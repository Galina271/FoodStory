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

    // Последняя реакция на рекомендацию: true = 👍, false = 👎.
    // Нужна, чтобы наглядно показать, что оценка засчитана.
    @State private var reactions: [PersistentIdentifier: Bool] = [:]

    // Зафиксированная подборка рекомендаций. Считаем её ОДИН раз (при появлении
    // экрана и при изменении числа рецептов), а не на каждый тап — иначе оценка
    // дообучает модель, порядок пересчитывается и карточки «скачут».
    @State private var displayedSuggestions: [Recipe] = []

    private func refreshSuggestions() {
        displayedSuggestions = taste.isTrained
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
                // Отступы задаём поэлементно, а горизонтальные ленты пускаем во всю
                // ширину (с внутренними полями) — тогда карточки уходят за край
                // аккуратно, без «обрезков-полосок» посреди экрана.
                VStack(alignment: .leading, spacing: Metric.padding * 1.5) {

                    greeting
                        .padding(.horizontal, Metric.padding)

                    VStack(alignment: .leading, spacing: 6) {
                        sectionTitle("Что приготовить сегодня?")
                        if taste.isTrained {
                            Label("Подобрано под ваш вкус · обучено на \(taste.trainedCount) примерах",
                                  systemImage: "sparkles")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(.horizontal, Metric.padding)

                    suggestionsRow

                    if !recentlyCooked.isEmpty {
                        sectionTitle("Недавно готовили")
                            .padding(.horizontal, Metric.padding)
                        recentRow
                    }

                    sectionTitle("Быстрые действия")
                        .padding(.horizontal, Metric.padding)
                    quickActions
                        .padding(.horizontal, Metric.padding)
                }
                .padding(.vertical, Metric.padding)
            }
            .background(Theme.background)
            .onAppear {
                if displayedSuggestions.isEmpty { refreshSuggestions() }
            }
            .onChange(of: recipes.count) { _, _ in
                refreshSuggestions()
            }
            .navigationTitle("FoodStory")
            .navigationBarTitleDisplayMode(.inline)
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
            Text("Привет, \(userName)! 👋")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.textPrimary)
            Text(recipes.isEmpty
                 ? "Начнём вашу кулинарную книгу"
                 : "\(recipes.count) \(recipeWord(recipes.count)) в вашей книге")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // Правильное слово: 1 рецепт, 2 рецепта, 5 рецептов.
    private func recipeWord(_ n: Int) -> String {
        let mod100 = n % 100, mod10 = n % 10
        if mod100 >= 11 && mod100 <= 14 { return "рецептов" }
        switch mod10 {
        case 1: return "рецепт"
        case 2, 3, 4: return "рецепта"
        default: return "рецептов"
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
                ForEach(displayedSuggestions) { recipe in
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
        // Поля по краям — карточки уходят за экран аккуратно, без «обрезков».
        .contentMargins(.horizontal, Metric.padding, for: .scrollContent)
    }

    // Пара кнопок оценки. Каждый тап — это один пример для обучения модели.
    private func ratingButtons(for recipe: Recipe) -> some View {
        let reaction = reactions[recipe.id]
        return HStack(spacing: 8) {
            ratingButton(icon: "hand.thumbsup", color: Theme.green,
                         active: reaction == true) {
                react(to: recipe, liked: true)
            }
            ratingButton(icon: "hand.thumbsdown", color: Theme.tomato,
                         active: reaction == false) {
                react(to: recipe, liked: false)
            }
        }
    }

    // Обрабатываем оценку: вибрация, подсветка, обучение модели.
    // Повторное нажатие на ту же кнопку — отмена (подсветка снимается).
    private func react(to recipe: Recipe, liked: Bool) {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        if reactions[recipe.id] == liked {
            withAnimation(.easeInOut(duration: 0.15)) {
                reactions[recipe.id] = nil
            }
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                reactions[recipe.id] = liked
            }
            taste.train(on: recipe, liked: liked)
        }
    }

    private func ratingButton(icon: String, color: Color, active: Bool,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: active ? "\(icon).fill" : icon)
                .font(.subheadline.bold())
                .foregroundStyle(active ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(active ? color : Theme.chip)
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
        .contentMargins(.horizontal, Metric.padding, for: .scrollContent)
    }

    // Кнопки быстрых действий.
    private var quickActions: some View {
        HStack(spacing: Metric.spacing) {
            quickActionButton(title: "Новый рецепт", icon: "plus", color: Theme.accent) {
                showingAddRecipe = true
            }
            quickActionButton(title: "Список покупок", icon: "cart.fill", color: Theme.green) {
                showingShoppingList = true
            }
            quickActionButton(title: "Помощник", icon: "sparkles", color: Theme.tomato) {
                showingAssistant = true
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.15), in: Circle())
                Text(title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)   // всегда 2 строки — карточки одной высоты
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
