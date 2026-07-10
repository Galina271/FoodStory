//
//  ProfileView.swift
//  FoodStory
//
//  Профиль: статистика (сколько рецептов, сколько приготовлено) и разделы —
//  Коллекции, Книга рецептов (PDF) и Настройки. Все они теперь рабочие.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Recipe.createdAt) private var recipes: [Recipe]

    // Имя из настроек (то же, что в приветствии на главной).
    @AppStorage("userName") private var userName = "Галина"

    // Готовая PDF-книга. Как только сюда попадает ссылка на файл — открывается
    // просмотр (через .sheet(item:)). Это надёжнее двух отдельных флагов:
    // лист откроется ровно тогда, когда файл действительно готов.
    @State private var book: PDFBook?

    private var totalCooked: Int {
        recipes.reduce(0) { $0 + $1.cookedCount }
    }

    private var favoritesCount: Int {
        recipes.filter { $0.isFavorite }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metric.padding) {

                    // Аватар + имя.
                    VStack(spacing: Metric.spacing) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(Theme.accent)
                        Text(userName)
                            .font(.title2.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.top)

                    // Карточки статистики.
                    HStack(spacing: Metric.spacing) {
                        statCard(value: "\(recipes.count)", label: "Рецептов")
                        statCard(value: "\(totalCooked)", label: "Приготовлено")
                        statCard(value: "\(favoritesCount)", label: "Избранных")
                    }

                    // Разделы — теперь кликабельные.
                    VStack(spacing: 0) {
                        NavigationLink {
                            CollectionsView()
                        } label: {
                            settingsRow(icon: "folder", title: "Коллекции")
                        }
                        Divider().padding(.leading, 52)

                        NavigationLink {
                            TasteProfileView()
                        } label: {
                            settingsRow(icon: "sparkles", title: "Вкусовой профиль (ИИ)")
                        }
                        Divider().padding(.leading, 52)

                        Button {
                            exportPDF()
                        } label: {
                            settingsRow(icon: "square.and.arrow.up", title: "Книга рецептов (PDF)")
                        }
                        .disabled(recipes.isEmpty)
                        Divider().padding(.leading, 52)

                        NavigationLink {
                            SettingsView()
                        } label: {
                            settingsRow(icon: "gearshape", title: "Настройки")
                        }
                    }
                    .cardStyle()
                }
                .padding(Metric.padding)
            }
            .background(Theme.background)
            .navigationTitle("Профиль")
            // Просмотр готовой книги прямо в приложении (PDFKit) с кнопками
            // «Готово» и «Сохранить» — файл открывается быстро и сохраняется
            // на устройство через «Сохранить в Файлы».
            .sheet(item: $book) { book in
                PDFBookView(url: book.url)
            }
        }
        .tint(Theme.accent)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(Theme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metric.padding)
        .cardStyle()
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: Metric.spacing) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(Theme.accent)
            Text(title)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Metric.padding)
        .contentShape(Rectangle())   // вся строка кликабельна, не только текст
    }

    // Собирает PDF-книгу и открывает её просмотр. Если ссылка получена —
    // присваиваем book, и .sheet(item:) сам покажет просмотрщик.
    private func exportPDF() {
        if let url = RecipeBookPDF.makeURL(recipes: recipes, author: userName) {
            book = PDFBook(url: url)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(previewContainer)
        .environment(TasteModel())
}
