import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var isShowingAddRecipe = false

    @Query private var recipes: [Recipe]

    var body: some View {
        NavigationStack {
            List {
                ForEach(recipes) { recipe in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.headline)

                        Text(recipe.recipeDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Рецепты")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddRecipe) {
                AddRecipeView()
            }
        }
    }
}
