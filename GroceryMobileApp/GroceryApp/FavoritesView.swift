import SwiftUI

struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Favorites Yet",
                systemImage: "heart",
                description: Text("Items you love will appear here.")
            )
            .background(GroceryTheme.background)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    FavoritesView()
}
