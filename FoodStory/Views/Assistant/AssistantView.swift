//
//  AssistantView.swift
//  FoodStory
//
//  AI-помощник (рабочий, офлайн). Вводим продукты и пожелание — получаем
//  подборку из СВОИХ рецептов, отсортированную по совпадению продуктов, вкусу
//  и пожеланиям. Подбор делает LocalRecipeAssistant, без интернета и ключей.
//

import SwiftUI
import SwiftData

struct AssistantView: View {
    @Environment(\.dismiss) private var dismiss

    // Все рецепты и модель вкуса — из них помощник строит подсказки.
    @Query private var recipes: [Recipe]
    @Environment(TasteModel.self) private var taste
    @Environment(\.modelContext) private var context

    @State private var products = ""
    @State private var note = ""
    @State private var suggestions: [AssistantSuggestion] = []
    @State private var didSearch = false

    // Настройки сервера-прокси к Claude (для генерации новых рецептов).
    @AppStorage("assistantServerURL") private var serverURL = ""
    @AppStorage("assistantServerToken") private var serverToken = ""

    // Состояние AI-генерации.
    @State private var aiText: String?
    @State private var aiError: String?
    @State private var aiLoading = false
    // Рецепт, сохранённый из ответа AI (чтобы показать «Открыть»).
    @State private var savedRecipe: Recipe?

    // Продукты строкой → список.
    private var productsList: [String] {
        products.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metric.padding) {

                    infoBanner

                    field(title: "Какие продукты есть?",
                          prompt: "Например: яйца, помидоры, сыр",
                          text: $products)

                    field(title: "Пожелание (необязательно)",
                          prompt: "Например: быстро, без мяса, на завтрак",
                          text: $note)

                    askButton
                    aiButton
                    aiResult

                    if didSearch {
                        resultsSection
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
            Text("Подбираю из ваших рецептов по продуктам и вкусу. Чем больше рецептов — тем точнее подсказки.")
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
            search()
        } label: {
            Label("Предложить рецепт", systemImage: "wand.and.stars")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        }
    }

    // Кнопка генерации нового рецепта через сервер (Claude).
    private var aiButton: some View {
        Button {
            Task { await generateWithAI() }
        } label: {
            HStack {
                if aiLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "wand.and.stars.inverse")
                }
                Text(aiLoading ? "Придумываю…" : "Придумать новый рецепт (AI)")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.green)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        }
        .disabled(aiLoading)
    }

    @ViewBuilder
    private var aiResult: some View {
        if let aiError {
            Text(aiError)
                .font(.subheadline)
                .foregroundStyle(Theme.tomato)
        }
        if let aiText {
            VStack(alignment: .leading, spacing: Metric.spacing) {
                Label("Новый рецепт от AI", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Theme.green)
                Text(aiText)
                    .foregroundStyle(Theme.textPrimary)

                // Сохранить рецепт к себе (или открыть, если уже сохранён).
                if let saved = savedRecipe {
                    NavigationLink {
                        RecipeDetailView(recipe: saved)
                    } label: {
                        Label("Открыть добавленный рецепт", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.green)
                    }
                } else {
                    Button {
                        saveAIRecipe(aiText)
                    } label: {
                        Label("Добавить в мои рецепты", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(Metric.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if suggestions.isEmpty {
            Text("Ничего не нашлось. Попробуйте другие продукты или добавьте рецепты.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        } else {
            VStack(spacing: Metric.spacing) {
                ForEach(suggestions) { suggestion in
                    suggestionCard(suggestion)
                }
            }
        }
    }

    @ViewBuilder
    private func suggestionCard(_ suggestion: AssistantSuggestion) -> some View {
        if let recipe = suggestion.recipe {
            // Подобран конкретный рецепт — карточка ведёт в него.
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                HStack(spacing: Metric.spacing) {
                    RecipeImageView(recipe: recipe, iconSize: 22)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(suggestion.reason)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Metric.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
            .buttonStyle(.plain)
        } else {
            // Общий совет (когда нет подходящих рецептов).
            VStack(alignment: .leading, spacing: 6) {
                Label(suggestion.title, systemImage: "lightbulb")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Text(suggestion.reason)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(Metric.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private func search() {
        suggestions = LocalRecipeAssistant.suggest(
            products: productsList, note: note, recipes: recipes, taste: taste
        )
        didSearch = true
    }

    // Генерация нового рецепта через наш сервер (если он настроен).
    // Разбираем ответ AI в рецепт и сохраняем в базу.
    private func saveAIRecipe(_ text: String) {
        let recipe = AIRecipeParser.recipe(from: text)
        context.insert(recipe)
        try? context.save()
        savedRecipe = recipe
    }

    private func generateWithAI() async {
        aiError = nil
        aiText = nil
        savedRecipe = nil

        let trimmed = serverURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil else {
            aiError = "Сначала укажите адрес сервера в Настройках → AI-помощник."
            return
        }

        aiLoading = true
        defer { aiLoading = false }

        let suggester = ServerRecipeSuggester(
            baseURL: url,
            appToken: serverToken.isEmpty ? nil : serverToken
        )
        do {
            aiText = try await suggester.suggestRecipe(fromProducts: productsList, note: note)
        } catch {
            aiError = error.localizedDescription
        }
    }
}

#Preview {
    AssistantView()
        .modelContainer(previewContainer)
        .environment(TasteModel())
}
