import SwiftUI

struct VoucherDetailView: View {
    let voucher: VoucherItem
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero card
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(voucher.isActive ? GroceryTheme.primary.opacity(0.15) : Color(.systemGray5))
                            .frame(width: 90, height: 90)
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(voucher.isActive ? GroceryTheme.primary : GroceryTheme.muted)
                    }

                    Text(voucher.discount)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(voucher.isActive ? GroceryTheme.primary : GroceryTheme.muted)

                    Text(voucher.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(GroceryTheme.subtitle)
                        .multilineTextAlignment(.center)

                    // Code with copy
                    HStack(spacing: 10) {
                        Text(voucher.code)
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .foregroundStyle(GroceryTheme.title)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                    .foregroundStyle(GroceryTheme.primary.opacity(0.4))
                            )

                        if voucher.isActive {
                            Button {
                                UIPasteboard.general.string = voucher.code
                                withAnimation { copied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { copied = false }
                                }
                            } label: {
                                Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.title3)
                                    .foregroundStyle(copied ? GroceryTheme.primary : GroceryTheme.subtitle)
                            }
                        }
                    }

                    if !voucher.isActive {
                        Text("This voucher has expired")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.badge)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(GroceryTheme.badge.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(GroceryTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)

                // Details
                VStack(alignment: .leading, spacing: 14) {
                    Label("Voucher Details", systemImage: "info.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.primary)

                    detailRow(icon: "tag.fill", label: "Discount", value: voucher.discount)
                    detailRow(icon: "cart.fill", label: "Minimum Order", value: voucher.minOrder)
                    detailRow(icon: "calendar", label: "Valid Until", value: voucher.validUntil)
                    detailRow(icon: "checkmark.circle", label: "Status", value: voucher.isActive ? "Active" : "Expired")
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GroceryTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                // Terms
                VStack(alignment: .leading, spacing: 10) {
                    Label("Terms & Conditions", systemImage: "doc.text.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.primary)

                    VStack(alignment: .leading, spacing: 6) {
                        termRow("Valid for one-time use only")
                        termRow("Cannot be combined with other vouchers")
                        termRow("Applicable to all products unless stated otherwise")
                        termRow("Discount applied before delivery and platform fees")
                        termRow("GroceryApp reserves the right to modify or cancel this voucher")
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GroceryTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            .padding(16)
        }
        .background(GroceryTheme.background)
        .navigationTitle("Voucher Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(GroceryTheme.primary)
                .frame(width: 20)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(GroceryTheme.subtitle)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)
        }
    }

    private func termRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundStyle(GroceryTheme.muted)
                .padding(.top, 5)
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(GroceryTheme.subtitle)
        }
    }
}

#Preview {
    NavigationStack {
        VoucherDetailView(voucher: VoucherItem(code: "FRESH10", description: "10% off your order", discount: "10%", minOrder: "Min. $15", validUntil: "May 31, 2026", isActive: true))
    }
}
