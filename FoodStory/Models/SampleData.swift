//
//  SampleData.swift
//  FoodStory
//
//  Несколько готовых рецептов. Нужны для двух вещей:
//  1. Чтобы при ПЕРВОМ запуске приложение было не пустым.
//  2. Чтобы Xcode Preview (живой предпросмотр экранов) показывал реальные карточки.
//

import Foundation

enum SampleData {

    /// Функция создаёт массив готовых рецептов.
    /// Каждый раз создаём НОВЫЕ объекты, потому что один объект SwiftData
    /// нельзя вставить в базу дважды.
    static func recipes() -> [Recipe] {
        [
            Recipe(
                title: "Паста Карбонара",
                summary: "Классика итальянской кухни: сливочно, сытно, за полчаса.",
                difficulty: .medium,
                category: .main,
                cookingMinutes: 25,
                servings: 2,
                ingredients: [
                    Ingredient(name: "Спагетти", amount: 200, unit: .gram),
                    Ingredient(name: "Бекон", amount: 150, unit: .gram),
                    Ingredient(name: "Яйца", amount: 2, unit: .piece),
                    Ingredient(name: "Пармезан", amount: 50, unit: .gram),
                    Ingredient(name: "Соль", amount: 0, unit: .toTaste)
                ],
                steps: [
                    Step(order: 1, text: "Отварите спагетти в подсолённой воде до состояния аль денте.", timerSeconds: 600),
                    Step(order: 2, text: "Обжарьте нарезанный бекон до золотистости."),
                    Step(order: 3, text: "Взбейте яйца с тёртым пармезаном."),
                    Step(order: 4, text: "Смешайте горячую пасту с беконом, снимите с огня и влейте яичную смесь, быстро перемешивая.")
                ]
            ),
            Recipe(
                title: "Овсянка с ягодами",
                summary: "Быстрый и полезный завтрак на каждый день.",
                difficulty: .easy,
                category: .breakfast,
                cookingMinutes: 10,
                servings: 1,
                ingredients: [
                    Ingredient(name: "Овсяные хлопья", amount: 50, unit: .gram),
                    Ingredient(name: "Молоко", amount: 200, unit: .milliliter),
                    Ingredient(name: "Ягоды", amount: 1, unit: .cup),
                    Ingredient(name: "Мёд", amount: 1, unit: .tablespoon)
                ],
                steps: [
                    Step(order: 1, text: "Залейте хлопья молоком и доведите до кипения.", timerSeconds: 300),
                    Step(order: 2, text: "Дайте настояться пару минут.", timerSeconds: 120),
                    Step(order: 3, text: "Добавьте ягоды и мёд.")
                ]
            ),
            Recipe(
                title: "Шоколадный фондан",
                summary: "Тёплый десерт с жидкой серединкой. Для особого случая.",
                difficulty: .hard,
                category: .dessert,
                cookingMinutes: 40,
                servings: 4,
                ingredients: [
                    Ingredient(name: "Тёмный шоколад", amount: 200, unit: .gram),
                    Ingredient(name: "Сливочное масло", amount: 100, unit: .gram),
                    Ingredient(name: "Яйца", amount: 4, unit: .piece),
                    Ingredient(name: "Сахар", amount: 100, unit: .gram),
                    Ingredient(name: "Мука", amount: 60, unit: .gram)
                ],
                steps: [
                    Step(order: 1, text: "Растопите шоколад с маслом на водяной бане."),
                    Step(order: 2, text: "Взбейте яйца с сахаром до пышности."),
                    Step(order: 3, text: "Соедините массы, добавьте муку."),
                    Step(order: 4, text: "Выпекайте в разогретой духовке.", timerSeconds: 720)
                ]
            )
        ]
    }
}
