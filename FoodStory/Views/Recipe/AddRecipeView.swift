//
//  AddRecipeView.swift
//  FoodStory
//
//  Форма рецепта. Один и тот же экран работает в ДВУХ режимах:
//   • создание нового рецепта  — открываем как AddRecipeView();
//   • редактирование готового   — открываем как AddRecipeView(recipeToEdit: recipe).
//
//  Так нам не нужно два почти одинаковых экрана: логика ввода общая, а по кнопке
//  «Сохранить» мы либо создаём новый Recipe, либо обновляем существующий.
//

import SwiftUI
import SwiftData
import PhotosUI   // PhotosPicker — системный выбор фото из галереи

struct AddRecipeView: View {
    @Environment(\.modelContext) private var context  // база, куда сохраняем
    @Environment(\.dismiss) private var dismiss

    // Рецепт, который редактируем. Если nil — значит создаём новый.
    private let recipeToEdit: Recipe?

    // Поля основной информации. Начальные значения подставляем в init:
    // при редактировании — из существующего рецепта, при создании — по умолчанию.
    @State private var title: String
    @State private var summary: String
    @State private var difficulty: Difficulty
    @State private var category: RecipeCategory
    @State private var cookingMinutes: Int
    @State private var servings: Int
    @State private var imageData: Data?

    // Черновики ингредиентов и шагов (простые структуры, пока не сохранены в базу).
    @State private var ingredientDrafts: [IngredientDraft]
    @State private var stepDrafts: [StepDraft]

    // Что выбрал пользователь в системном пикере фото.
    @State private var photoItem: PhotosPickerItem?

    // Определитель категории (Core ML модель или запасной вариант).
    private let categoryPredictor = CategoryPredictorFactory.make()

    // Какой из листов сейчас открыт.
    @State private var showingIngredientSheet = false
    @State private var showingStepSheet = false

    // Ингредиент, который сейчас редактируем (nil — правка закрыта).
    @State private var editingIngredient: IngredientDraft?

    /// init подготавливает начальное состояние формы.
    /// `_title = State(initialValue:)` — так задают стартовое значение для @State
    /// прямо в инициализаторе.
    init(recipeToEdit: Recipe? = nil) {
        self.recipeToEdit = recipeToEdit
        _title = State(initialValue: recipeToEdit?.title ?? "")
        _summary = State(initialValue: recipeToEdit?.summary ?? "")
        _difficulty = State(initialValue: recipeToEdit?.difficulty ?? .easy)
        _category = State(initialValue: recipeToEdit?.category ?? .other)
        _cookingMinutes = State(initialValue: recipeToEdit?.cookingMinutes ?? 30)
        _servings = State(initialValue: recipeToEdit?.servings ?? 2)
        _imageData = State(initialValue: recipeToEdit?.imageData)
        _ingredientDrafts = State(initialValue: (recipeToEdit?.ingredients ?? []).map {
            IngredientDraft(name: $0.name, amount: $0.amount, unit: $0.unit)
        })
        _stepDrafts = State(initialValue: (recipeToEdit?.sortedSteps ?? []).map {
            StepDraft(text: $0.text, timerMinutes: ($0.timerSeconds ?? 0) / 60, prep: $0.prep)
        })
    }

