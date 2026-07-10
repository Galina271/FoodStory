//
//  WelcomeView.swift
//  FoodStory
//
//  Экран приветствия при самом первом запуске: коротко рассказывает, что умеет
//  приложение, и просит имя. Показывается один раз (флаг hasOnboarded), потом
//  сразу открывается основной экран.
//

import SwiftUI

struct WelcomeView: View {
    var onDone: () -> Void

    @AppStorage("userName") private var userName = "Галина"
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var name = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Metric.padding) {

                // Логотип-эмблема в фирменных цветах.
                ZStack {
                    Circle().fill(Theme.accent)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                }
                .frame(width: 110, height: 110)
                .padding(.top, 40)

                Text("Добро пожаловать\nв FoodStory")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)

                Text("Ваша личная кулинарная книга, которая учится на ваших вкусах.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal)

                // Три ключевые возможности.
                VStack(alignment: .leading, spacing: Metric.spacing) {
                    feature(icon: "book.fill", title: "Храните рецепты",
                            subtitle: "С фото, ингредиентами и шагами")
                    feature(icon: "flame.fill", title: "Готовьте по шагам",
                            subtitle: "С таймером и напоминаниями")
                    feature(icon: "sparkles", title: "Умные подсказки",
                            subtitle: "Рекомендации под ваш вкус")
                }
                .padding(Metric.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Имя пользователя.
                VStack(alignment: .leading, spacing: 6) {
                    Text("Как вас зовут?")
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.textPrimary)
                    TextField("Имя", text: $name)
                        .padding(10)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
                }

                Button {
                    start()
                } label: {
                    Text("Начать готовить")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
                }
                .padding(.top, Metric.spacing)
            }
            .padding(Metric.padding)
        }
        .background(Theme.background)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .onAppear { name = userName }
    }

    private func feature(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Metric.spacing) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func start() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { userName = trimmed }
        hasOnboarded = true
        onDone()
    }
}

#Preview {
    WelcomeView { }
}
