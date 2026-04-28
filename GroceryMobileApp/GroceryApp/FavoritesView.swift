import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favoritesStore

    private var favoriteProducts: [GroceryProduct] {
        favoritesStore.favorites(from: SampleData.allProducts)
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteProducts.isEmpty {
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
                            ForEach(favoriteProducts) { product in
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
