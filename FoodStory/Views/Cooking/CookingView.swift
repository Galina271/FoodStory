import SwiftUI

struct CookingView: View {

    let recipe: Recipe
    let session: CookingSession

    var body: some View {

        Text("Готовим \(recipe.title)")
            .navigationTitle("Приготовление")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CookingView(
            recipe: Recipe(
                title: "Карбонара",
                servings: 2,
                cookTimeMinutes: 25,
                difficulty: .easy
            ),
            session: CookingSession()
        )
    }
}
