//
//  AddIngredientSheet.swift
//  FoodStory
//
//  Маленький экран («лист»), который выезжает снизу, чтобы добавить один ингредиент.
//
//  Чтобы не создавать объекты SwiftData раньше времени, мы работаем с «черновиком» —
//  простой структурой IngredientDraft. В настоящий @Model она превратится только
//  при сохранении всего рецепта.
//

import SwiftUI

// Лёгкий «черновик» ингредиента. struct (значимый тип) — копируется, не сохраняется в базу.
struct IngredientDraft: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
    var unit: IngredientUnit
}

struct AddIngredientSheet: View {
    // Замыкание (closure): функция, которую мы вызовем, когда пользователь нажмёт «Добавить».
    // Через неё «возвращаем» готовый черновик в родительский экран.
    var onAdd: (IngredientDraft) -> Void

    @Environment(\.dismiss) private var dismiss   // умеет закрывать этот лист

    @State private var name = ""
    @State private var amount = ""
    @State private var unit: IngredientUnit = .gram

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название (например, Мука)", text: $name)

                Section {
                    if unit.hasAmount {
                        TextField("Количество", text: $amount)
                            .keyboardType(.decimalPad)   // цифровая клавиатура
                    }
                    Picker("Единица", selection: $unit) {
                        ForEach(IngredientUnit.allCases) { u in
                            Text(u.short).tag(u)
                        }
                    }
                }
            }
            .navigationTitle("Ингредиент")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        // Запятую заменяем на точку — на русской клавиатуре часто вводят "1,5".
                        let value = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let draft = IngredientDraft(name: name, amount: value, unit: unit)
                        onAdd(draft)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)  // пустое имя нельзя
                }
            }
        }
    }
}

#Preview {
    AddIngredientSheet { _ in }
}
