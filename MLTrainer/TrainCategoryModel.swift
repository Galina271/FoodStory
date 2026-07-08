//
//  TrainCategoryModel.swift
//  FoodStory · инструмент разработчика (НЕ часть приложения)
//
//  Обучает Core ML модель, которая по тексту рецепта (название + ингредиенты)
//  угадывает категорию блюда. Это классификатор текста (MLTextClassifier).
//
//  Как запустить (на Mac, из папки проекта):
//      xcrun --sdk macosx swift MLTrainer/TrainCategoryModel.swift
//
//  Результат: FoodStory/ML/RecipeCategoryClassifier.mlmodel
//  Xcode сам скомпилирует .mlmodel при сборке приложения.
//
//  Чтобы улучшить модель — дописывай примеры в массив `samples` (чем больше и
//  разнообразнее данные, тем умнее модель) и запускай скрипт заново.
//

import CreateML
import Foundation

// Один пример обучения: текст рецепта → категория (rawValue из RecipeCategory).
struct Sample { let text: String; let label: String }

let samples: [Sample] = [
    // breakfast
    Sample(text: "омлет яйца молоко сыр", label: "breakfast"),
    Sample(text: "овсянка хлопья молоко ягоды мёд", label: "breakfast"),
    Sample(text: "блинчики мука молоко яйца", label: "breakfast"),
    Sample(text: "яичница глазунья яйца бекон", label: "breakfast"),
    Sample(text: "сырники творог мука сахар", label: "breakfast"),
    Sample(text: "тосты хлеб масло джем", label: "breakfast"),
    Sample(text: "гранола овсянка орехи мёд", label: "breakfast"),
    Sample(text: "манная каша молоко сахар", label: "breakfast"),

    // soup
    Sample(text: "борщ свёкла капуста мясо картофель", label: "soup"),
    Sample(text: "куриный суп курица лапша морковь", label: "soup"),
    Sample(text: "томатный суп помидоры базилик", label: "soup"),
    Sample(text: "грибной суп шампиньоны сливки", label: "soup"),
    Sample(text: "харчо говядина рис томат", label: "soup"),
    Sample(text: "солянка колбаса огурцы маслины", label: "soup"),
    Sample(text: "гороховый суп горох копчёности", label: "soup"),
    Sample(text: "крем суп тыква сливки", label: "soup"),

    // main
    Sample(text: "паста карбонара спагетти бекон яйца пармезан", label: "main"),
    Sample(text: "плов рис мясо морковь лук", label: "main"),
    Sample(text: "котлеты фарш лук хлеб", label: "main"),
    Sample(text: "жаркое картофель мясо лук", label: "main"),
    Sample(text: "стейк говядина соль перец", label: "main"),
    Sample(text: "ризотто рис бульон пармезан", label: "main"),
    Sample(text: "лазанья фарш соус бешамель сыр", label: "main"),
    Sample(text: "гуляш говядина лук паприка", label: "main"),

    // salad
    Sample(text: "салат цезарь курица сухарики пармезан", label: "salad"),
    Sample(text: "греческий салат помидоры огурцы фета оливки", label: "salad"),
    Sample(text: "оливье картофель колбаса горошек майонез", label: "salad"),
    Sample(text: "винегрет свёкла морковь картофель", label: "salad"),
    Sample(text: "овощной салат огурцы помидоры зелень", label: "salad"),
    Sample(text: "салат с тунцом тунец яйца листья", label: "salad"),
    Sample(text: "капустный салат капуста морковь", label: "salad"),
    Sample(text: "фруктовый салат яблоко банан апельсин", label: "salad"),

    // dessert
    Sample(text: "шоколадный фондан шоколад масло яйца", label: "dessert"),
    Sample(text: "тирамису маскарпоне кофе савоярди", label: "dessert"),
    Sample(text: "чизкейк творожный сыр печенье", label: "dessert"),
    Sample(text: "брауни шоколад какао масло", label: "dessert"),
    Sample(text: "мороженое сливки сахар ваниль", label: "dessert"),
    Sample(text: "панна котта сливки желатин ваниль", label: "dessert"),
    Sample(text: "крем брюле сливки желтки сахар", label: "dessert"),
    Sample(text: "шоколадный торт коржи крем шоколад", label: "dessert"),

    // baking
    Sample(text: "домашний хлеб мука дрожжи вода", label: "baking"),
    Sample(text: "булочки мука дрожжи молоко масло", label: "baking"),
    Sample(text: "пирог с яблоками тесто яблоки корица", label: "baking"),
    Sample(text: "круассаны слоёное тесто масло", label: "baking"),
    Sample(text: "кекс мука яйца сахар разрыхлитель", label: "baking"),
    Sample(text: "печенье мука масло сахар", label: "baking"),
    Sample(text: "фокачча мука оливковое масло розмарин", label: "baking"),
    Sample(text: "пицца тесто томатный соус сыр", label: "baking"),

    // drink
    Sample(text: "смузи банан ягоды йогурт", label: "drink"),
    Sample(text: "лимонад лимон вода сахар мята", label: "drink"),
    Sample(text: "горячий шоколад какао молоко", label: "drink"),
    Sample(text: "компот из ягод ягоды сахар вода", label: "drink"),
    Sample(text: "глинтвейн вино специи апельсин", label: "drink"),
    Sample(text: "молочный коктейль молоко мороженое", label: "drink"),
    Sample(text: "морс клюква вода сахар", label: "drink"),
    Sample(text: "латте кофе молоко", label: "drink"),

    // other
    Sample(text: "томатный соус помидоры чеснок базилик", label: "other"),
    Sample(text: "маринад для мяса соевый соус чеснок", label: "other"),
    Sample(text: "песто базилик орехи оливковое масло пармезан", label: "other"),
    Sample(text: "хумус нут тахини лимон чеснок", label: "other"),
    Sample(text: "гарнир рис масло соль", label: "other"),
    Sample(text: "паштет печень масло лук", label: "other"),
    Sample(text: "дип сметана зелень чеснок", label: "other"),
    Sample(text: "заправка масло уксус горчица", label: "other"),
]

let table = try MLDataTable(dictionary: [
    "text": samples.map { $0.text },
    "label": samples.map { $0.label }
])

print("Обучаю на \(samples.count) примерах…")
let model = try MLTextClassifier(trainingData: table, textColumn: "text", labelColumn: "label")

// Метаданные — полезно для App Store и порядка.
let metadata = MLModelMetadata(
    author: "FoodStory",
    shortDescription: "Определяет категорию блюда по названию и ингредиентам.",
    version: "1.0"
)

let outURL = URL(fileURLWithPath: "FoodStory/ML/RecipeCategoryClassifier.mlmodel")
try model.write(to: outURL, metadata: metadata)
print("Готово: \(outURL.path)")
