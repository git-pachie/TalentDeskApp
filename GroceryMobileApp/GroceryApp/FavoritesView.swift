import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(ProductStore.self) private var productStore
    @State private var refreshID = UUID()

    var body: some View {
        NavigationStack {
            Group {
                let allProducts = productStore.allProducts.isEmpty ? SampleData.allProducts : productStore.allProducts
                let favorites = favoritesStore.favoriteProducts.isEmpty
                    ? allProducts.filter { favoritesStore.isFavorite($0) }
                    : favoritesStore.favoriteProducts

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
        .groceryPreviewEnvironment()
}
