import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        // TabView рисует вкладки внизу. Каждая вкладка — отдельный экран.
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }

            RecipeListView()
                .tabItem {
                    Label("Рецепты", systemImage: "book.fill")
                }

            SearchView()
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }

            FridgeView()
                .tabItem {
                    Label("Холодильник", systemImage: "refrigerator.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
        }
        .tint(Theme.accent)
        // Светлая/тёмная схема зависит от выбранной темы. Чтение здесь
        // подписывает вид на ThemeManager — при смене темы всё обновится.
        .preferredColorScheme(ThemeManager.shared.colorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Ingredient.self, Step.self, ShoppingItem.self], inMemory: true)
        .environment(TasteModel())
}
