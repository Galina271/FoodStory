//
//  RecipeDetailView.swift
//  FoodStory
//
//  Детальный просмотр рецепта: фото, метаданные, ингредиенты с галочками,
//  пошаговая инструкция и кнопка «Приготовить» (запускает режим готовки).
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(TasteModel.self) private var taste   // наша обучаемая модель вкуса

    // Какие ингредиенты отмечены галочкой (для будущего списка покупок).
    // Храним имена отмеченных ингредиентов.
    @State private var checkedIngredients: Set<String> = []

    // Управляет открытием полноэкранного режима готовки.
    @State private var showingCooking = false

    // Открыт ли экран редактирования этого рецепта.
    @State private var showingEdit = false

    // Показываем ли подтверждение удаления.
    @State private var showingDeleteConfirm = false

    // На сколько порций пересчитывать ингредиенты (стартуем с числа из рецепта).
    @State private var servings: Int

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.servings)
    }

    // Во сколько раз масштабировать количества относительно рецепта.
    private var scaleFactor: Double {
        Double(servings) / Double(max(recipe.servings, 1))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.padding) {

                header
                metadata
                if recipe.rating > 0 || !recipe.notes.isEmpty {
                    ratingSection
                }
                portionsSection
                ingredientsSection
                stepsSection

                cookButton
                    .padding(.top, Metric.spacing)
            }
            .padding(Metric.padding)
        }
        .background(Theme.background)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Быстрая кнопка «в избранное».
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(recipe.isFavorite ? Theme.tomato : Theme.textSecondary)
                }
            }
            // Меню остальных действий.
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Изменить", systemImage: "pencil")
                    }
                    Button {
                        duplicate()
                    } label: {
                        Label("Дублировать", systemImage: "plus.square.on.square")
                    }
                    ShareLink(item: recipe.shareText) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        // Полноэкранный режим готовки.
        .fullScreenCover(isPresented: $showingCooking) {
            CookingView(recipe: recipe)
        }
        // Экран редактирования этого рецепта.
        .sheet(isPresented: $showingEdit) {
            AddRecipeView(recipeToEdit: recipe)
        }
        // Подтверждение удаления.
        .confirmationDialog(
            "Удалить «\(recipe.title)»?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) { delete() }
            Button("Отмена", role: .cancel) { }
        }
    }

    // MARK: - Действия

    private func toggleFavorite() {
        recipe.isFavorite.toggle()
        try? context.save()
        // Обучаем модель вкуса: избранное = лайк, снятие = дизлайк.
        taste.train(on: recipe, liked: recipe.isFavorite)
    }

    private func duplicate() {
        let copy = recipe.makeCopy()
        context.insert(copy)
        try? context.save()
    }

    private func delete() {
        context.delete(recipe)
        try? context.save()
        dismiss()   // закрываем экран удалённого рецепта
    }

    // Добавляет ингредиенты в список покупок. Если пользователь отметил галочками
    // только часть — добавляем их; если не отметил ничего — добавляем все.
    private func addToShoppingList() {
        let chosen = checkedIngredients.isEmpty
            ? recipe.ingredients
            : recipe.ingredients.filter { checkedIngredients.contains($0.name) }

        for ingredient in chosen {
            // В список кладём количество с учётом выбранного числа порций.
            let detail = ingredient.unit.hasAmount ? ingredient.scaledDisplayAmount(scaleFactor) : ""
            context.insert(ShoppingItem(name: ingredient.name, detail: detail))
        }
        try? context.save()
    }

    // «Фото» + описание.
    private var header: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            RecipeImageView(recipe: recipe, iconSize: 56, showsCategoryBadge: true)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))

            if !recipe.summary.isEmpty {
                Text(recipe.summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // Три «плашки»: время, порции, сложность.
    private var metadata: some View {
        HStack(spacing: Metric.spacing) {
            metaPill(icon: "clock", text: recipe.cookingTimeText)
            metaPill(icon: "person.2", text: "\(servings) порц.")
            metaPill(icon: recipe.difficulty.icon, text: recipe.difficulty.title, color: recipe.difficulty.color)
        }
    }

    // Оценка и заметка после последней готовки (показываем, если есть).
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            if recipe.rating > 0 {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= recipe.rating ? "star.fill" : "star")
                            .foregroundStyle(star <= recipe.rating ? Theme.accent : Theme.textSecondary)
                    }
                }
            }
            if !recipe.notes.isEmpty {
                Text(recipe.notes)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // Блок «Порции»: можно нажимать −/＋ или вписать число вручную.
    // Количества ингредиентов ниже пересчитываются автоматически.
    private var portionsSection: some View {
        HStack(spacing: Metric.spacing) {
            Image(systemName: "person.2.fill")
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Порции")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text(servings == recipe.servings ? "как в рецепте" : "пересчитано с \(recipe.servings)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 14) {
                Button { setServings(servings - 1) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .buttonStyle(.plain)

                TextField("", value: $servings, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 46)
                    .padding(.vertical, 6)
                    .background(Theme.chip)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
                    .foregroundStyle(Theme.textPrimary)

                Button { setServings(servings + 1) } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }
            .font(.title2)
            .foregroundStyle(Theme.accent)
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        // Держим число в разумных пределах, даже если вписали вручную.
        .onChange(of: servings) { _, newValue in
            let clamped = min(max(newValue, 1), 50)
            if clamped != newValue { servings = clamped }
        }
    }

    private func setServings(_ n: Int) {
        servings = min(max(n, 1), 50)
    }

    private func metaPill(icon: String, text: String, color: Color = Theme.accent) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metric.spacing)
        .cardStyle()
    }

    // Список ингредиентов с галочками.
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            HStack {
                Text("Ингредиенты")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                // Добавляет отмеченные ингредиенты (или все, если ничего не отмечено)
                // в список покупок.
                Button {
                    addToShoppingList()
                } label: {
                    Label("В список", systemImage: "cart.badge.plus")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                }
            }

            ForEach(recipe.ingredients) { ingredient in
                Button {
                    toggle(ingredient.name)
                } label: {
                    HStack {
                        Image(systemName: checkedIngredients.contains(ingredient.name)
                              ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(checkedIngredients.contains(ingredient.name)
                                             ? Theme.green : Theme.textSecondary)
                        Text(ingredient.name)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(ingredient.scaledDisplayAmount(scaleFactor))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // Пошаговая инструкция.
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            Text("Приготовление")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)

            ForEach(recipe.sortedSteps) { step in
                HStack(alignment: .top, spacing: Metric.spacing) {
                    // Кружок с номером шага.
                    Text("\(step.order)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.accent)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.text)
                            .foregroundStyle(Theme.textPrimary)
                        if step.hasTimer {
                            Label(step.timerText, systemImage: "timer")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // Большая кнопка запуска режима готовки.
    private var cookButton: some View {
        Button {
            showingCooking = true
        } label: {
            Label("Приготовить", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        }
    }

    // Поставить/снять галочку у ингредиента.
    private func toggle(_ name: String) {
        if checkedIngredients.contains(name) {
            checkedIngredients.remove(name)
        } else {
            checkedIngredients.insert(name)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: SampleData.recipes()[0])
    }
    .environment(TasteModel())
}
