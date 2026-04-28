import SwiftUI

struct CheckoutView: View {
    @Environment(CartStore.self) private var cartStore
    @State private var deliveryAddress = "Home, New York"
    @State private var paymentMethod = "Credit Card"
    @State private var showingConfirmation = false
    @State private var showingAddressPicker = false
    @State private var showingPaymentPicker = false

    private let addresses = ["Home, New York", "Office, Manhattan", "Mom's, Brooklyn", "Gym, Queens"]
    private let paymentMethods = [
        ("Credit Card", "creditcard.fill"),
        ("Debit Card", "creditcard"),
        ("Apple Pay", "apple.logo"),
        ("Cash on Delivery", "banknote.fill"),
    ]

    private let deliveryFee: Double = 5
    private var subtotal: Double { cartStore.totalPrice }
    private var total: Double { subtotal + deliveryFee }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Order summary
                orderSummary

                Divider()

                // Delivery address
                Button { showingAddressPicker = true } label: {
                    sectionCard(title: "Delivery Address", icon: "mappin.circle.fill") {
                        HStack {
                            Text(deliveryAddress)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(GroceryTheme.title)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(GroceryTheme.muted)
                        }
                    }
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingAddressPicker) {
                    NavigationView {
                        List(addresses, id: \.self) { address in
                            Button {
                                deliveryAddress = address
                                showingAddressPicker = false
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(GroceryTheme.primary)
                                    Text(address)
                                        .foregroundStyle(GroceryTheme.title)
                                    Spacer()
                                    if address == deliveryAddress {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(GroceryTheme.primary)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Delivery Address")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showingAddressPicker = false }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }

                // Payment method
                Button { showingPaymentPicker = true } label: {
                    sectionCard(title: "Payment Method", icon: "creditcard.fill") {
                        HStack {
                            Text(paymentMethod)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(GroceryTheme.title)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(GroceryTheme.muted)
                        }
                    }
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingPaymentPicker) {
                    NavigationView {
                        List(paymentMethods, id: \.0) { method in
                            Button {
                                paymentMethod = method.0
                                showingPaymentPicker = false
                            } label: {
                                HStack {
                                    Image(systemName: method.1)
                                        .foregroundStyle(GroceryTheme.primary)
                                        .frame(width: 24)
                                    Text(method.0)
                                        .foregroundStyle(GroceryTheme.title)
                                    Spacer()
                                    if method.0 == paymentMethod {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(GroceryTheme.primary)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Payment Method")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showingPaymentPicker = false }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }

                // Price breakdown
                priceBreakdown

                // Place order button
                Button {
                    showingConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "bag.fill")
                        Text("Place Order — $\(Int(total))")
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
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Order Placed!", isPresented: $showingConfirmation) {
            Button("OK") {
                cartStore.items.removeAll()
            }
        } message: {
            Text("Your order of \(cartStore.totalItems) item(s) totaling $\(Int(total)) has been placed successfully.")
        }
    }

    // MARK: - Order Summary

    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)

            ForEach(cartStore.items) { item in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(width: 44, height: 44)
                        .overlay {
                            if let urlString = item.product.imageURL, let url = URL(string: urlString) {
                                CachedAsyncImage(url: url, emoji: item.product.emoji)
                            } else {
                                Text(item.product.emoji).font(.title3)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.product.name)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(GroceryTheme.title)
                            .lineLimit(1)
                        Text("x\(item.quantity)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(GroceryTheme.muted)
                    }

                    Spacer()

                    Text("$\(Int(item.product.price) * item.quantity)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                }
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.primary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Price Breakdown

    private var priceBreakdown: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Subtotal")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(GroceryTheme.subtitle)
                Spacer()
                Text("$\(Int(subtotal))")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(GroceryTheme.title)
            }
            HStack {
                Text("Delivery Fee")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(GroceryTheme.subtitle)
                Spacer()
                Text("$\(Int(deliveryFee))")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(GroceryTheme.title)
            }
            Divider()
            HStack {
                Text("Total")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.title)
                Spacer()
                Text("$\(Int(total))")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.primary)
            }
        }
        .padding(14)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

#Preview {
    NavigationStack {
        CheckoutView()
    }
    .environment(CartStore())
}
