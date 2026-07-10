//
//  FridgeView.swift
//  FoodStory
//
//  «Холодильник»: вводим продукты, которые есть дома, и приложение предлагает
//  рецепты, отсортированные по количеству совпадений ингредиентов.
//

import SwiftUI
import SwiftData

struct FridgeView: View {
    @Query private var recipes: [Recipe]

    // Продукты, которые пользователь добавил в «холодильник».
    @State private var products: [String] = []
    @State private var newProduct = ""

    // Считаем для каждого рецепта, сколько его ингредиентов есть в холодильнике,
    // и сортируем по убыванию совпадений.
    private var matches: [(recipe: Recipe, count: Int)] {
        guard !products.isEmpty else { return [] }
        let lowered = products.map { $0.lowercased() }

        return recipes
            .map { recipe -> (Recipe, Int) in
                let count = recipe.ingredients.filter { ingredient in
                    lowered.contains { ingredient.name.lowercased().contains($0) }
                }.count
                return (recipe, count)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Metric.padding) {
                    inputRow
                    productChips

                    if matches.isEmpty {
                        Spacer()
                        Text(products.isEmpty
                             ? "Добавьте продукты из холодильника,\nи я предложу, что приготовить."
                             : "Совпадений не найдено.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    } else {
                        resultsList
                    }
                }
                .padding(Metric.padding)
            }
            .keyboardDoneButton()
            .navigationTitle("Холодильник")
        }
        .tint(Theme.accent)
    }

    // Поле ввода + кнопка добавления продукта.
    private var inputRow: some View {
        HStack {
            TextField("Например, яйца", text: $newProduct)
                .padding(10)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
                .onSubmit(addProduct)

            Button(action: addProduct) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    // «Чипсы» добавленных продуктов с возможностью удалить.
    private var productChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(products, id: \.self) { product in
                    HStack(spacing: 4) {
                        Text(product)
                        Button {
                            products.removeAll { $0 == product }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                    }
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

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: Metric.spacing) {
                ForEach(matches, id: \.recipe.id) { match in
                    NavigationLink {
                        RecipeDetailView(recipe: match.recipe)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.recipe.title)
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Совпадений: \(match.count) из \(match.recipe.ingredients.count)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.green)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(Metric.padding)
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addProduct() {
        let trimmed = newProduct.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !products.contains(trimmed) else { return }
        products.append(trimmed)
        newProduct = ""
    }
}

#Preview {
    FridgeView()
        .modelContainer(previewContainer)
}
