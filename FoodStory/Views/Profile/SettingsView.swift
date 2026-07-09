//
//  SettingsView.swift
//  FoodStory
//
//  Настройки: имя пользователя и выбор темы оформления (7 вариантов).
//  Тема применяется мгновенно ко всему приложению и сохраняется между запусками.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = "Галина"

    // Хранитель темы. Чтение его свойств в body подписывает экран на изменения,
    // поэтому галочка у выбранной темы обновляется сразу.
    private var theme: ThemeManager { ThemeManager.shared }

    // Адрес и токен нашего сервера-прокси к Claude (для AI-генерации рецептов).
    @AppStorage("assistantServerURL") private var serverURL = ""
    @AppStorage("assistantServerToken") private var serverToken = ""

    var body: some View {
        Form {
            Section("Имя") {
                TextField("Как вас зовут?", text: $userName)
            }

            Section("Тема оформления") {
                ForEach(AppThemeOption.allCases) { option in
                    Button {
                        theme.selected = option
                    } label: {
                        themeRow(option)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                TextField("https://ваш-сервер", text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                TextField("Токен (если задан на сервере)", text: $serverToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("AI-помощник (сервер)")
            } footer: {
                Text("Адрес вашего сервера-прокси к Claude. Пока не заполнено — помощник работает офлайн (подбор из ваших рецептов). Инструкция по серверу — в папке server/ проекта.")
            }

            Section("О приложении") {
                LabeledContent("Версия", value: "1.0")
                LabeledContent("Сделано с любовью", value: "❤️")
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Одна строка списка тем: образцы цветов + название + галочка у выбранной.
    private func themeRow(_ option: AppThemeOption) -> some View {
        HStack(spacing: Metric.spacing) {
            ThemeSwatch(option: option)
            Text(option.title)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if theme.selected == option {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accent)
            }
        }
        .contentShape(Rectangle())   // вся строка кликабельна
    }
}

// Маленькое превью темы: прямоугольник цвета фона с тремя точками-акцентами.
private struct ThemeSwatch: View {
    let option: AppThemeOption

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(option.palette.background)
            HStack(spacing: 3) {
                ForEach(Array(option.swatch.enumerated()), id: \.offset) { _, color in
                    Circle().fill(color).frame(width: 9, height: 9)
                }
            }
        }
        .frame(width: 56, height: 34)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
