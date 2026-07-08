//
//  ShoppingItem.swift
//  FoodStory
//
//  Одна строка списка покупок: что купить, сколько и куплено ли уже.
//  Это @Model — значит список сохраняется в базу и не пропадает при перезапуске.
//
//  Пункты можно добавлять вручную на экране списка, из рецепта («добавить все
//  ингредиенты») или из «холодильника».
//

import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var name: String
    var detail: String      // количество текстом, например "200 г" (может быть пустым)
    var isChecked: Bool     // куплено ли
    var createdAt: Date

    init(name: String, detail: String = "", isChecked: Bool = false) {
        self.name = name
        self.detail = detail
        self.isChecked = isChecked
        self.createdAt = Date()
    }
}
