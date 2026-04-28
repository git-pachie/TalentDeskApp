import SwiftUI

struct CartView: View {
    @Environment(CartStore.self) private var cartStore

    var body: some View {
        NavigationStack {
            Group {
                if cartStore.items.isEmpty {
                    ContentUnavailableView(
                        "Cart is Empty",
                        systemImage: "cart",
                        description: Text("Tap the cart icon on any product to add it here.")
                    )
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(cartStore.items) { item in
                                    cartRow(item: item)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        // Checkout bar
                        VStack(spacing: 12) {
                            Divider()
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(GroceryTheme.muted)
                                    Text("$\(Int(cartStore.totalPrice))")
                                        .font(.system(.title2, design: .rounded, weight: .bold))
                                        .foregroundStyle(GroceryTheme.primary)
                                }
                                Spacer()
                                NavigationLink {
                                    CheckoutView()
                                } label: {
                                    Text("Checkout (\(cartStore.totalItems))")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 14)
                                        .background(GroceryTheme.primary)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                        .background(GroceryTheme.card)
                    }
                }
            }
            .background(GroceryTheme.background)
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func cartRow(item: CartItem) -> some View {
        HStack(spacing: 12) {
            // Product image
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.systemGray6))
                .frame(width: 70, height: 70)
                .overlay {
                    if let urlString = item.product.imageURL, let url = URL(string: urlString) {
                        CachedAsyncImage(url: url, emoji: item.product.emoji)
                    } else {
                        Text(item.product.emoji)
                            .font(.system(size: 36))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(GroceryTheme.title)
                    .lineLimit(1)
                Text("$\(Int(item.product.price)) each")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
            }

            Spacer()

            // Quantity controls
            HStack(spacing: 10) {
                Button {
                    cartStore.updateQuantity(for: item.product, quantity: item.quantity - 1)
                } label: {
                    Image(systemName: item.quantity == 1 ? "trash" : "minus")
                        .font(.caption2.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .background(item.quantity == 1 ? GroceryTheme.badge.opacity(0.12) : GroceryTheme.primaryLight)
                        .foregroundStyle(item.quantity == 1 ? GroceryTheme.badge : GroceryTheme.primary)
                        .clipShape(Circle())
                }

                Text("\(item.quantity)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.title)
                    .frame(width: 24)

                Button {
                    cartStore.updateQuantity(for: item.product, quantity: item.quantity + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .background(GroceryTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

#Preview {
    CartView()
        .environment(CartStore())
}
