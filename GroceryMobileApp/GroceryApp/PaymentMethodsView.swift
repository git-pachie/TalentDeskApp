import SwiftUI

struct PaymentItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let icon: String
    var isDefault: Bool
}

struct PaymentMethodsView: View {
    @State private var methods: [PaymentItem] = [
        PaymentItem(name: "Credit Card", detail: "•••• •••• •••• 4242", icon: "creditcard.fill", isDefault: true),
        PaymentItem(name: "Debit Card", detail: "•••• •••• •••• 8910", icon: "creditcard", isDefault: false),
        PaymentItem(name: "Apple Pay", detail: "Connected", icon: "apple.logo", isDefault: false),
        PaymentItem(name: "Cash on Delivery", detail: "Pay when delivered", icon: "banknote.fill", isDefault: false),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(methods) { method in
                    HStack(spacing: 12) {
                        Image(systemName: method.icon)
                            .font(.title3)
                            .foregroundStyle(GroceryTheme.primary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(method.name)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(GroceryTheme.title)
                                if method.isDefault {
                                    Text("Default")
                                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(GroceryTheme.primary.opacity(0.12))
                                        .foregroundStyle(GroceryTheme.primary)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(method.detail)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(GroceryTheme.muted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(GroceryTheme.muted)
                    }
                    .padding(14)
                    .background(GroceryTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(GroceryTheme.background)
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PaymentMethodsView()
    }
}
