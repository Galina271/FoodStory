//
//  SettingsView.swift
//  FoodStory
//
//  Простые настройки. Пока здесь имя пользователя — оно подставляется в
//  приветствие на главной и в профиле. Значение хранится в @AppStorage:
//  это крохотное постоянное хранилище (UserDefaults) для маленьких настроек,
//  которое само сохраняется между запусками.
//

import SwiftUI

struct SettingsView: View {
    // Тот же ключ "userName" используется на главной и в профиле —
    // поэтому имя меняется сразу везде.
    @AppStorage("userName") private var userName = "Галина"

    var body: some View {
        Form {
            Section("Имя") {
                TextField("Как вас зовут?", text: $userName)
            }

            Section("О приложении") {
                LabeledContent("Версия", value: "1.0")
                LabeledContent("Рецептов создано с любовью", value: "❤️")
            }

            Section {
                Text("Скоро здесь появятся тёмная тема, единицы измерения и напоминания.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
