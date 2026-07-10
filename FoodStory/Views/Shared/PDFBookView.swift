//
//  PDFBookView.swift
//  FoodStory
//
//  Экран просмотра готовой книги рецептов (PDF). Используем PDFKit —
//  он открывает файл мгновенно и листает страницы прямо в приложении
//  (в отличие от QuickLook, который на устройстве грузился медленно).
//
//  Вверху две понятные кнопки:
//   • «Готово»    — закрыть просмотр;
//   • «Сохранить» — системное меню «Поделиться» (ShareLink), где есть пункт
//     «Сохранить в Файлы» — это и есть скачивание книги в PDF на устройство.
//

import SwiftUI
import PDFKit

/// Обёртка над ссылкой на файл книги, чтобы показывать её через .sheet(item:).
/// Как только появляется PDFBook — SwiftUI открывает просмотр (без гонки состояний).
struct PDFBook: Identifiable {
    let id = UUID()
    let url: URL
}

struct PDFBookView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Книга рецептов")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Готово") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        // ShareLink с ссылкой на файл сразу предлагает
                        // «Сохранить в Файлы», отправить или распечатать.
                        ShareLink(item: url) {
                            Label("Сохранить", systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

/// Тонкая обёртка над PDFView из PDFKit — показывает и листает PDF.
private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true                 // страница подгоняется по ширине
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical      // листаем вертикально, как ленту
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        // Если файл сменился — перезагружаем документ.
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}
