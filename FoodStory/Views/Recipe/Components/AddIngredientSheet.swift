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
    var id = UUID()
    var name: String
    var amount: Double
    var unit: IngredientUnit
}

struct AddIngredientSheet: View {
    // Замыкание (closure): функция, которую мы вызовем при сохранении.
    // Через неё «возвращаем» готовый черновик в родительский экран.
    var onSave: (IngredientDraft) -> Void

    // Если передали существующий черновик — открываемся в режиме РЕДАКТИРОВАНИЯ
    // (поля уже заполнены, кнопка называется «Сохранить»). Если nil — добавляем новый.
    private let editingDraft: IngredientDraft?

    @Environment(\.dismiss) private var dismiss   // умеет закрывать этот лист

    @State private var name: String
    @State private var amount: String
    @State private var unit: IngredientUnit

    init(draft: IngredientDraft? = nil, onSave: @escaping (IngredientDraft) -> Void) {
        self.editingDraft = draft
        self.onSave = onSave
        _name = State(initialValue: draft?.name ?? "")
        // Количество показываем без лишнего ".0" — так удобнее редактировать.
        if let amount = draft?.amount, amount > 0 {
            let clean = amount.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(amount)) : String(amount)
            _amount = State(initialValue: clean)
        } else {
            _amount = State(initialValue: "")
        }
        _unit = State(initialValue: draft?.unit ?? .gram)
    }

    private var isEditing: Bool { editingDraft != nil }

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
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle(isEditing ? "Изменить ингредиент" : "Ингредиент")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Сохранить" : "Добавить") {
                        // Запятую заменяем на точку — на русской клавиатуре часто вводят "1,5".
                        let value = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
                        // id сохраняем при редактировании, чтобы обновить именно эту строку.
                        var draft = IngredientDraft(name: name, amount: value, unit: unit)
                        if let editingDraft { draft.id = editingDraft.id }
                        onSave(draft)
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
