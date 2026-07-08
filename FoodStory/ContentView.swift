import SwiftUI
import SwiftData

struct ContentView: View {
    // Системная светлая/тёмная схема — нужна для темы «как в системе».
    @Environment(\.colorScheme) private var systemScheme

    // Показывали ли уже экран приветствия (сохраняется между запусками).
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showingWelcome = false

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
        // Сообщаем менеджеру системную схему (для темы «как в системе»).
        .onChange(of: systemScheme) { _, newValue in
            ThemeManager.shared.systemColorScheme = newValue
        }
        .onAppear {
            ThemeManager.shared.systemColorScheme = systemScheme
            if !hasOnboarded { showingWelcome = true }
        }
        // Экран приветствия при самом первом запуске.
        .fullScreenCover(isPresented: $showingWelcome) {
            WelcomeView { showingWelcome = false }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Ingredient.self, Step.self, ShoppingItem.self], inMemory: true)
        .environment(TasteModel())
}
