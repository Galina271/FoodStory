//
//  RecipeImageView.swift
//  FoodStory
//
//  Картинка рецепта в одном месте — чтобы везде (карточка, детали, PDF-книга)
//  она выглядела одинаково и по одним правилам:
//   • если у рецепта есть своё фото — показываем его;
//   • если фото нет — рисуем аппетитную заглушку: градиент цвета категории
//     плюс её иконка. Так ни одна карточка не выглядит пустой.
//
//  Компонент маленький и «глупый»: получает рецепт — рисует картинку. Никакой
//  логики сохранения тут нет, поэтому его легко переиспользовать где угодно.
//

import SwiftUI

struct RecipeImageView: View {
    let recipe: Recipe

    // Насколько крупной делать иконку на заглушке (в карточке меньше, в деталях больше).
    var iconSize: CGFloat = 44

    // Показывать ли бейдж с названием категории поверх картинки.
    var showsCategoryBadge: Bool = false

    var body: some View {
        ZStack {
            // Пытаемся достать фото пользователя из сохранённых байтов.
            if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()   // заполняем всю область, лишнее обрезается
            } else {
                placeholder
            }
        }
        // clipped() обрезает всё, что вылезло за рамку (важно для scaledToFill).
        .clipped()
        // Бейдж категории поверх — по желанию.
        .overlay(alignment: .topLeading) {
            if showsCategoryBadge {
                categoryBadge
                    .padding(Metric.spacing)
            }
        }
    }

    // Заглушка: диагональный градиент категории + её иконка по центру.
    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: recipe.category.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: recipe.category.icon)
                .font(.system(size: iconSize))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    // Маленькая «капсула» с названием категории — читается поверх любого фото.
    private var categoryBadge: some View {
        Label(recipe.category.title, systemImage: recipe.category.icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.35), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        RecipeImageView(recipe: SampleData.recipes()[0], iconSize: 56, showsCategoryBadge: true)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
        RecipeImageView(recipe: SampleData.recipes()[2])
            .frame(width: 160, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
    }
    .padding()
    .background(Theme.background)
}
