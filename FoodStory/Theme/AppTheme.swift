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

/// `Theme` — это «коробка» с цветами. Мы пишем `Theme.accent`, `Theme.background` и т.д.
/// Раньше цвета были фиксированными. Теперь каждое свойство берёт цвет из ТЕКУЩЕЙ
/// темы (ThemeManager). Поскольку ThemeManager помечен @Observable, при смене темы
/// SwiftUI автоматически перекрашивает все экраны, которые читают эти цвета.
enum Theme {

    /// Текущая палитра (набор цветов выбранной темы).
    static var current: ThemePalette { ThemeManager.shared.palette }

    // Фон всего экрана.
    static var background: Color { current.background }

    // Поверхность карточек.
    static var card: Color { current.card }

    // Основной акцент (кнопки, активные иконки).
    static var accent: Color { current.accent }

    // Дополнительный акцент (теги, «свежесть»).
    static var green: Color { current.green }

    // Цвет «избранного»/важного.
    static var tomato: Color { current.tomato }

    // Основной текст.
    static var textPrimary: Color { current.textPrimary }

    // Второстепенный текст (подписи, метаданные).
    static var textSecondary: Color { current.textSecondary }

    // Лёгкая заливка для «капсул»/чипсов.
    static var chip: Color { current.chip }
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
