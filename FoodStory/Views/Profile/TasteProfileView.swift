//
//  TasteProfileView.swift
//  FoodStory
//
//  «Вкусовой профиль» — окно внутрь нашей обучаемой ИИ-модели. Здесь видно,
//  что именно она выучила про твои предпочтения: какие категории блюд ты
//  любишь, какие ингредиенты в фаворитах, и на скольких примерах она обучилась.
//  Отсюда же модель можно обнулить и начать обучение заново.
//

import SwiftUI

struct TasteProfileView: View {
    @Environment(TasteModel.self) private var taste

    @State private var showingResetConfirm = false

    private var categories: [(category: RecipeCategory, value: Double)] {
        taste.categoryAffinities()
    }

    private var ingredients: [(name: String, value: Double)] {
        taste.topIngredients(limit: 8)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.padding) {

                intro

                if taste.isTrained {
                    categorySection
                    if !ingredients.isEmpty { ingredientSection }
                    resetButton
                } else {
                    emptyState
                }
            }
            .padding(Metric.padding)
        }
        .background(Theme.background)
        .navigationTitle("Вкусовой профиль")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            Label("Обучаемая модель вкуса", systemImage: "brain")
                .font(.headline)
                .foregroundStyle(Theme.accent)
            Text("Модель учится на ваших действиях: избранное и приготовленные блюда сдвигают её оценки. Обучено на \(taste.trainedCount) \(examplesWord(taste.trainedCount)).")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // Полоски симпатии по категориям (от -1 до +1).
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            Text("Категории")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)

            ForEach(categories, id: \.category) { item in
                HStack(spacing: Metric.spacing) {
                    Label(item.category.title, systemImage: item.category.icon)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 130, alignment: .leading)
                    AffinityBar(value: item.value)
                        .frame(height: 10)
                }
            }
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // Любимые ингредиенты — «чипсы».
    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: Metric.spacing) {
            Text("Любимые ингредиенты")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)

            FlowChips(items: ingredients.map { $0.name })
        }
        .padding(Metric.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            showingResetConfirm = true
        } label: {
            Label("Сбросить обучение", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.chip)
                .foregroundStyle(Theme.tomato)
                .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        }
        .confirmationDialog("Забыть всё, что модель выучила?",
                            isPresented: $showingResetConfirm,
                            titleVisibility: .visible) {
            Button("Сбросить", role: .destructive) { taste.reset() }
            Button("Отмена", role: .cancel) { }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Модель ещё учится", systemImage: "sparkles")
        } description: {
            Text("Добавляйте рецепты в избранное ❤️ и готовьте — и здесь появится ваш вкусовой профиль, а рекомендации на главной станут персональными.")
        }
        .padding(.top, 40)
    }

    /// 1 пример, 2 примера, 5 примеров.
    private func examplesWord(_ n: Int) -> String {
        let mod100 = n % 100, mod10 = n % 10
        if mod100 >= 11 && mod100 <= 14 { return "примерах" }
        switch mod10 {
        case 1: return "примере"
        case 2, 3, 4: return "примерах"
        default: return "примерах"
        }
    }
}

// Полоска симпатии: центр = 0, вправо и зелёным = нравится, влево и красным = нет.
private struct AffinityBar: View {
    let value: Double   // ожидаем примерно [-1, 1]

    var body: some View {
        GeometryReader { geo in
            let fullWidth = geo.size.width
            let half = fullWidth / 2
            let magnitude = min(abs(value), 1) * half

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.chip)
                    .frame(height: 8)
                Capsule()
                    .fill(value >= 0 ? Theme.green : Theme.tomato)
                    .frame(width: magnitude, height: 8)
                    .offset(x: value >= 0 ? half : half - magnitude)
            }
            .frame(height: geo.size.height, alignment: .center)
        }
    }
}

// Простая «обёртка» чипсов в несколько строк.
private struct FlowChips: View {
    let items: [String]

    var body: some View {
        // Для наглядности хватит вертикального списка «чипсов» по строкам.
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows(), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { name in
                        Text(name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.chip)
                            .foregroundStyle(Theme.textPrimary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // Разбиваем ингредиенты по 3 в строку.
    private func rows() -> [[String]] {
        stride(from: 0, to: items.count, by: 3).map {
            Array(items[$0 ..< min($0 + 3, items.count)])
        }
    }
}

#Preview {
    // Немного «обучим» модель для наглядного превью.
    let model = TasteModel()
    for recipe in SampleData.recipes() {
        model.train(on: recipe, liked: true)
    }
    return NavigationStack { TasteProfileView() }
        .environment(model)
}
