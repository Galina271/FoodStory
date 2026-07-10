//
//  KeyboardToolbar.swift
//  FoodStory
//
//  Добавляет над клавиатурой панель с кнопкой «Готово» — понятный и
//  предсказуемый способ закрыть клавиатуру именно тогда, когда захочет
//  пользователь (клавиатура НЕ закрывается сама при переходе между полями).
//
//  Применяется одной строкой: `.keyboardDoneButton()` на экране с полями ввода.
//  В паре с ним удобно ставить `.scrollDismissesKeyboard(.interactively)` —
//  тогда клавиатуру можно ещё и «смахнуть» вниз, потянув список.
//

import SwiftUI

extension View {
    /// Панель с кнопкой «Готово» над клавиатурой.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    // Просим активное поле «отпустить» клавиатуру.
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
                .fontWeight(.semibold)
            }
        }
    }
}
