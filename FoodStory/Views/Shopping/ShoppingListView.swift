//
//  ShoppingListView.swift
//  FoodStory
//
//  Список покупок. Пункты можно добавлять вручную, отмечать купленными
//  (галочка + зачёркивание), удалять свайпом и очищать разом.
//  Открывается с главного экрана по кнопке «Список покупок».
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    // Из базы берём по времени добавления (Bool сортировать нельзя).
    @Query(sort: \ShoppingItem.createdAt) private var items: [ShoppingItem]

    @Environment(\.modelContext) private var context

    @State private var newItemName = ""

    // Некупленные — сверху, купленные — вниз (сортируем уже в памяти).
    private var sortedItems: [ShoppingItem] {
        items.sorted { !$0.isChecked && $1.isChecked }
    }

    // Сколько ещё осталось купить — для подзаголовка.
    private var remaining: Int { items.filter { !$0.isChecked }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    addRow

                    if items.isEmpty {
                        Spacer()
                        ContentUnavailableView(
                            "Список пуст",
                            systemImage: "cart",
                            description: Text("Добавьте продукты вручную или из рецепта.")
                        )
                        Spacer()
                    } else {
                        list
                    }
                }
            }
            .navigationTitle("Список покупок")
            .toolbar {
                if !items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                clearChecked()
                            } label: {
                                Label("Убрать купленное", systemImage: "checkmark.circle")
                            }
                            Button(role: .destructive) {
                                clearAll()
                            } label: {
                                Label("Очистить всё", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                if !items.isEmpty {
                    Text("Осталось купить: \(remaining)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Metric.padding)
                        .padding(.top, 4)
                }
            }
        }
        .tint(Theme.accent)
    }

    // Поле ввода нового продукта + кнопка добавления.
    private var addRow: some View {
        HStack {
            TextField("Добавить продукт", text: $newItemName)
                .padding(10)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
                .onSubmit(addItem)

            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
            .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(Metric.padding)
    }

    private var list: some View {
        List {
            ForEach(sortedItems) { item in
                Button {
                    toggle(item)
                } label: {
                    HStack {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isChecked ? Theme.green : Theme.textSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .foregroundStyle(Theme.textPrimary)
                                .strikethrough(item.isChecked)
                            if !item.detail.isEmpty {
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    .opacity(item.isChecked ? 0.5 : 1)
                }
                .buttonStyle(.plain)
                .listRowBackground(Theme.card)
            }
            .onDelete(perform: deleteItems)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Действия

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(ShoppingItem(name: trimmed))
        try? context.save()
        newItemName = ""
    }

    private func toggle(_ item: ShoppingItem) {
        item.isChecked.toggle()
        try? context.save()
    }

    private func deleteItems(_ offsets: IndexSet) {
        for index in offsets { context.delete(sortedItems[index]) }
        try? context.save()
    }

    private func clearChecked() {
        for item in items where item.isChecked { context.delete(item) }
        try? context.save()
    }

    private func clearAll() {
        for item in items { context.delete(item) }
        try? context.save()
    }
}

#Preview {
    ShoppingListView()
        .modelContainer(previewContainer)
}
