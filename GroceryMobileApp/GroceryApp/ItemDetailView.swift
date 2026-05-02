import SwiftUI

struct ItemDetailView: View {
    let product: GroceryProduct
    @State private var quantity = 1
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(CartStore.self) private var cartStore
    @Environment(ProductStore.self) private var productStore
    @State private var selectedImageIndex = 0
    @State private var showingImageViewer = false
    @State private var productDetail: ProductDTO?

    private var galleryImages: [ProductImageDTO] {
        if let detail = productDetail, !detail.images.isEmpty {
            return detail.images.sorted(by: { $0.sortOrder < $1.sortOrder })
        }
        return []
    }

    private var thumbnailURLs: [String] {
        if !galleryImages.isEmpty {
            return galleryImages.map(\.displayUrl)
        }
        if let main = product.imageURL { return [main] }
        return []
    }

    private var selectedGalleryImage: ProductImageDTO? {
        guard galleryImages.indices.contains(selectedImageIndex) else { return nil }
        return galleryImages[selectedImageIndex]
    }

    @State private var relatedProducts: [GroceryProduct] = []

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
        .fullScreenCover(isPresented: $showingImageViewer) {
            productImageViewer
        }
        .task {
            productDetail = await productStore.productDetail(product.id)
            await loadRelatedProducts()
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Button {
            showingImageViewer = true
        } label: {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray6))
                .frame(height: 260)
                .overlay {
                    if !thumbnailURLs.isEmpty, let url = URL(string: thumbnailURLs[selectedImageIndex]) {
                        CachedAsyncImage(url: url, emoji: product.emoji, lastModified: selectedGalleryImage?.dateModified ?? product.imageDateModified)
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
        .buttonStyle(.plain)
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
                                let imageModified = galleryImages.indices.contains(index) ? galleryImages[index].dateModified : product.imageDateModified
                                CachedAsyncImage(url: url, emoji: product.emoji, lastModified: imageModified)
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
            Text(CurrencyFormatter.peso(Int(product.price)))
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(GroceryTheme.primary)
            if let original = product.originalPrice {
                Text(CurrencyFormatter.peso(Int(original)))
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

            // Show additional categories if product belongs to multiple
            if let extras = productDetail?.additionalCategoryNames, !extras.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(GroceryTheme.primary)
                    ForEach(extras, id: \.self) { cat in
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
        Group {
            if !relatedProducts.isEmpty {
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
                                        Text(CurrencyFormatter.peso(Int(item.price)))
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
        }
    }

    // MARK: - Add to Cart

    private var addToCartButton: some View {
        Button {
            cartStore.add(product, quantity: quantity)
        } label: {
            HStack {
                Image(systemName: "cart.badge.plus")
                Text("Add to Cart — \(CurrencyFormatter.peso(quantity * Int(product.price)))")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(GroceryTheme.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    // MARK: - Load Related Products

    private func loadRelatedProducts() async {
        // Fetch products from the same category, sorted by rating (highest first)
        do {
            let categoryId = productDetail?.categoryId ?? product.id
            let result: PagedResult<ProductDTO> = try await APIClient.shared.get(
                "/api/products",
                query: [
                    URLQueryItem(name: "categoryId", value: categoryId.uuidString),
                    URLQueryItem(name: "pageSize", value: "15"),
                    URLQueryItem(name: "sortBy", value: "newest"),
                ]
            )

            // Filter out the current product, take top 10
            let related = result.items
                .filter { $0.id != product.id && $0.isActive }
                .sorted { $0.averageRating > $1.averageRating }
                .prefix(10)
                .map(\.asGroceryProduct)

            relatedProducts = Array(related)
        } catch {
            print("⚠️ Failed to load related products: \(error)")
        }
    }
}

private extension ItemDetailView {
    var productImageViewer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(thumbnailURLs.enumerated()), id: \.offset) { index, urlString in
                        GeometryReader { proxy in
                            ZStack {
                                Color.black

                                if let url = URL(string: urlString) {
                                    let imageModified = galleryImages.indices.contains(index) ? galleryImages[index].dateModified : product.imageDateModified
                                    CachedAsyncImage(url: url, emoji: product.emoji, lastModified: imageModified, displayMode: .fit)
                                        .frame(
                                            maxWidth: proxy.size.width,
                                            maxHeight: proxy.size.height,
                                            alignment: .center
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 24)
                                } else {
                                    Text(product.emoji)
                                        .font(.system(size: 120))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if thumbnailURLs.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(thumbnailURLs.enumerated()), id: \.offset) { index, urlString in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedImageIndex = index
                                    }
                                } label: {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 64, height: 64)
                                        .overlay {
                                            if let url = URL(string: urlString) {
                                                let imageModified = galleryImages.indices.contains(index) ? galleryImages[index].dateModified : product.imageDateModified
                                                CachedAsyncImage(url: url, emoji: product.emoji, lastModified: imageModified)
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(selectedImageIndex == index ? Color.white : Color.white.opacity(0.18), lineWidth: selectedImageIndex == index ? 2 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color.black.opacity(0.9))
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        showingImageViewer = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(product: SampleData.deals.first!)
    }
    .groceryPreviewEnvironment()
}
