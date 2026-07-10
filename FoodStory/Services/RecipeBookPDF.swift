//
//  RecipeBookPDF.swift
//  FoodStory
//
//  Собирает из всех рецептов один PDF-файл — «книгу рецептов»: обложку и по
//  странице (или больше) на каждый рецепт с фото, ингредиентами и шагами.
//  Файл сохраняется во временную папку, а вернувшийся URL можно отдать в
//  «Поделиться» — сохранить в Файлы, отправить, распечатать.
//
//  Рисуем «руками» через UIGraphicsPDFRenderer — это стандартный способ Apple
//  создавать PDF на iOS. Помощник PDFDrawer прячет всю возню с координатами и
//  переносом на новую страницу, чтобы код книги читался просто сверху вниз.
//

import UIKit
import SwiftUI

enum RecipeBookPDF {

    /// Создаёт PDF и возвращает ссылку на файл. Если рецептов нет — вернёт nil.
    static func makeURL(recipes: [Recipe], author: String) -> URL? {
        guard !recipes.isEmpty else { return nil }

        // A4 в точках (1 точка = 1/72 дюйма).
        let pageSize = CGSize(width: 595.2, height: 841.8)
        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Книга рецептов.pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                let drawer = PDFDrawer(context: ctx, pageSize: pageSize, margin: 48)

                drawer.drawCover(title: "Книга рецептов",
                                 subtitle: "\(recipes.count) \(recipesWord(recipes.count)) · \(author)")

                for recipe in recipes {
                    drawer.drawRecipe(recipe)
                }
            }
            return url
        } catch {
            return nil
        }
    }

    /// Правильное слово: 1 рецепт, 2 рецепта, 5 рецептов.
    private static func recipesWord(_ n: Int) -> String {
        let mod100 = n % 100, mod10 = n % 10
        if mod100 >= 11 && mod100 <= 14 { return "рецептов" }
        switch mod10 {
        case 1: return "рецепт"
        case 2, 3, 4: return "рецепта"
        default: return "рецептов"
        }
    }
}

// MARK: - Помощник рисования

/// Держит текущую страницу и вертикальную позицию `y`, умеет переносить контент
/// на новую страницу, когда место заканчивается. Благодаря ему код «книги»
/// не думает о координатах — просто «нарисуй заголовок, потом список, потом шаги».
private final class PDFDrawer {
    let ctx: UIGraphicsPDFRendererContext
    let pageSize: CGSize
    let margin: CGFloat
    var y: CGFloat = 0

    private var contentWidth: CGFloat { pageSize.width - margin * 2 }
    private var maxY: CGFloat { pageSize.height - margin }

    // Цвета книги фиксированные (тёмное на белом), не зависят от темы приложения —
    // страница PDF всегда белая, поэтому текст должен быть тёмным при любой теме.
    private let ink = UIColor(red: 0.23, green: 0.18, blue: 0.15, alpha: 1)
    private let inkSoft = UIColor(red: 0.55, green: 0.51, blue: 0.47, alpha: 1)
    private let accent = UIColor(red: 0.92, green: 0.54, blue: 0.24, alpha: 1)

    init(context: UIGraphicsPDFRendererContext, pageSize: CGSize, margin: CGFloat) {
        self.ctx = context
        self.pageSize = pageSize
        self.margin = margin
    }

    // Начинает новую страницу и ставит курсор в левый верхний угол поля.
    private func startPage() {
        ctx.beginPage()
        y = margin
    }

    // Если запрошенной высоты не хватает до низа — переносим на новую страницу.
    private func ensure(_ height: CGFloat) {
        if y + height > maxY { startPage() }
    }

    // MARK: Обложка

