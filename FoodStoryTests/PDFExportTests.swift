//
//  PDFExportTests.swift
//  FoodStoryTests
//
//  Проверяем генерацию PDF-книги рецептов: для пустого списка возвращается nil,
//  а для реальных рецептов получается настоящий PDF-файл на диске.
//

import Testing
import Foundation
@testable import FoodStory

struct PDFExportTests {

    @Test func emptyRecipesReturnsNil() {
        #expect(RecipeBookPDF.makeURL(recipes: [], author: "Галина") == nil)
    }

    @Test @MainActor func producesRealPDFFile() throws {
        let recipes = SampleData.recipes()
        let url = try #require(RecipeBookPDF.makeURL(recipes: recipes, author: "Галина"))

        // Файл существует и не пустой.
        let data = try Data(contentsOf: url)
        #expect(data.count > 1000)

        // Первые байты настоящего PDF — это "%PDF".
        let header = String(data: data.prefix(4), encoding: .ascii)
        #expect(header == "%PDF")
    }
}
