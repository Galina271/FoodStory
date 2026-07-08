//
//  ShareSheet.swift
//  FoodStory
//
//  Маленькая обёртка над системным окном «Поделиться» (UIActivityViewController).
//  В SwiftUI есть готовый ShareLink, но он требует, чтобы файл уже существовал в
//  момент отрисовки. Нам же удобнее сгенерировать PDF по нажатию, а потом показать
//  это окно — для такого сценария подходит собственная обёртка.
//
//  UIViewControllerRepresentable — «мостик», который позволяет вставить
//  UIKit-экран (тут — окно шаринга) внутрь SwiftUI.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]   // что шарим — например, ссылку на PDF-файл

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {
        // Обновлять нечего — окно одноразовое.
    }
}
