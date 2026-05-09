import SwiftUI

struct VoucherItem: Identifiable {
    let id: UUID
    let code: String
    let description: String
    let discount: String
    let minOrder: String
    let validUntil: String
    let isActive: Bool

    init(id: UUID = UUID(), code: String, description: String, discount: String, minOrder: String, validUntil: String, isActive: Bool) {
        self.id = id
        self.code = code
        self.description = description
        self.discount = discount
        self.minOrder = minOrder
        self.validUntil = validUntil
        self.isActive = isActive
    }
}

struct VouchersView: View {
    @State private var copiedCode: String?
    @State private var vouchers: [VoucherItem] = []
    @State private var isLoading = false

    private var activeVouchers: [VoucherItem] { vouchers.filter { $0.isActive } }
    private var expiredVouchers: [VoucherItem] { vouchers.filter { !$0.isActive } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading && vouchers.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading vouchers...")
                            .padding(.top, 40)
                        Spacer()
                    }
                } else if vouchers.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(GroceryTheme.muted)
                            Text("No Vouchers Available")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(GroceryTheme.title)
                            Text("Vouchers assigned by admin will appear here.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(GroceryTheme.muted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                        Spacer()
                    }
                } else {
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
            }
            .padding(.vertical, 12)
        }
        .background(GroceryTheme.background)
        .navigationTitle("My Vouchers")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadVouchers() }
        .refreshable { await loadVouchers() }
    }

    private func loadVouchers() async {
        guard APIClient.shared.isAuthenticated else { return }
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        do {
            let dtos: [VoucherDTO] = try await APIClient.shared.get("/api/vouchers/user")
            let mapped = dtos.map(\.asVoucherItem)
            await MainActor.run { vouchers = mapped }
            print("✅ [Vouchers] Loaded \(mapped.count) voucher(s)")
        } catch {
            print("⚠️ Failed to load vouchers: \(error)")
        }
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
