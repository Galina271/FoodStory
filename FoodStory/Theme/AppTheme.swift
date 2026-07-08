//
//  AppTheme.swift
//  FoodStory
//
//  Здесь живёт ВСЯ палитра приложения и общие размеры (отступы, скругления).
//  Идея: цвета нигде не пишем «вручную» по экранам, а берём только отсюда.
//  Тогда, если завтра захочешь поменять оттенок оранжевого — правишь одну строчку,
//  и весь интерфейс меняется сразу.
//

import SwiftUI

// MARK: - Палитра

/// `Theme` — это просто «коробка» с цветами. Мы пишем `Theme.accent`, `Theme.background` и т.д.
/// `enum` без вариантов используется как пространство имён — внутри только статические свойства.
enum Theme {

    // Фон всего экрана — тёплый кремовый, как страница кулинарной книги.
    static let background = Color(hex: 0xFBF6EF)

    // Поверхность карточек — чистый белый, чтобы карточки «приподнимались» над фоном.
    static let card = Color(hex: 0xFFFFFF)

    // Основной акцент — тёплый тыквенный оранжевый (кнопки, активные иконки).
    static let accent = Color(hex: 0xEA8A3C)

    // Дополнительный акцент — мягкий травяной зелёный (теги, «здоровое», свежесть).
    static let green = Color(hex: 0x6FA86A)

    // Цвет «избранного»/важного — томатно-красный.
    static let tomato = Color(hex: 0xE0533D)

    // Основной текст — тёмно-коричневый (мягче чистого чёрного, выглядит «вкуснее»).
    static let textPrimary = Color(hex: 0x3A2E26)

    // Второстепенный текст — приглушённый коричневый (подписи, метаданные).
    static let textSecondary = Color(hex: 0x9A8A7C)

    // Лёгкая заливка для «капсул»/чипсов под фильтры и теги.
    static let chip = Color(hex: 0xF1E7DA)
}

// MARK: - Размеры

/// Общие отступы и скругления, чтобы интерфейс был единообразным.
enum Metric {
    static let cornerRadius: CGFloat = 18      // скругление карточек
    static let smallRadius: CGFloat = 12       // скругление мелких элементов
    static let padding: CGFloat = 16           // стандартный внутренний отступ
    static let spacing: CGFloat = 12           // расстояние между элементами
}

// MARK: - Удобный инициализатор цвета из HEX

extension Color {
    /// Позволяет писать `Color(hex: 0xEA8A3C)` вместо длинной записи с долями.
    /// Внутри мы «разбираем» число на красную, зелёную и синюю составляющие.
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - Готовые «строительные блоки» вида

/// Модификатор, который превращает любой контент в «карточку»:
/// белый фон, скругление, мягкая тень. Применяется так: `.cardStyle()`.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Короткая запись для применения стиля карточки.
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
