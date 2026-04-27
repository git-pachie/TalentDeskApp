import SwiftUI

struct ItemDetailView: View {
    let product: GroceryProduct
    @State private var quantity = 1
    @State private var isFavorite = false

    @State private var selectedImageIndex = 0

    private var productImages: [String] {
        switch product.category {
        case "Fruits":
            return [product.emoji, "🍎", "🍊", "🍇"]
        case "Veggie":
            return [product.emoji, "🥗", "🌿", "🧑‍🌾"]
        default:
            return [product.emoji, "📦", "🏷️", "✨"]
        }
    }

    private let relatedEmojis: [(String, String)] = [
        ("🥕", "Carrots"), ("🥦", "Broccoli"), ("🍅", "Tomatoes"),
        ("🥬", "Lettuce"), ("🌽", "Corn"), ("🫑", "Pepper")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero image
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(height: 260)
                        .overlay(
                            Text(productImages[selectedImageIndex])
                                .font(.system(size: 120))
                        )

                    Button {
                        withAnimation(.bouncy) { isFavorite.toggle() }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(isFavorite ? GroceryTheme.badge : GroceryTheme.muted)
                            .padding(10)
                            .background(GroceryTheme.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                    }
                    .padding(16)

                    if let discount = product.discount {
                        Text(discount)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(GroceryTheme.badge)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(16)
                    }
                }

                // Thumbnail gallery
                HStack(spacing: 10) {
                    ForEach(Array(productImages.enumerated()), id: \.offset) { index, emoji in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedImageIndex = index
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 60, height: 60)
                                Text(emoji)
                                    .font(.system(size: 30))
                            }
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

                // Name & Location
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

                // Price
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

                Divider()

                // Quantity selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quantity")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)

                    HStack(spacing: 16) {
                        Button {
                            if quantity > 1 { quantity -= 1 }
                        } label: {
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

                        Button {
                            quantity += 1
                        } label: {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 36, height: 36)
                                .background(GroceryTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                        }
                    }
                }

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this item")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)

                    Text("Fresh and organic \(product.name.lowercased()) sourced from local farms in \(product.location). Perfect for salads, cooking, or healthy snacking. Stored at optimal temperature to ensure freshness.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.subtitle)
                        .lineSpacing(4)
                }

                Divider()

                // Related images
                VStack(alignment: .leading, spacing: 12) {
                    Text("You might also like")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(relatedEmojis, id: \.1) { emoji, name in
                                VStack(spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemGray6))
                                            .frame(width: 80, height: 80)
                                        Text(emoji)
                                            .font(.system(size: 40))
                                    }
                                    Text(name)
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundStyle(GroceryTheme.subtitle)
                                }
                            }
                        }
                    }
                }

                // Add to cart button
                Button { } label: {
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
            .padding(16)
        }
        .background(GroceryTheme.background)
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(product: SampleData.deals.first!)
    }
}