    func drawCover(title: String, subtitle: String) {
        startPage()

        // Цветная шапка во всю ширину страницы.
        let bandHeight: CGFloat = 320
        accent.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageSize.width, height: bandHeight)).fill()

        // Эмблема: полупрозрачный круг + белые вилка/нож по центру шапки.
        let emblem: CGFloat = 128
        let emblemRect = CGRect(x: (pageSize.width - emblem) / 2, y: 80, width: emblem, height: emblem)
        UIColor.white.withAlphaComponent(0.20).setFill()
        UIBezierPath(ovalIn: emblemRect).fill()
        if let symbol = UIImage(systemName: "fork.knife")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 60, weight: .semibold))
            .withTintColor(.white, renderingMode: .alwaysOriginal) {
            let s = symbol.size
            symbol.draw(in: CGRect(x: emblemRect.midX - s.width / 2,
                                   y: emblemRect.midY - s.height / 2,
                                   width: s.width, height: s.height))
        }

        // Название бренда под эмблемой.
        drawCenteredString("FoodStory", font: .systemFont(ofSize: 24, weight: .bold),
                           color: .white, atY: emblemRect.maxY + 18)

        // Заголовок и подзаголовок книги — по центру под шапкой.
        y = bandHeight + 90
        drawCentered(title, font: .systemFont(ofSize: 40, weight: .bold), color: ink, spacingAfter: 14)
        drawCentered(subtitle, font: .systemFont(ofSize: 17, weight: .regular), color: inkSoft, spacingAfter: 0)

        // Дата внизу страницы.
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ru_RU")
        drawCenteredString(formatter.string(from: Date()),
                           font: .systemFont(ofSize: 12, weight: .regular),
                           color: inkSoft, atY: pageSize.height - margin - 16)
    }

    // MARK: Один рецепт

    func drawRecipe(_ recipe: Recipe) {
        startPage()   // каждый рецепт — с новой страницы

        drawText(recipe.title, font: .systemFont(ofSize: 24, weight: .bold), color: ink, spacingAfter: 4)

        let meta = "\(recipe.category.title) · \(recipe.cookingTimeText) · \(recipe.servings) порц. · \(recipe.difficulty.title)"
        drawText(meta, font: .systemFont(ofSize: 12, weight: .regular), color: accent, spacingAfter: 12)

        drawPhoto(recipe)

        if !recipe.summary.isEmpty {
            drawText(recipe.summary, font: .italicSystemFont(ofSize: 13), color: inkSoft, spacingAfter: 14)
        }

        drawText("Ингредиенты", font: .systemFont(ofSize: 16, weight: .semibold), color: ink, spacingAfter: 6)
        for ingredient in recipe.ingredients {
            let line = "•  \(ingredient.name) — \(ingredient.displayAmount)"
            drawText(line, font: .systemFont(ofSize: 13), color: ink, spacingAfter: 3)
        }

        space(12)
        drawText("Приготовление", font: .systemFont(ofSize: 16, weight: .semibold), color: ink, spacingAfter: 6)
        for step in recipe.sortedSteps {
            let line = "\(step.order).  \(step.text)"
            drawText(line, font: .systemFont(ofSize: 13), color: ink, spacingAfter: 6)
        }
    }

    // MARK: Кирпичики

    // Рисует текст с переносом по словам, при нехватке места — новая страница.
    // Возвращать высоту не нужно: курсор y двигаем внутри.
    @discardableResult
    private func drawText(_ string: String, font: UIFont, color: UIColor, spacingAfter: CGFloat = 6) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let box = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        let height = ceil(attributed.boundingRect(with: box,
                                                  options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                  context: nil).height)
        ensure(height)
        attributed.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: height),
                        options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        y += height + spacingAfter
        return height
    }

    private func space(_ height: CGFloat) { y += height }

    // Рисует текст по центру страницы от текущего `y` и сдвигает курсор вниз.
    private func drawCentered(_ string: String, font: UIFont, color: UIColor, spacingAfter: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let box = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        let height = ceil(attributed.boundingRect(with: box,
                                                  options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                  context: nil).height)
        attributed.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: height),
                        options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        y += height + spacingAfter
    }

    // Рисует одну строку по центру страницы на заданной высоте (курсор не трогает).
    private func drawCenteredString(_ string: String, font: UIFont, color: UIColor, atY: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (string as NSString).size(withAttributes: attributes)
        (string as NSString).draw(at: CGPoint(x: (pageSize.width - size.width) / 2, y: atY),
                                  withAttributes: attributes)
    }

    // Рисует фото рецепта или цветную заглушку категории.
    private func drawPhoto(_ recipe: Recipe) {
        let height: CGFloat = 200
        ensure(height + 12)
        let rect = CGRect(x: margin, y: y, width: contentWidth, height: height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 14)

        if let data = recipe.imageData, let image = UIImage(data: data) {
            ctx.cgContext.saveGState()
            path.addClip()   // скругляем углы фото
            image.draw(in: aspectFillRect(image: image, in: rect))
            ctx.cgContext.restoreGState()
        } else {
            UIColor(recipe.category.gradient.first ?? .orange).setFill()
            path.fill()
            let title = recipe.category.title
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let size = (title as NSString).size(withAttributes: attrs)
            (title as NSString).draw(
                at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2),
                withAttributes: attrs
            )
        }
        y += height + 14
    }

    // Прямоугольник, в который фото впишется «по заполнению» (без искажений).
    private func aspectFillRect(image: UIImage, in rect: CGRect) -> CGRect {
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let w = image.size.width * scale
        let h = image.size.height * scale
        return CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
    }
}
