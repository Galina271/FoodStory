//
//  HomeView.swift
//  FoodStory
//
//  Главный экран: приветствие, рекомендации «Что приготовить сегодня»,
//  «Недавно готовили» и быстрые действия.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var recipes: [Recipe]

    // Наша обучаемая модель вкуса — от неё берём персональные рекомендации.
    @Environment(TasteModel.self) private var taste

    // Имя пользователя из настроек (меняется на экране «Настройки»).
    @AppStorage("userName") private var userName = "Галина"

    @State private var showingAddRecipe = false
    @State private var showingShoppingList = false
    @State private var showingAssistant = false

    // Рекомендации: если модель вкуса уже чему-то научилась — показываем её
    // персональный топ; пока не обучена — просто 3 случайных рецепта.
    private var suggestions: [Recipe] {
        taste.isTrained
            ? taste.recommendations(from: recipes, limit: 3)
            : Array(recipes.shuffled().prefix(3))
    }

    // Недавно готовили — те, у кого cookedCount > 0.
    private var recentlyCooked: [Recipe] {
        recipes.filter { $0.cookedCount > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metric.padding * 1.5) {

                    greeting

                    sectionTitle("Что приготовить сегодня?")
                    if taste.isTrained {
                        Label("Подобрано под ваш вкус · обучено на \(taste.trainedCount) примерах",
                              systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                    }
                    suggestionsRow

                    if !recentlyCooked.isEmpty {
                        sectionTitle("Недавно готовили")
                        recentRow
                    }

                    sectionTitle("Быстрые действия")
                    quickActions
                }
                .padding(Metric.padding)
            }
            .background(Theme.background)
            .navigationTitle("FoodStory")
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView()
            }
            .sheet(isPresented: $showingShoppingList) {
                ShoppingListView()
            }
            .sheet(isPresented: $showingAssistant) {
                AssistantView()
            }
        }
        .tint(Theme.accent)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Привет, \(userName)!")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("Что приготовим сегодня?")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3.bold())
            .foregroundStyle(Theme.textPrimary)
    }

    // Горизонтальный скролл рекомендаций. Под каждой карточкой — оценки 👍/👎,
    // которыми пользователь напрямую обучает модель вкуса.
    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Metric.spacing) {
                ForEach(suggestions) { recipe in
                    VStack(spacing: 8) {
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeCardView(recipe: recipe)
                        }
                        .buttonStyle(.plain)

                        ratingButtons(for: recipe)
                    }
                    .frame(width: 200)
                }
            }
        }
    }

    // Пара кнопок оценки. Каждый тап — это один пример для обучения модели.
    private func ratingButtons(for recipe: Recipe) -> some View {
        HStack(spacing: 8) {
            ratingButton(icon: "hand.thumbsup", color: Theme.green) {
                taste.train(on: recipe, liked: true)
            }
            ratingButton(icon: "hand.thumbsdown", color: Theme.tomato) {
                taste.train(on: recipe, liked: false)
            }
        }
    }

    private func ratingButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            // Лёгкая вибрация-отклик, что оценка засчитана.
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            action()
        } label: {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.chip)
                .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
        }
        .buttonStyle(.plain)
    }

    private var recentRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metric.spacing) {
                ForEach(recentlyCooked) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeCardView(recipe: recipe)
                            .frame(width: 200)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // Кнопки быстрых действий.
    private var quickActions: some View {
        HStack(spacing: Metric.spacing) {
            quickActionButton(title: "Новый рецепт", icon: "plus") {
                showingAddRecipe = true
            }
            quickActionButton(title: "Список покупок", icon: "cart") {
                showingShoppingList = true
            }
            quickActionButton(title: "Помощник", icon: "sparkles") {
                showingAssistant = true
            }
        }
    }

    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Metric.padding)
            .cardStyle()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(previewContainer)
        .environment(TasteModel())
}
