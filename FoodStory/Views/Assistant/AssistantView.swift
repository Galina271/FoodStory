//
//  AssistantView.swift
//  FoodStory
//
//  Экран AI-помощника: вводим продукты и пожелание — получаем идею рецепта.
//  Сейчас работает демо-режим (StubRecipeSuggester, без интернета). Когда будет
//  готов ключ, здесь достаточно заменить одну строку на ClaudeRecipeSuggester.
//

import SwiftUI

struct AssistantView: View {
    @Environment(\.dismiss) private var dismiss

    // Какой «поставщик идей» используем. Пока — заглушка.
    // Позже: let suggester: RecipeSuggesting = ClaudeRecipeSuggester(apiKey: "...")
    private let suggester: RecipeSuggesting = StubRecipeSuggester()

    @State private var products = ""
    @State private var note = ""
    @State private var answer = ""
    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metric.padding) {

                    infoBanner

                    // Поле продуктов.
                    field(title: "Какие продукты есть?",
                          prompt: "Например: яйца, помидоры, сыр",
                          text: $products)

                    // Поле пожелания.
                    field(title: "Пожелание (необязательно)",
                          prompt: "Например: быстро, без мяса, на завтрак",
                          text: $note)

                    askButton

                    if let errorText {
                        Text(errorText)
                            .font(.subheadline)
                            .foregroundStyle(Theme.tomato)
                    }

                    if !answer.isEmpty {
                        answerCard
                    }
                }
                .padding(Metric.padding)
            }
            .background(Theme.background)
            .navigationTitle("Помощник")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .tint(Theme.accent)
    }

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: Metric.spacing) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.accent)
            Text("Демо-режим. Позже подключим Claude AI — и подсказки станут настоящими.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func field(title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textPrimary)
            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(1...3)
                .padding(10)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
        }
    }

    private var askButton: some View {
        Button {
            Task { await ask() }
        } label: {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(isLoading ? "Придумываю…" : "Предложить рецепт")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        }
        .disabled(isLoading)
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            Label("Идея", systemImage: "lightbulb")
                .font(.headline)
                .foregroundStyle(Theme.accent)
            Text(answer)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // Запрашиваем идею у «поставщика».
    private func ask() async {
        errorText = nil
        answer = ""
        isLoading = true
        defer { isLoading = false }

        // Разбиваем строку продуктов по запятым в список.
        let list = products
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        do {
            answer = try await suggester.suggestRecipe(fromProducts: list, note: note)
        } catch {
            errorText = error.localizedDescription
        }
    }
}

#Preview {
    AssistantView()
}
