import SwiftUI

struct AddressItem: Identifiable {
    let id = UUID()
    var label: String
    var address: String
    var isDefault: Bool
}

struct AddressListView: View {
    @State private var addresses: [AddressItem] = [
        AddressItem(label: "Home", address: "123 Main St, New York, NY 10001", isDefault: true),
        AddressItem(label: "Office", address: "456 Park Ave, Manhattan, NY 10022", isDefault: false),
        AddressItem(label: "Mom's", address: "789 Oak Dr, Brooklyn, NY 11201", isDefault: false),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(addresses) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(GroceryTheme.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.label)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(GroceryTheme.title)
                                if item.isDefault {
                                    Text("Default")
                                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(GroceryTheme.primary.opacity(0.12))
                                        .foregroundStyle(GroceryTheme.primary)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(item.address)
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
        .navigationTitle("Addresses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AddressListView()
    }
}
