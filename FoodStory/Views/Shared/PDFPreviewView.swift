//
//  PDFPreviewView.swift
//  FoodStory
//
//  Показывает готовый PDF прямо в приложении через системный просмотрщик
//  QuickLook. Так пользователь сразу видит книгу рецептов (что она НЕ пустая),
//  а встроенная кнопка «Поделиться» вверху справа позволяет сохранить файл
//  на устройство («Сохранить в Файлы»), отправить или распечатать.
//
//  QLPreviewController — это готовый экран Apple; мы лишь оборачиваем его в
//  SwiftUI через UIViewControllerRepresentable и даём ему ссылку на файл.
//

import SwiftUI
import QuickLook

struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {
        context.coordinator.url = url
        controller.reloadData()
    }

    // Источник данных для просмотрщика: сообщаем ему один файл — нашу книгу.
    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController,
                               previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}
