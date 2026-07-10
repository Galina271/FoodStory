//
//  RecipeCategory.swift
//  FoodStory
//
//  Категория блюда: завтрак, суп, горячее, салат и т.д.
//  Категория решает сразу две задачи:
//   1. По ней можно фильтровать и группировать рецепты (раздел «Коллекции»).
//   2. Если у рецепта НЕТ своего фото — мы рисуем красивую заглушку с цветом и
//      иконкой этой категории, чтобы карточка выглядела аппетитно, а не пусто.
//
//  Это `enum` со строковым «сырьём» (String) — такое значение SwiftData умеет
//  сохранять в базу как обычную строку ("breakfast", "soup" ...).
//

import SwiftUI

enum RecipeCategory: String, Codable, CaseIterable, Identifiable {
    case breakfast     // завтрак
    case soup          // суп
    case main          // горячее / основное блюдо
    case salad         // салат / закуска
    case dessert       // десерт
    case baking        // выпечка
    case drink         // напиток
    case other         // другое (значение по умолчанию)

    var id: String { rawValue }

    /// Название на русском — то, что видит пользователь в пикере и на бейджах.
    var title: String {
        switch self {
        case .breakfast: return "Завтрак"
        case .soup:      return "Суп"
        case .main:      return "Горячее"
        case .salad:     return "Салат"
        case .dessert:   return "Десерт"
        case .baking:    return "Выпечка"
        case .drink:     return "Напиток"
        case .other:     return "Другое"
        }
    }

    /// Иконка из набора SF Symbols — рисуется на заглушке вместо фото.
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .soup:      return "cup.and.saucer.fill"
        case .main:      return "fork.knife"
        case .salad:     return "leaf.fill"
        case .dessert:   return "birthday.cake.fill"
        case .baking:    return "oven.fill"
        case .drink:     return "wineglass.fill"
        case .other:     return "fork.knife"
        }
    }

    /// Пара цветов для градиента-заглушки. Каждой категории — свой аппетитный оттенок.
    var gradient: [Color] {
        switch self {
        case .breakfast: return [Color(hex: 0xF6B24B), Color(hex: 0xEA8A3C)]
        case .soup:      return [Color(hex: 0xE0745A), Color(hex: 0xD1533D)]
        case .main:      return [Color(hex: 0xEA8A3C), Color(hex: 0x6FA86A)]
        case .salad:     return [Color(hex: 0x8FBF6A), Color(hex: 0x5B9A55)]
        case .dessert:   return [Color(hex: 0xE68AA8), Color(hex: 0xB86FA8)]
        case .baking:    return [Color(hex: 0xC9915A), Color(hex: 0xA8703C)]
        case .drink:     return [Color(hex: 0x5AB6C9), Color(hex: 0x3C93A8)]
        case .other:     return [Color(hex: 0xB0A08F), Color(hex: 0x8A7A6C)]
        }
    }
}
