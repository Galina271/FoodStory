//
// FoodStory — сервер-прокси к Claude.
//
// Зачем нужен: секретный ключ Anthropic НЕЛЬЗЯ класть в приложение (его легко
// достать из установленного приложения). Поэтому ключ хранится ЗДЕСЬ, на сервере,
// а приложение обращается к этому серверу. Сервер сам вызывает Claude и возвращает
// текст рецепта.
//
// Запуск локально:
//   cd server && npm install && ANTHROPIC_API_KEY=sk-ant-... npm start
//
// Переменные окружения:
//   ANTHROPIC_API_KEY — ключ Anthropic (обязательно).
//   CLAUDE_MODEL      — модель (по умолчанию claude-opus-4-8).
//   APP_SHARED_TOKEN  — если задан, приложение должно прислать такой же токен
//                       в заголовке x-app-token (простая защита от чужих запросов).
//   PORT              — порт (по умолчанию 8787).
//

import express from "express";
import Anthropic from "@anthropic-ai/sdk";

// Ловим любые неожиданные ошибки, чтобы сервер НИКОГДА не падал молча.
process.on("unhandledRejection", (reason) => console.error("unhandledRejection:", reason));
process.on("uncaughtException", (err) => console.error("uncaughtException:", err));

const app = express();
app.use(express.json());

// .trim() убирает случайные пробелы/переносы строки по краям — частая причина
// «invalid x-api-key» при копировании ключа в панель хостинга.
const apiKey = process.env.ANTHROPIC_API_KEY?.trim();
const model = (process.env.CLAUDE_MODEL || "claude-opus-4-8").trim();
const appToken = process.env.APP_SHARED_TOKEN?.trim() || null;

// Проверяем ключ на типичные ошибки (пустой, с примером-placeholder'ом, не тот формат).
function keyProblem(key) {
  if (!key) return "не задан ANTHROPIC_API_KEY";
  if (!/^[\x00-\x7F]+$/.test(key)) {
    return "ключ содержит не-латинские символы — похоже, вставлен пример «ТВОЙ_КЛЮЧ», а не настоящий ключ";
  }
  if (!key.startsWith("sk-ant-")) return "ключ должен начинаться с «sk-ant-»";
  return null;
}

const keyIssue = keyProblem(apiKey);
if (keyIssue) console.error("⚠️  Проблема с ключом:", keyIssue);

// Клиент создаём только если ключ выглядит корректным.
const client = keyIssue ? null : new Anthropic({ apiKey });

// Проверка живости — удобно после деплоя открыть /health в браузере.
app.get("/health", (req, res) => {
  res.json({ ok: true, configured: Boolean(client), model, keyIssue });
});

// Основной эндпоинт: принимает продукты и пожелание, возвращает { text }.
// Ошибки возвращаем со статусом 200 и полем error — так их не «съедает» туннель
// (Cloudflare заменяет 5xx своей страницей), и приложение может показать причину.
app.post("/suggest", async (req, res) => {
  console.log("[/suggest] запрос получен:", JSON.stringify(req.body));
  try {
    if (appToken && req.get("x-app-token") !== appToken) {
      return res.json({ error: "Неверный токен приложения." });
    }
    if (!client) {
      return res.json({ error: `Сервер не настроен: ${keyIssue}.` });
    }

    const products = Array.isArray(req.body?.products) ? req.body.products : [];
    const note = typeof req.body?.note === "string" ? req.body.note : "";
    const productsText = products.length ? products.join(", ") : "(не указаны)";

    const userPrompt =
      `У меня есть продукты: ${productsText}.\n` +
      `Пожелание: ${note || "нет"}.\n` +
      `Предложи один рецепт: короткое описание, список ингредиентов и пошаговые шаги. ` +
      `Отвечай на русском языке.`;

    const message = await client.messages.create({
      model,
      max_tokens: 1024,
      system: "Ты дружелюбный кулинарный помощник. Предлагай простые и понятные домашние рецепты.",
      messages: [{ role: "user", content: userPrompt }],
    });

    const text = message.content
      .filter((block) => block.type === "text")
      .map((block) => block.text)
      .join("");

    console.log("[/suggest] успех, символов:", text.length);
    res.json({ text: text || "Не удалось получить ответ. Попробуйте ещё раз." });
  } catch (err) {
    // Показываем настоящую причину (статус + сообщение от Anthropic).
    const detail = `${err?.status ?? ""} ${err?.error?.error?.message ?? err?.message ?? err}`.trim();
    console.error("[/suggest] ОШИБКА Claude:", detail);
    res.json({ error: `Claude: ${detail}` });
  }
});

const port = process.env.PORT || 8787;
app.listen(port, () => {
  console.log(`FoodStory server on http://localhost:${port} (configured=${Boolean(client)})`);
});
