//
//  ServerRecipeSuggester.swift
//  FoodStory
//
//  Обращается к НАШЕМУ серверу (а не напрямую к Claude). Сервер хранит ключ и сам
//  вызывает Claude — так секрет не попадает в приложение. Это правильный способ
//  для публикации в App Store.
//
//  Сервер лежит в папке server/ этого проекта. Адрес сервера задаётся в
//  Настройках приложения (Настройки → AI-помощник).
//

import Foundation

struct ServerRecipeSuggester: RecipeSuggesting {
    /// Базовый адрес сервера, например https://foodstory.onrender.com
    let baseURL: URL
    /// Необязательный общий токен (если сервер его требует).
    var appToken: String? = nil

    func suggestRecipe(fromProducts products: [String], note: String) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("suggest"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let appToken, !appToken.isEmpty {
            request.setValue(appToken, forHTTPHeaderField: "x-app-token")
        }
        request.httpBody = try JSONEncoder().encode(RequestBody(products: products, note: note))
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServerError.badResponse
        }

        let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data)

        // Сервер может вернуть ошибку в поле error (даже со статусом 200) —
        // показываем её текст.
        if let serverError = decoded?.error, !serverError.isEmpty {
            throw ServerError.message(serverError)
        }
        guard http.statusCode == 200 else {
            throw ServerError.message("Ошибка сервера (\(http.statusCode)).")
        }
        guard let text = decoded?.text, !text.isEmpty else {
            throw ServerError.badResponse
        }
        return text
    }

    // MARK: - Формы запроса/ответа

    private struct RequestBody: Encodable {
        let products: [String]
        let note: String
    }

    private struct ResponseBody: Decodable {
        let text: String?
        let error: String?
    }

    enum ServerError: LocalizedError {
        case badResponse
        case message(String)

        var errorDescription: String? {
            switch self {
            case .badResponse:      return "Сервер вернул неожиданный ответ."
            case .message(let m):   return m
            }
        }
    }
}
