import SwiftUI

struct OrderItem: Identifiable {
    let id = UUID()
    let orderNumber: String
    let date: String
    let items: Int
    let total: Double
    let status: OrderStatus
}

enum OrderStatus: String {
    case processing = "Processing"
    case shipped = "Shipped"
    case delivered = "Delivered"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .processing: .orange
        case .shipped: .blue
        case .delivered: GroceryTheme.primary
        case .cancelled: GroceryTheme.badge
        }
    }

    var icon: String {
        switch self {
        case .processing: "clock.fill"
        case .shipped: "shippingbox.fill"
        case .delivered: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }
}

struct OrdersView: View {
    @State private var selectedTab = 0

    private let currentOrders: [OrderItem] = [
        OrderItem(orderNumber: "#GR-1042", date: "Apr 28, 2026", items: 3, total: 45, status: .processing),
        OrderItem(orderNumber: "#GR-1039", date: "Apr 27, 2026", items: 5, total: 72, status: .shipped),
    ]

    private let orderHistory: [OrderItem] = [
        OrderItem(orderNumber: "#GR-1035", date: "Apr 22, 2026", items: 2, total: 28, status: .delivered),
        OrderItem(orderNumber: "#GR-1028", date: "Apr 18, 2026", items: 4, total: 56, status: .delivered),
        OrderItem(orderNumber: "#GR-1020", date: "Apr 12, 2026", items: 1, total: 18, status: .delivered),
        OrderItem(orderNumber: "#GR-1015", date: "Apr 8, 2026", items: 6, total: 94, status: .cancelled),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Current").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ScrollView {
                LazyVStack(spacing: 12) {
                    let orders = selectedTab == 0 ? currentOrders : orderHistory

                    if orders.isEmpty {
                        ContentUnavailableView(
                            "No Orders",
                            systemImage: "bag",
                            description: Text("Your orders will appear here.")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(orders) { order in
                            NavigationLink {
                                OrderDetailView(order: order)
                            } label: {
                                orderCard(order)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(GroceryTheme.background)
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func orderCard(_ order: OrderItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(order.orderNumber)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.title)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: order.status.icon)
                        .font(.caption2)
                    Text(order.status.rawValue)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(order.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(order.status.color.opacity(0.12))
                .clipShape(Capsule())
            }

            HStack {
                Label(order.date, systemImage: "calendar")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
                Spacer()
                Text("\(order.items) items")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.subtitle)
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.subtitle)
                Spacer()
                Text("$\(Int(order.total))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
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
        OrdersView()
    }
}
