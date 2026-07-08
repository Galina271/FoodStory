//
//  AppThemeOption.swift
//  FoodStory
//
//  Здесь живут ТЕМЫ оформления. Раньше цвета в Theme были «прибиты гвоздями»
//  (одна кремово-оранжевая палитра). Теперь их можно менять на лету.
//
//  Как это работает:
//   • ThemePalette — «коробка» из всех цветов приложения.
//   • AppThemeOption — перечисление тем (7 штук), у каждой своя палитра.
//   • ThemeManager — единый «хранитель» текущей темы (@Observable-синглтон).
//     Когда пользователь меняет тему, ThemeManager обновляется, и SwiftUI
//     сам перекрашивает все экраны, потому что цвета Theme.* читаются из него.
//   Выбор сохраняется в UserDefaults и не пропадает между запусками.
//

import SwiftUI

// MARK: - Палитра (набор цветов одной темы)

struct ThemePalette {
    let background: Color
    let card: Color
    let accent: Color
    let green: Color
    let tomato: Color
    let textPrimary: Color
    let textSecondary: Color
    let chip: Color
}

// MARK: - Темы

enum AppThemeOption: String, CaseIterable, Identifiable {
    case classic    // кремово-оранжевая (по умолчанию)
    case dark       // тёмная
    case ocean      // морская сине-бирюзовая
    case forest     // лесная зелёная
    case berry      // ягодная фиолетовая
    case sunset     // тёплый закат (коралл)
    case mono       // минимал: графит

    var id: String { rawValue }

    /// Название для интерфейса.
    var title: String {
        switch self {
        case .classic: return "Классическая"
        case .dark:    return "Тёмная"
        case .ocean:   return "Морская"
        case .forest:  return "Лесная"
        case .berry:   return "Ягодная"
        case .sunset:  return "Закат"
        case .mono:    return "Графит"
        }
    }

    /// Тёмная ли тема — нужно, чтобы системные элементы (статус-бар, клавиатура)
    /// подстроились под светлую/тёмную гамму.
    var isDark: Bool { self == .dark }

    /// Полный набор цветов темы.
    var palette: ThemePalette {
        switch self {
        case .classic:
            return ThemePalette(
                background: Color(hex: 0xFBF6EF), card: Color(hex: 0xFFFFFF),
                accent: Color(hex: 0xEA8A3C), green: Color(hex: 0x6FA86A),
                tomato: Color(hex: 0xE0533D), textPrimary: Color(hex: 0x3A2E26),
                textSecondary: Color(hex: 0x9A8A7C), chip: Color(hex: 0xF1E7DA))
        case .dark:
            return ThemePalette(
                background: Color(hex: 0x1C1B1A), card: Color(hex: 0x2A2825),
                accent: Color(hex: 0xF0954A), green: Color(hex: 0x7FB877),
                tomato: Color(hex: 0xE8664F), textPrimary: Color(hex: 0xF3EEE7),
                textSecondary: Color(hex: 0xA79E93), chip: Color(hex: 0x393530))
        case .ocean:
            return ThemePalette(
                background: Color(hex: 0xEEF6F8), card: Color(hex: 0xFFFFFF),
                accent: Color(hex: 0x2E8B9E), green: Color(hex: 0x3FA79E),
                tomato: Color(hex: 0xE0664D), textPrimary: Color(hex: 0x1E3A44),
                textSecondary: Color(hex: 0x7C97A0), chip: Color(hex: 0xD9EAEE))
        case .forest:
            return ThemePalette(
                background: Color(hex: 0xF1F5EC), card: Color(hex: 0xFFFFFF),
                accent: Color(hex: 0x4F7A34), green: Color(hex: 0x86A867),
                tomato: Color(hex: 0xCF6A32), textPrimary: Color(hex: 0x26331F),
                textSecondary: Color(hex: 0x8A9880), chip: Color(hex: 0xE2EAD8))
        case .berry:
            return ThemePalette(
                background: Color(hex: 0xF7EFF6), card: Color(hex: 0xFFFFFF),
                accent: Color(hex: 0xB0559A), green: Color(hex: 0x6FA86A),
                tomato: Color(hex: 0xD84E7A), textPrimary: Color(hex: 0x3A2636),
                textSecondary: Color(hex: 0x9A8494), chip: Color(hex: 0xEBDCE9))
        case .sunset:
            return ThemePalette(
                background: Color(hex: 0xFFF2EC), card: Color(hex: 0xFFFFFF),
                accent: Color(hex: 0xF06E4B), green: Color(hex: 0x6FA86A),
                tomato: Color(hex: 0xE24D5B), textPrimary: Color(hex: 0x40261F),
                textSecondary: Color(hex: 0xA78A80), chip: Color(hex: 0xFBDFD3))
        case .mono:
            return ThemePalette(
                background: Color(hex: 0xF4F4F2), card: Color(hex: 0xFFFFFF),
                accent: Color(hex: 0x3A3A3A), green: Color(hex: 0x5E7D5A),
                tomato: Color(hex: 0xB4503C), textPrimary: Color(hex: 0x1F1F1F),
                textSecondary: Color(hex: 0x8A8A88), chip: Color(hex: 0xE7E7E4))
        }
    }

    /// Три цвета-образца для превью в списке тем.
    var swatch: [Color] { [palette.accent, palette.green, palette.tomato] }
}

// MARK: - Хранитель текущей темы

@Observable
final class ThemeManager {
    /// Один общий экземпляр на всё приложение.
    static let shared = ThemeManager()

    private static let storageKey = "appTheme"

    /// Выбранная тема. При изменении — сохраняем в UserDefaults.
    var selected: AppThemeOption {
        didSet { UserDefaults.standard.set(selected.rawValue, forKey: Self.storageKey) }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        selected = AppThemeOption(rawValue: saved ?? "") ?? .classic
    }

    /// Текущая палитра — её читают все цвета Theme.*.
    var palette: ThemePalette { selected.palette }

    /// Светлая/тёмная схема для системных элементов.
    var colorScheme: ColorScheme? { selected.isDark ? .dark : .light }
}
