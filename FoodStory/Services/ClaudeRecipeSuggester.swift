//
//  ClaudeRecipeSuggester.swift
//  FoodStory
//
//  Настоящий AI-помощник на базе Claude (модель claude-opus-4-8).
//  ПОКА НЕ ВКЛЮЧЁН: в приложении по умолчанию используется StubRecipeSuggester.
//  Этот файл — готовый задел. Чтобы включить, нужно:
//    1. Получить API-ключ на console.anthropic.com.
//    2. Передать ключ в ClaudeRecipeSuggester(apiKey:) и использовать его в
//       AssistantView вместо заглушки.
//
//  ⚠️ Ключ НЕЛЬЗЯ хранить прямо в коде и класть в git — это секрет. Позже
//  вынесем его в безопасное место (например, Keychain или конфигурацию сборки).
//
//  Swift-SDK у Anthropic нет, поэтому обращаемся к API напрямую по HTTPS
//  (endpoint POST https://api.anthropic.com/v1/messages).
//

import Foundation

struct ClaudeRecipeSuggester: RecipeSuggesting {
    /// Секретный ключ доступа к API. Пустой ключ = помощник не настроен.
    let apiKey: String

    /// Модель Claude. По умолчанию — самая способная (Opus 4.8).
    var model: String = "claude-opus-4-8"

    func suggestRecipe(fromProducts products: [String], note: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw SuggesterError.notConfigured
        }

        // 1. Собираем текст запроса для модели.
        let productsText = products.isEmpty ? "(продукты не указаны)" : products.joined(separator: ", ")
        let userPrompt = """
        У меня есть такие продукты: \(productsText).
        Пожелание: \(note.isEmpty ? "нет" : note).
        Предложи один рецепт: короткое описание, список ингредиентов и шаги.
        Отвечай на русском языке.
        """

        // 2. Формируем тело запроса по формату Messages API.
        let body = RequestBody(
            model: model,
            max_tokens: 1024,
            system: "Ты дружелюбный кулинарный помощник. Предлагай простые и понятные домашние рецепты.",
            messages: [Message(role: "user", content: userPrompt)]
        )

        // 3. Настраиваем HTTP-запрос и обязательные заголовки.
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        // 4. Отправляем и разбираем ответ.
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SuggesterError.badResponse
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        // Ответ приходит массивом блоков; собираем текстовые.
        let text = decoded.content
            .filter { $0.type == "text" }
            .map { $0.text ?? "" }
            .joined()

        return text.isEmpty ? "Не удалось получить ответ. Попробуйте ещё раз." : text
    }

    // MARK: - Ошибки

    enum SuggesterError: LocalizedError {
        case notConfigured
        case badResponse

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "AI-помощник ещё не настроен (нет ключа API)."
            case .badResponse:   return "Сервис недоступен. Проверьте интернет и ключ API."
            }
        }
    }

    // MARK: - Формы запроса и ответа (Codable = умеют превращаться в JSON и обратно)

    private struct RequestBody: Encodable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    private struct Message: Encodable {
        let role: String
        let content: String
    }

    private struct ResponseBody: Decodable {
        let content: [Block]
    }

    private struct Block: Decodable {
        let type: String
        let text: String?
    }
}
