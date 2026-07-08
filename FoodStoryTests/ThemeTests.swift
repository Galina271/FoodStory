//
//  ThemeTests.swift
//  FoodStoryTests
//
//  Проверяем набор тем оформления: что их ровно 7, ровно одна тёмная,
//  у каждой есть название и три цвета-образца.
//

import Testing
@testable import FoodStory

struct ThemeTests {

    @Test func eightThemesAvailable() {
        // 7 цветовых тем + «как в системе».
        #expect(AppThemeOption.allCases.count == 8)
        #expect(AppThemeOption.allCases.contains(.system))
    }

    @Test func exactlyOneDarkTheme() {
        let darkCount = AppThemeOption.allCases.filter { $0.isDark }.count
        #expect(darkCount == 1)
        #expect(AppThemeOption.dark.isDark == true)
        #expect(AppThemeOption.classic.isDark == false)
    }

    @Test func everyThemeHasTitleAndSwatch() {
        for option in AppThemeOption.allCases {
            #expect(!option.title.isEmpty)
            #expect(option.swatch.count == 3)
        }
    }

    @Test func managerReflectsConcreteSelection() {
        // Для конкретной темы палитра менеджера совпадает с палитрой темы.
        let manager = ThemeManager.shared
        let original = manager.selected
        manager.selected = .ocean
        #expect(manager.palette.accent == AppThemeOption.ocean.palette.accent)
        manager.selected = original   // возвращаем как было
    }
}
