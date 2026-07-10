//
//  KeyboardDismissUITests.swift
//  FoodStoryUITests
//
//  Проверяет, что клавиатура закрывается при тапе по свободной области.
//  Открываем форму нового рецепта, ставим курсор в поле «Название», убеждаемся,
//  что клавиатура появилась, затем тапаем по заголовку экрана (свободная зона)
//  и проверяем, что клавиатура ушла.
//

import XCTest

final class KeyboardDismissUITests: XCTestCase {

    @MainActor
    func testTapOnEmptyAreaDismissesKeyboard() throws {
        let app = XCUIApplication()
        app.launch()

        // Переходим на вкладку «Рецепты».
        app.tabBars.buttons["Рецепты"].tap()

        // Открываем «+» (кнопка добавления в правом верхнем углу).
        let addButton = app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1)
        addButton.tap()

        // Ставим курсор в поле названия — появляется клавиатура.
        let titleField = app.textFields["Название блюда"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Поле названия не найдено")
        titleField.tap()

        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5),
                      "Клавиатура должна была появиться")

        // Тапаем по свободной области — заголовку экрана «Новый рецепт».
        app.navigationBars.staticTexts["Новый рецепт"].tap()

        // Клавиатура должна исчезнуть.
        let keyboardGone = expectation(for: NSPredicate(format: "exists == false"),
                                       evaluatedWith: app.keyboards.element)
        wait(for: [keyboardGone], timeout: 5)
    }
}
