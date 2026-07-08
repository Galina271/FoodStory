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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Ingredient.self, Step.self, ShoppingItem.self], inMemory: true)
}
