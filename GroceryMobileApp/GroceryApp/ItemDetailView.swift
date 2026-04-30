import SwiftUI

struct ItemDetailView: View {
    let product: GroceryProduct
    @State private var quantity = 1
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(CartStore.self) private var cartStore
    @Environment(ProductStore.self) private var productStore
    @State private var selectedImageIndex = 0
    @State private var productDetail: ProductDTO?

    private var thumbnailURLs: [String] {
        // Use API images if loaded, otherwise fall back to the product's single image
        if let detail = productDetail, !detail.imageGalleryURLs.isEmpty {
            return detail.imageGalleryURLs
        }
        if let main = product.imageURL { return [main] }
        return []
    }

    private var relatedProducts: [GroceryProduct] {
        SampleData.allProducts.filter { $0.id != product.id && $0.category == product.category }.prefix(5).map { $0 }
        + SampleData.allProducts.filter { $0.id != product.id && $0.category != product.category }.prefix(2).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero image
                heroImage

                // Thumbnails
                thumbnailRow

                // Info
                productInfo

                // Price
                priceSection

                Divider()
                quantitySelector
                Divider()
                aboutSection
                Divider()
                relatedSection
                addToCartButton
            }
            .padding(16)
        }
        .background(GroceryTheme.background)
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            productDetail = await productStore.productDetail(product.id)
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.systemGray6))
            .frame(height: 260)
            .overlay {
                if let url = URL(string: thumbnailURLs[selectedImageIndex]) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button {
                    withAnimation(.bouncy) { favoritesStore.toggle(product) }
                } label: {
                    Image(systemName: favoritesStore.isFavorite(product) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(favoritesStore.isFavorite(product) ? GroceryTheme.badge : GroceryTheme.muted)
                        .padding(10)
                        .background(GroceryTheme.card)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                }
                .padding(16)
            }
            .overlay(alignment: .topLeading) {
                if let discount = product.discount {
                    Text(discount)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(GroceryTheme.badge)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(16)
                }
            }
    }

    // MARK: - Thumbnail Row

    private var thumbnailRow: some View {
        HStack(spacing: 10) {
            ForEach(Array(thumbnailURLs.enumerated()), id: \.offset) { index, urlString in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedImageIndex = index
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 60)
                        .overlay {
                            if let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView().scaleEffect(0.5)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    selectedImageIndex == index ? GroceryTheme.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - Product Info

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(GroceryTheme.title)
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(GroceryTheme.primary)
                Text(product.location)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
            }
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(GroceryTheme.primary)
                Text(product.category)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(GroceryTheme.subtitle)
            }
        }
    }

    // MARK: - Price

    private var priceSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("$\(Int(product.price))")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(GroceryTheme.primary)
            if let original = product.originalPrice {
                Text("$\(Int(original))")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
                    .strikethrough()
            }
        }
    }

    // MARK: - Quantity

    private var quantitySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quantity")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)
            HStack(spacing: 16) {
                Button { if quantity > 1 { quantity -= 1 } } label: {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(GroceryTheme.primaryLight)
                        .foregroundStyle(GroceryTheme.primary)
                        .clipShape(Circle())
                }
                Text("\(quantity)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.title)
                    .frame(width: 40)
                Button { quantity += 1 } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(GroceryTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this item")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)
            Text(productDetail?.description ?? "Fresh and organic \(product.name.lowercased()) sourced from local farms in \(product.location). Perfect for salads, cooking, or healthy snacking. Stored at optimal temperature to ensure freshness.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(GroceryTheme.subtitle)
                .lineSpacing(4)

            // Show all categories if product belongs to multiple
            if let categories = productDetail?.allCategoryNames, categories.count > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(GroceryTheme.primary)
                    ForEach(categories, id: \.self) { cat in
                        Text(cat)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(GroceryTheme.primaryLight)
                            .foregroundStyle(GroceryTheme.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Related

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You might also like")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relatedProducts) { item in
                        NavigationLink {
                            ItemDetailView(product: item)
                        } label: {
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        if let urlString = item.imageURL, let url = URL(string: urlString) {
                                            CachedAsyncImage(url: url, emoji: item.emoji)
                                        } else {
                                            Text(item.emoji)
                                                .font(.system(size: 40))
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(item.name)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(GroceryTheme.subtitle)
                                    .lineLimit(1)
                                Text("$\(Int(item.price))")
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                                    .foregroundStyle(GroceryTheme.primary)
                            }
                            .frame(width: 80)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Add to Cart

    private var addToCartButton: some View {
        Button {
            cartStore.add(product, quantity: quantity)
        } label: {
            HStack {
                Image(systemName: "cart.badge.plus")
                Text("Add to Cart — $\(quantity * Int(product.price))")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(GroceryTheme.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(product: SampleData.deals.first!)
    }
    .groceryPreviewEnvironment()
}
