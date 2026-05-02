import SwiftUI

struct OrderItem: Identifiable, Hashable {
    let id: UUID
    let orderNumber: String
    let date: String
    let items: Int
    let total: Double
    let status: OrderStatus
    let orderRemarks: String
    let paymentMethod: String
    let paymentDetail: String

    init(id: UUID = UUID(), orderNumber: String, date: String, items: Int, total: Double, status: OrderStatus, orderRemarks: String = "", paymentMethod: String = "Credit Card", paymentDetail: String = "") {
        self.id = id
        self.orderNumber = orderNumber
        self.date = date
        self.items = items
        self.total = total
        self.status = status
        self.orderRemarks = orderRemarks
        self.paymentMethod = paymentMethod
        self.paymentDetail = paymentDetail
    }
}

enum OrderStatus: String, Hashable {
    case pending = "Pending"
    case paid = "Paid"
    case processing = "Processing"
    case outForDelivery = "OutForDelivery"
    case delivered = "Delivered"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .pending:        .orange
        case .paid:           .blue
        case .processing:     .orange
        case .outForDelivery: .purple
        case .delivered:      GroceryTheme.primary
        case .cancelled:      GroceryTheme.badge
        }
    }

    var icon: String {
        switch self {
        case .pending:        "clock.fill"
        case .paid:           "creditcard.fill"
        case .processing:     "shippingbox.fill"
        case .outForDelivery: "truck.box.fill"
        case .delivered:      "checkmark.circle.fill"
        case .cancelled:      "xmark.circle.fill"
        }
    }

    var displayName: String {
        switch self {
        case .outForDelivery: "Out for Delivery"
        default: rawValue
        }
    }

    /// Initialize from API status string
    static func from(_ apiStatus: String) -> OrderStatus {
        OrderStatus(rawValue: apiStatus) ?? .pending
    }
}

struct OrdersView: View {
    @State private var selectedTab = 0
    @State private var orders: [OrderItem] = []
    @State private var isLoading = false

    private var currentOrders: [OrderItem] {
        orders.filter { $0.status == .pending || $0.status == .paid || $0.status == .processing || $0.status == .outForDelivery }
    }

    private var orderHistory: [OrderItem] {
        orders.filter { $0.status == .delivered || $0.status == .cancelled }
    }

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
        .task { await loadOrders() }
        .refreshable { await loadOrders() }
    }

    private func loadOrders() async {
        guard APIClient.shared.isAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let dtos: [OrderDTO] = try await APIClient.shared.get("/api/orders")
            orders = dtos.map(\.asOrderItem)
        } catch {
            print("⚠️ Failed to load orders: \(error)")
        }
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
                    Text(order.status.displayName)
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
