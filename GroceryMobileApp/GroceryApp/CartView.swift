import SwiftUI

struct CartView: View {
    @Environment(CartStore.self) private var cartStore
    @State private var editingRemarkItem: CartItem?
    @State private var remarkText = ""
    @State private var navigationPath: [CartRoute] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                                NavigationLink(value: CartRoute.checkout) {
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
            .navigationDestination(for: CartRoute.self) { route in
                switch route {
                case .checkout:
                    CheckoutView { order in
                        navigationPath = [.order(order)]
                    }
                case .order(let order):
                    OrderDetailView(order: order, lockBackNavigation: true)
                }
            }
            .alert("Add Note", isPresented: Binding(
                get: { editingRemarkItem != nil },
                set: { if !$0 { editingRemarkItem = nil } }
            )) {
                TextField("e.g. ripe ones please", text: $remarkText)
                Button("OK") {
                    if let item = editingRemarkItem {
                        cartStore.updateRemarks(for: item.product, remarks: remarkText)
                    }
                    editingRemarkItem = nil
                }
                Button("Clear", role: .destructive) {
                    if let item = editingRemarkItem {
                        cartStore.updateRemarks(for: item.product, remarks: "")
                    }
                    editingRemarkItem = nil
                }
                Button("Cancel", role: .cancel) {
                    editingRemarkItem = nil
                }
            } message: {
                Text("Add a note for \(editingRemarkItem?.product.name ?? "this item")")
            }
        }
    }

    private func cartRow(item: CartItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                        .lineLimit(1)

                    Text("$\(Int(item.product.price)) each")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)

                    // Add/Edit remark button
                    Button {
                        remarkText = item.remarks
                        editingRemarkItem = item
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 10))
                            Text(item.remarks.isEmpty ? "Add note" : "Edit note")
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(GroceryTheme.primaryLight)
                        .foregroundStyle(GroceryTheme.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
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

            // Display remark label if set
            if !item.remarks.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble.fill")
                        .font(.caption2)
                        .foregroundStyle(GroceryTheme.primary)
                    Text(item.remarks)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.subtitle)
                        .lineLimit(2)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

private enum CartRoute: Hashable {
    case checkout
    case order(OrderItem)
}

#Preview {
    CartView()
        .groceryPreviewEnvironment()
}
