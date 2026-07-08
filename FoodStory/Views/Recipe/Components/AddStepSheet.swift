//
//  AddStepSheet.swift
//  FoodStory
//
//  Лист для добавления одного шага приготовления (с опциональным таймером).
//

import SwiftUI

// Черновик шага. order проставим позже, при сохранении (по порядку добавления).
struct StepDraft: Identifiable {
    let id = UUID()
    var text: String
    var timerMinutes: Int   // 0 = без таймера
}

struct AddStepSheet: View {
    var onAdd: (StepDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var hasTimer = false
    @State private var minutes = 5

    var body: some View {
        NavigationStack {
            Form {
                Section("Описание шага") {
                    // Многострочное поле ввода.
                    TextField("Что нужно сделать?", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Добавить таймер", isOn: $hasTimer)
                    if hasTimer {
                        Stepper("Таймер: \(minutes) мин", value: $minutes, in: 1...180)
                    }
                }
            }
            .navigationTitle("Шаг")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        let draft = StepDraft(text: text, timerMinutes: hasTimer ? minutes : 0)
                        onAdd(draft)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddStepSheet { _ in }
}
