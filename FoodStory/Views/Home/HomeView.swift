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

    // Имя пользователя из настроек (меняется на экране «Настройки»).
    @AppStorage("userName") private var userName = "Галина"

    @State private var showingAddRecipe = false
    @State private var showingShoppingList = false
    @State private var showingAssistant = false

    // 3 случайных рецепта в качестве рекомендаций.
    private var suggestions: [Recipe] {
        Array(recipes.shuffled().prefix(3))
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

    // Горизонтальный скролл рекомендаций.
    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metric.spacing) {
                ForEach(suggestions) { recipe in
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
}
