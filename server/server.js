//
// FoodStory — сервер-прокси к нейросети (Gemini или Claude).
//
// Зачем: секретный ключ нельзя класть в приложение. Он хранится ЗДЕСЬ, а
// приложение обращается к этому серверу. Сервер сам вызывает нейросеть.
//
// Какой «мозг» использовать — выбирается автоматически:
//   • если задан GEMINI_API_KEY  → Gemini (бесплатный тариф Google);
//   • иначе если ANTHROPIC_API_KEY → Claude (платный).
// Можно задать явно переменной AI_PROVIDER = gemini | claude.
//
// Запуск локально:
//   cd server && npm install && GEMINI_API_KEY=... npm start
//

import express from "express";
import Anthropic from "@anthropic-ai/sdk";

// Ловим любые неожиданные ошибки, чтобы сервер не падал молча.
process.on("unhandledRejection", (reason) => console.error("unhandledRejection:", reason));
process.on("uncaughtException", (err) => console.error("uncaughtException:", err));

const app = express();
app.use(express.json());

const appToken = process.env.APP_SHARED_TOKEN?.trim() || null;

// Ключи. .trim() убирает случайные пробелы/переносы по краям (частая ошибка копирования).
const geminiKey = process.env.GEMINI_API_KEY?.trim();
const anthropicKey = process.env.ANTHROPIC_API_KEY?.trim();
const yandexKey = process.env.YANDEX_API_KEY?.trim();
const yandexFolder = process.env.YANDEX_FOLDER_ID?.trim();

// Какой провайдер использовать (или задать явно через AI_PROVIDER).
const provider = (
  process.env.AI_PROVIDER ||
  (yandexKey ? "yandex" : geminiKey ? "gemini" : "claude")
).toLowerCase();

const geminiModel = (process.env.GEMINI_MODEL || "gemini-2.0-flash").trim();
const claudeModel = (process.env.CLAUDE_MODEL || "claude-opus-4-8").trim();
const yandexModel = (process.env.YANDEX_MODEL || "yandexgpt-lite/latest").trim();

// Клиент Claude нужен только для провайдера claude.
const anthropic = anthropicKey ? new Anthropic({ apiKey: anthropicKey }) : null;

const SYSTEM = "Ты дружелюбный кулинарный помощник. Предлагай простые и понятные домашние рецепты.";

// Настроен ли выбранный провайдер? Возвращает текст проблемы или null.
function configProblem() {
  if (provider === "yandex") {
    if (!yandexKey) return "не задан YANDEX_API_KEY";
    if (!yandexFolder) return "не задан YANDEX_FOLDER_ID";
    return null;
  }
  if (provider === "gemini") {
    return geminiKey ? null : "не задан GEMINI_API_KEY";
  }
  if (provider === "claude") {
    if (!anthropicKey) return "не задан ANTHROPIC_API_KEY";
    if (!/^[\x00-\x7F]+$/.test(anthropicKey)) return "ключ Claude содержит не-латинские символы (вставлен пример?)";
    if (!anthropicKey.startsWith("sk-ant-")) return "ключ Claude должен начинаться с «sk-ant-»";
    return null;
  }
  return `неизвестный провайдер: ${provider}`;
}
const issue = configProblem();
if (issue) console.error("⚠️  Проблема с настройкой:", issue);

// Проверка живости.
app.get("/health", (req, res) => {
  const model = provider === "gemini" ? geminiModel
    : provider === "yandex" ? yandexModel
    : claudeModel;
  res.json({ ok: true, provider, model, configured: !issue, issue });
});

// Универсальная генерация: вызывает выбранный провайдер, возвращает текст.
async function generateRecipe(userPrompt) {
  if (provider === "yandex") {
    // YandexGPT (Yandex Cloud Foundation Models). Ключ сервисного аккаунта —
    // заголовок «Authorization: Api-Key …»; каталог зашит в modelUri.
    const resp = await fetch("https://llm.api.cloud.yandex.net/foundationModels/v1/completion", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Api-Key ${yandexKey}`,
      },
      body: JSON.stringify({
        modelUri: `gpt://${yandexFolder}/${yandexModel}`,
        completionOptions: { stream: false, temperature: 0.6, maxTokens: 1000 },
        messages: [
          { role: "system", text: SYSTEM },
          { role: "user", text: userPrompt },
        ],
      }),
    });
    const data = await resp.json();
    if (!resp.ok) {
      throw new Error(`${resp.status} ${data?.message || JSON.stringify(data)}`);
    }
    return data?.result?.alternatives?.[0]?.message?.text || "";
  }

  if (provider === "gemini") {
    // REST-запрос к Gemini (без отдельной библиотеки).
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiKey}`;
    const resp = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: SYSTEM }] },
        contents: [{ role: "user", parts: [{ text: userPrompt }] }],
        generationConfig: { maxOutputTokens: 1024 },
      }),
    });
    const data = await resp.json();
    if (!resp.ok) {
      throw new Error(`${resp.status} ${data?.error?.message || "ошибка Gemini"}`);
    }
    return (data?.candidates?.[0]?.content?.parts || []).map((p) => p.text).join("");
  }

  // Claude.
  const message = await anthropic.messages.create({
    model: claudeModel,
    max_tokens: 1024,
    system: SYSTEM,
    messages: [{ role: "user", content: userPrompt }],
  });
  return message.content.filter((b) => b.type === "text").map((b) => b.text).join("");
}

// Основной эндпоинт. Ошибки отдаём со статусом 200 в поле error, чтобы их не
// «съедал» туннель/прокси и приложение могло показать причину.
app.post("/suggest", async (req, res) => {
  console.log("[/suggest] запрос:", JSON.stringify(req.body));
  try {
    if (appToken && req.get("x-app-token") !== appToken) {
      return res.json({ error: "Неверный токен приложения." });
    }
    if (issue) {
      return res.json({ error: `Сервер не настроен: ${issue}.` });
    }

    const products = Array.isArray(req.body?.products) ? req.body.products : [];
    const note = typeof req.body?.note === "string" ? req.body.note : "";
    const productsText = products.length ? products.join(", ") : "(не указаны)";

    const userPrompt =
      `У меня есть продукты: ${productsText}.\n` +
      `Пожелание: ${note || "нет"}.\n` +
      `Предложи один рецепт: короткое описание, список ингредиентов и пошаговые шаги. ` +
      `Отвечай на русском языке.`;

    const text = await generateRecipe(userPrompt);
    console.log(`[/suggest] успех (${provider}), символов:`, text.length);
    res.json({ text: text || "Не удалось получить ответ. Попробуйте ещё раз." });
  } catch (err) {
    const detail = err?.message || String(err);
    console.error(`[/suggest] ОШИБКА (${provider}):`, detail);
    res.json({ error: `${provider}: ${detail}` });
  }
});

const port = process.env.PORT || 8787;
app.listen(port, () => {
  console.log(`FoodStory server on :${port} provider=${provider} configured=${!issue}`);
});