    // Удобные флаги, чтобы подписи менялись сами.
    private var isEditing: Bool { recipeToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                // 0. Фото блюда
                photoSection

                // 1. Основная информация
                Section("Основное") {
                    TextField("Название блюда", text: $title)
                    TextField("Короткое описание", text: $summary, axis: .vertical)
                        .lineLimit(2...4)
                    Picker("Категория", selection: $category) {
                        ForEach(RecipeCategory.allCases) { c in
                            Label(c.title, systemImage: c.icon).tag(c)
                        }
                    }
                    // Кнопка появляется, когда есть название — Core ML модель
                    // подскажет категорию по названию и ингредиентам.
                    if !title.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            if let predicted = categoryPredictor.predictCategory(
                                title: title,
                                ingredients: ingredientDrafts.map { $0.name }
                            ) {
                                category = predicted
                            }
                        } label: {
                            Label("Определить категорию автоматически", systemImage: "sparkles")
                                .font(.subheadline)
                        }
                    }
                    Picker("Сложность", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { d in
                            Text(d.title).tag(d)
                        }
                    }
                    Stepper("Время: \(cookingMinutes) мин", value: $cookingMinutes, in: 5...600, step: 5)
                    Stepper("Порций: \(servings)", value: $servings, in: 1...20)
                }

                // 2. Ингредиенты — по тапу на строку открывается правка.
                Section("Ингредиенты") {
                    ForEach(ingredientDrafts) { draft in
                        Button {
                            editingIngredient = draft
                        } label: {
                            HStack {
                                Text(draft.name)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(displayDraft(draft))
                                    .foregroundStyle(Theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        ingredientDrafts.remove(atOffsets: offsets)
                    }

                    Button {
                        showingIngredientSheet = true
                    } label: {
                        Label("Добавить ингредиент", systemImage: "plus.circle")
                    }
                }

                // 3. Шаги — текст каждого шага редактируется прямо в строке.
                // Под текстом шага — своё поле «Подготовка заранее»: всё, что там
                // написано, соберётся в блок «Подготовка» сверху карточки рецепта.
                Section("Шаги приготовления") {
                    ForEach($stepDrafts) { $draft in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                if let index = stepDrafts.firstIndex(where: { $0.id == draft.id }) {
                                    Text("\(index + 1).")
                                        .foregroundStyle(Theme.accent)
                                }
                                // Редактируемое многострочное поле — можно менять текст шага.
                                TextField("Что нужно сделать?", text: $draft.text, axis: .vertical)
                                    .lineLimit(1...6)
                            }
                            // Поле подготовки для этого шага (появляется под ним).
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checklist")
                                    .font(.caption)
                                    .foregroundStyle(Theme.green)
                                    .padding(.top, 3)
                                TextField("Подготовить заранее (необязательно)",
                                          text: $draft.prep, axis: .vertical)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1...4)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        stepDrafts.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        stepDrafts.move(fromOffsets: from, toOffset: to)
                    }

                    Button {
                        showingStepSheet = true
                    } label: {
                        Label("Добавить шаг", systemImage: "plus.circle")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)   // клавиатуру можно смахнуть вниз
            .keyboardDoneButton()                       // и закрыть кнопкой «Готово»
            .navigationTitle(isEditing ? "Редактировать" : "Новый рецепт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()   // включает режим удаления/перетаскивания
                }
            }
            // Когда пользователь выбрал фото — загружаем его байты в imageData.
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .sheet(isPresented: $showingIngredientSheet) {
                AddIngredientSheet { draft in
                    ingredientDrafts.append(draft)
                }
            }
            // Правка существующего ингредиента: заменяем строку с тем же id.
            .sheet(item: $editingIngredient) { draft in
                AddIngredientSheet(draft: draft) { updated in
                    if let index = ingredientDrafts.firstIndex(where: { $0.id == updated.id }) {
                        ingredientDrafts[index] = updated
                    }
                }
            }
            .sheet(isPresented: $showingStepSheet) {
                AddStepSheet { draft in
                    stepDrafts.append(draft)
                }
            }
        }
    }

    // Секция выбора фото: превью (если есть) + кнопка выбрать/заменить + удалить.
    private var photoSection: some View {
        Section("Фото блюда") {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
                    .listRowInsets(EdgeInsets())

                Button(role: .destructive) {
                    self.imageData = nil
                    photoItem = nil
                } label: {
                    Label("Удалить фото", systemImage: "trash")
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(imageData == nil ? "Выбрать фото" : "Заменить фото",
                      systemImage: "photo")
            }
        }
    }

    private func displayDraft(_ draft: IngredientDraft) -> String {
        guard draft.unit.hasAmount else { return draft.unit.short }
        let number = draft.amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(draft.amount)) : String(draft.amount)
        return "\(number) \(draft.unit.short)"
    }

    // Сохранение: либо обновляем существующий рецепт, либо создаём новый.
    private func save() {
        // Собираем свежие ингредиенты и шаги из черновиков.
        let ingredients = ingredientDrafts.map {
            Ingredient(name: $0.name, amount: $0.amount, unit: $0.unit)
        }
        let steps = stepDrafts.enumerated().map { index, draft in
            Step(
                order: index + 1,
                text: draft.text,
                timerSeconds: draft.timerMinutes > 0 ? draft.timerMinutes * 60 : nil,
                prep: draft.prep.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        if let recipe = recipeToEdit {
            // РЕДАКТИРОВАНИЕ: обновляем поля существующего рецепта.
            recipe.title = title
            recipe.summary = summary
            recipe.difficulty = difficulty
            recipe.category = category
            recipe.cookingMinutes = cookingMinutes
            recipe.servings = servings
            recipe.imageData = imageData

            // Старые ингредиенты и шаги удаляем из базы, чтобы не остались «висеть»,
            // и подставляем новые.
            for old in recipe.ingredients { context.delete(old) }
            for old in recipe.steps { context.delete(old) }
            recipe.ingredients = ingredients
            recipe.steps = steps
        } else {
            // СОЗДАНИЕ: делаем новый рецепт и кладём в базу.
            let recipe = Recipe(
                title: title,
                summary: summary,
                difficulty: difficulty,
                category: category,
                cookingMinutes: cookingMinutes,
                servings: servings,
                imageData: imageData,
                ingredients: ingredients,
                steps: steps
            )
            context.insert(recipe)
        }

        try? context.save()
        dismiss()
    }
}

#Preview("Создание") {
    AddRecipeView()
        .modelContainer(previewContainer)
}

#Preview("Редактирование") {
    AddRecipeView(recipeToEdit: SampleData.recipes()[0])
        .modelContainer(previewContainer)
}
