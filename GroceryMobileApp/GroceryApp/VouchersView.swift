import SwiftUI

struct VoucherItem: Identifiable {
    let id = UUID()
    let code: String
    let description: String
    let discount: String
    let minOrder: String
    let validUntil: String
    let isActive: Bool
}

struct VouchersView: View {
    @State private var copiedCode: String?

    private let vouchers: [VoucherItem] = [
        VoucherItem(code: "FRESH10", description: "10% off your order", discount: "10%", minOrder: "Min. $15", validUntil: "May 31, 2026", isActive: true),
        VoucherItem(code: "SAVE5", description: "$5 off orders above $20", discount: "$5", minOrder: "Min. $20", validUntil: "Jun 15, 2026", isActive: true),
        VoucherItem(code: "NEWUSER", description: "$8 off first order", discount: "$8", minOrder: "No minimum", validUntil: "Dec 31, 2026", isActive: true),
        VoucherItem(code: "FREESHIP", description: "Free delivery on any order", discount: "Free Delivery", minOrder: "No minimum", validUntil: "May 15, 2026", isActive: true),
        VoucherItem(code: "SUMMER20", description: "20% off summer fruits", discount: "20%", minOrder: "Min. $25", validUntil: "Aug 31, 2026", isActive: true),
        VoucherItem(code: "WELCOME", description: "$3 off your next order", discount: "$3", minOrder: "Min. $10", validUntil: "Apr 1, 2026", isActive: false),
        VoucherItem(code: "HOLIDAY15", description: "15% off holiday specials", discount: "15%", minOrder: "Min. $30", validUntil: "Jan 5, 2026", isActive: false),
    ]

    private var activeVouchers: [VoucherItem] { vouchers.filter { $0.isActive } }
    private var expiredVouchers: [VoucherItem] { vouchers.filter { !$0.isActive } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !activeVouchers.isEmpty {
                    Text("Available")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                        .padding(.horizontal, 16)

                    ForEach(activeVouchers) { voucher in
                        NavigationLink {
                            VoucherDetailView(voucher: voucher)
                        } label: {
                            voucherCard(voucher, expired: false)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !expiredVouchers.isEmpty {
                    Text("Expired")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.muted)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ForEach(expiredVouchers) { voucher in
                        NavigationLink {
                            VoucherDetailView(voucher: voucher)
                        } label: {
                            voucherCard(voucher, expired: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(GroceryTheme.background)
        .navigationTitle("My Vouchers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func voucherCard(_ voucher: VoucherItem, expired: Bool) -> some View {
        HStack(spacing: 0) {
            // Left: discount badge
            VStack(spacing: 4) {
                Text(voucher.discount)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(expired ? GroceryTheme.muted : .white)
                Text("OFF")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(expired ? GroceryTheme.muted : .white.opacity(0.8))
            }
            .frame(width: 80)
            .frame(maxHeight: .infinity)
            .background(expired ? Color(.systemGray4) : GroceryTheme.primary)

            // Right: details
            VStack(alignment: .leading, spacing: 6) {
                Text(voucher.code)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(expired ? GroceryTheme.muted : GroceryTheme.title)

                Text(voucher.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.subtitle)

                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "cart")
                            .font(.system(size: 9))
                        Text(voucher.minOrder)
                            .font(.system(.caption2, design: .rounded))
                    }
                    .foregroundStyle(GroceryTheme.muted)

                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(voucher.validUntil)
                            .font(.system(.caption2, design: .rounded))
                    }
                    .foregroundStyle(expired ? GroceryTheme.badge : GroceryTheme.muted)
                }

                if !expired {
                    Button {
                        UIPasteboard.general.string = voucher.code
                        copiedCode = voucher.code
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if copiedCode == voucher.code { copiedCode = nil }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: copiedCode == voucher.code ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10))
                            Text(copiedCode == voucher.code ? "Copied!" : "Copy Code")
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(copiedCode == voucher.code ? GroceryTheme.primary : GroceryTheme.primaryLight)
                        .foregroundStyle(copiedCode == voucher.code ? .white : GroceryTheme.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Expired")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.badge)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 110)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .opacity(expired ? 0.6 : 1)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        VouchersView()
    }
}
