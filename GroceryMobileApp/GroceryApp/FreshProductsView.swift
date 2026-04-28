import SwiftUI

struct FreshProductsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Filter chips
                HStack(spacing: 10) {
                    filterChip(label: "Price")
                    filterChip(label: "Brand")
                    filterChip(label: "Popularity")
                }

                // Product grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 14) {
                    ForEach(SampleData.freshProducts) { product in
                        NavigationLink {
                            ItemDetailView(product: product)
                        } label: {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(GroceryTheme.background)
        .navigationTitle("Fresh Products")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(GroceryTheme.title)
                }
            }
        }
    }

    private func filterChip(label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(GroceryTheme.card)
        .foregroundStyle(GroceryTheme.title)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(GroceryTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: GroceryProduct
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Image container
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
                .frame(height: 140)
                .overlay {
                    if let urlString = product.imageURL, let url = URL(string: urlString) {
                        CachedAsyncImage(url: url, emoji: product.emoji)
                    } else {
                        Text(product.emoji)
                            .font(.system(size: 72))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if let discount = product.discount {
                        Text(discount)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(GroceryTheme.badge)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .padding(8)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        withAnimation(.bouncy) { favoritesStore.toggle(product) }
                    } label: {
                        Image(systemName: favoritesStore.isFavorite(product) ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(favoritesStore.isFavorite(product) ? GroceryTheme.badge : GroceryTheme.muted)
                            .padding(7)
                            .background(GroceryTheme.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }

            Text(product.name)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)
                .lineLimit(1)

            Text(product.location)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(GroceryTheme.muted)
                .lineLimit(1)

            HStack {
                Text("$\(Int(product.price))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.primary)

                if let original = product.originalPrice {
                    Text("$\(Int(original))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                        .strikethrough()
                }

                Spacer()

                Button { } label: {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 13, weight: .medium))
                        .padding(7)
                        .background(GroceryTheme.primaryLight)
                        .foregroundStyle(GroceryTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
        }
        .padding(10)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

#Preview {
    NavigationStack {
        FreshProductsView()
    }
    .environment(FavoritesStore())
}
