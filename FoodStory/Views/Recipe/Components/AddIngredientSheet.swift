import SwiftUI

struct AddIngredientSheet: View {

    @Environment(\.dismiss) private var dismiss

    let onSave: (Ingredient) -> Void

    @State private var name = ""
    @State private var amount = ""
    @State private var unit: IngredientUnit = .gram

    var body: some View {

        NavigationStack {

            Form {

                Section("Ингредиент") {

                    TextField("Название", text: $name)

                    TextField("Количество", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Единица", selection: $unit) {

                        ForEach(IngredientUnit.allCases, id: \.self) { unit in
                            Text(unit.title)
                                .tag(unit)
                        }
                    }
                }
            }
            .navigationTitle("Новый ингредиент")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Добавить") {
                        saveIngredient()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveIngredient() {

        let value = Double(amount) ?? 0

        let ingredient = Ingredient(
            name: name,
            amount: value,
            unit: unit
        )

        onSave(ingredient)

        dismiss()
    }
}

#Preview {
    AddIngredientSheet { _ in

    }
}
