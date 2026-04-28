import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @State private var refreshID = UUID()

    var body: some View {
        NavigationStack {
            Group {
                let favorites = SampleData.allProducts.filter { favoritesStore.isFavorite($0) }

                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart icon on any product to add it here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 14) {
                            ForEach(favorites) { product in
                                NavigationLink {
                                    ItemDetailView(product: product)
                                } label: {
                                    ProductCard(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .id(refreshID)
                    }
                    .refreshable {
                        refreshID = UUID()
                    }
                }
            }
            .background(GroceryTheme.background)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    FavoritesView()
        .environment(FavoritesStore())
}
