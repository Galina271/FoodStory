//
//  RecipeListView.swift
//  FoodStory
//
//  Экран «Мои рецепты»: сетка карточек, сортировка, кнопка добавления.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {

    // @Query — это «волшебство» SwiftData: оно само достаёт все рецепты из базы
    // И автоматически обновляет экран, когда что-то добавили или удалили.
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    // Доступ к базе, чтобы уметь удалять рецепты.
    @Environment(\.modelContext) private var context
    @Environment(TasteModel.self) private var taste   // модель вкуса

    // Текущий способ сортировки. @State — значение, которое может меняться
    // и при изменении перерисовывает экран.
    @State private var sortOption: SortOption = .date

    // Управляет показом экрана добавления (true — открыт).
    @State private var showingAddRecipe = false

    // Рецепт, который сейчас редактируем (nil — окно правки закрыто).
    @State private var editingRecipe: Recipe?

    // Рецепт, для которого пользователь нажал «Удалить» — держим его,
    // пока показываем подтверждение, чтобы не удалить случайно.
    @State private var recipeToDelete: Recipe?

    // Выбранная категория для фильтра (nil = показывать все).
    @State private var selectedCategory: RecipeCategory?

    // Варианты сортировки из твоего плана: по дате, популярности, времени, алфавиту.
    enum SortOption: String, CaseIterable, Identifiable {
        case date = "По дате"
        case popular = "По популярности"
        case time = "По времени"
        case alphabet = "По алфавиту"
        var id: String { rawValue }
    }

    // Рецепты, уже отсортированные выбранным способом.
    private var sortedRecipes: [Recipe] {
        switch sortOption {
        case .date:     return recipes.sorted { $0.createdAt > $1.createdAt }
        case .popular:  return recipes.sorted { $0.cookedCount > $1.cookedCount }
        case .time:     return recipes.sorted { $0.cookingMinutes < $1.cookingMinutes }
        case .alphabet: return recipes.sorted { $0.title < $1.title }
        }
    }

    // Категории, в которых есть хотя бы один рецепт (в порядке из enum).
    private var usedCategories: [RecipeCategory] {
        RecipeCategory.allCases.filter { category in
            recipes.contains { $0.category == category }
        }
    }

    // Рецепты после сортировки и фильтра по категории.
    private var filteredRecipes: [Recipe] {
        guard let selectedCategory else { return sortedRecipes }
        return sortedRecipes.filter { $0.category == selectedCategory }
    }

    // Сетка из двух колонок. Расстояние между колонками — побольше, чтобы
    // карточки заметно отделялись друг от друга.
    private let columns = [
        GridItem(.flexible(), spacing: Metric.padding),
        GridItem(.flexible(), spacing: Metric.padding)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if recipes.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        categoryFilterBar

                        ScrollView {
                            if filteredRecipes.isEmpty {
                                Text("В этой категории пока нет рецептов.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.top, 40)
                            } else {
                                LazyVGrid(columns: columns, spacing: Metric.padding + 6) {
                                    ForEach(filteredRecipes) { recipe in
                                        // NavigationLink делает карточку «кликабельной» —
                                        // при нажатии откроется детальный экран.
                                        NavigationLink {
                                            RecipeDetailView(recipe: recipe)
                                        } label: {
                                            RecipeCardView(recipe: recipe)
                                        }
                                        .buttonStyle(.plain)   // убираем синий цвет ссылки
                                        // Долгое нажатие на карточку открывает меню действий.
                                        .contextMenu {
                                            recipeMenu(for: recipe)
                                        }
                                    }
                                }
                                .padding(Metric.padding)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Мои рецепты")
            .toolbar {
                // Меню сортировки слева.
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Сортировка", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                // Кнопка «+» справа.
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // sheet — это экран, который «выезжает» снизу.
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView()
            }
            // Тот же экран, но в режиме редактирования выбранного рецепта.
            .sheet(item: $editingRecipe) { recipe in
                AddRecipeView(recipeToEdit: recipe)
            }
            // Подтверждение удаления — чтобы не стереть рецепт по ошибке.
            .confirmationDialog(
                "Удалить «\(recipeToDelete?.title ?? "")»?",
                isPresented: Binding(
                    get: { recipeToDelete != nil },
                    set: { if !$0 { recipeToDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: recipeToDelete
            ) { recipe in
                Button("Удалить", role: .destructive) { delete(recipe) }
                Button("Отмена", role: .cancel) { recipeToDelete = nil }
            }
        }
        .tint(Theme.accent)
    }

    // Пункты меню действий над рецептом.
    @ViewBuilder
    private func recipeMenu(for recipe: Recipe) -> some View {
        Button {
            editingRecipe = recipe
        } label: {
            Label("Изменить", systemImage: "pencil")
        }
        Button {
            toggleFavorite(recipe)
        } label: {
            Label(recipe.isFavorite ? "Убрать из избранного" : "В избранное",
                  systemImage: recipe.isFavorite ? "heart.slash" : "heart")
        }
        Button {
            duplicate(recipe)
        } label: {
            Label("Дублировать", systemImage: "plus.square.on.square")
        }
        Button(role: .destructive) {
            recipeToDelete = recipe
        } label: {
            Label("Удалить", systemImage: "trash")
        }
    }

    // MARK: - Действия над рецептами

    private func delete(_ recipe: Recipe) {
        context.delete(recipe)
        try? context.save()
        recipeToDelete = nil
    }

    private func duplicate(_ recipe: Recipe) {
        let copy = recipe.makeCopy()
        context.insert(copy)
        try? context.save()
    }

    private func toggleFavorite(_ recipe: Recipe) {
        recipe.isFavorite.toggle()
        try? context.save()
        taste.train(on: recipe, liked: recipe.isFavorite)
    }

    // Лента «чипсов» категорий: «Все» + категории, в которых есть рецепты.
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "Все", icon: "square.grid.2x2",
                             selected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(usedCategories) { category in
                    categoryChip(title: category.title, icon: category.icon,
                                 selected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, Metric.padding)
            .padding(.vertical, 10)
        }
    }

    private func categoryChip(title: String, icon: String, selected: Bool,
                              action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(selected ? .bold : .regular))
                .foregroundStyle(selected ? .white : Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Theme.accent : Theme.chip, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // Что показываем, когда рецептов нет вообще.
    private var emptyState: some View {
        VStack(spacing: Metric.spacing) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundStyle(Theme.textSecondary)
            Text("Пока нет рецептов")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Нажмите «+», чтобы добавить первый.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

#Preview {
    RecipeListView()
        .modelContainer(previewContainer)
        .environment(TasteModel())
}
