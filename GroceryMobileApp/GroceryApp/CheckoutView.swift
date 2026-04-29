import SwiftUI
import PassKit

struct CheckoutView: View {
    @Environment(CartStore.self) private var cartStore
    @State private var paymentMethod = "Credit Card"
    @State private var showingConfirmation = false
    @State private var showingAddressPicker = false
    @State private var showingPaymentPicker = false
    @State private var showingVoucherSheet = false
    @State private var appliedVoucher: (code: String, discount: Double)?
    @State private var orderPlaced = false
    @State private var successScale: CGFloat = 0
    @State private var placedOrder: OrderItem?
    @State private var navigateToOrder = false
    @State private var orderRemarks = ""
    @State private var applePayCoordinator = ApplePayCoordinator()
    @State private var showingGCashPayment = false
    @State private var showingCardPayment = false
    @State private var cardPaymentDetail = ""
    @State private var deliveryAddresses: [AddressDTO] = []
    @State private var selectedAddressId: UUID?

    private let availableVouchers = [
        (code: "FRESH10", description: "10% off your order", discount: 0.10),
        (code: "SAVE5", description: "$5 off orders above $20", discount: 5.0),
        (code: "NEWUSER", description: "$8 off first order", discount: 8.0),
        (code: "FREESHIP", description: "Free delivery", discount: 5.0),
    ]

    private var currentAddress: (label: String, address: String, instructions: String, contact: String) {
        if let idx = deliveryAddresses.firstIndex(where: { $0.id == selectedAddressId }) {
            let a = deliveryAddresses[idx]
            return (a.label, a.fullAddress, "", "")
        }
        if let first = deliveryAddresses.first {
            return (first.label, first.fullAddress, "", "")
        }
        return ("No Address", "Add a delivery address", "", "")
    }

    private let paymentMethods = [
        ("Credit Card", "creditcard.fill"),
        ("Debit Card", "creditcard"),
        ("Apple Pay", "apple.logo"),
        ("GCash", "g.circle.fill"),
        ("Cash on Delivery", "banknote.fill"),
    ]

    private let deliveryFee: Double = 5
    private let platformFee: Double = 2
    private let otherCharges: Double = 1
    private var subtotal: Double { cartStore.totalPrice }
    private var voucherDiscount: Double {
        guard let voucher = appliedVoucher else { return 0 }
        // If discount < 1, treat as percentage
        if voucher.discount < 1 {
            return subtotal * voucher.discount
        }
        return voucher.discount
    }
    private var total: Double { max(0, subtotal + deliveryFee + platformFee + otherCharges - voucherDiscount) }

    private var paymentDetailText: String {
        if !cardPaymentDetail.isEmpty && (paymentMethod == "Credit Card" || paymentMethod == "Debit Card") {
            return cardPaymentDetail
        }
        switch paymentMethod {
        case "GCash": return "+63 9XX XXX XXXX"
        case "Apple Pay": return "Apple ID: guest@icloud.com"
        case "Credit Card": return "•••• •••• •••• 4242"
        case "Debit Card": return "•••• •••• •••• 8910"
        case "Cash on Delivery": return "Pay when delivered"
        default: return ""
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Order summary
                orderSummary

                Divider()

                // Delivery address
                Button { showingAddressPicker = true } label: {
                    sectionCard(title: "Delivery Address", icon: "mappin.circle.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(currentAddress.label)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(GroceryTheme.title)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(GroceryTheme.muted)
                            }
                            Text(currentAddress.address)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(GroceryTheme.subtitle)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.caption2)
                                Text(currentAddress.contact)
                                    .font(.system(.caption, design: .rounded))
                            }
                            .foregroundStyle(GroceryTheme.primary)

                            if !currentAddress.instructions.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.bubble.fill")
                                        .font(.caption2)
                                    Text(currentAddress.instructions)
                                        .font(.system(.caption2, design: .rounded))
                                }
                                .foregroundStyle(GroceryTheme.muted)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingAddressPicker) {
                    NavigationView {
                        List(deliveryAddresses) { addr in
                            Button {
                                selectedAddressId = addr.id
                                showingAddressPicker = false
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(GroceryTheme.primary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(addr.label)
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .foregroundStyle(GroceryTheme.title)
                                        Text(addr.fullAddress)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(GroceryTheme.subtitle)
                                    }

                                    Spacer()

                                    if addr.id == selectedAddressId {
                                        Image(systemName: "checkmark.circle.fill")
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
                    .presentationDetents([.large])
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

                // Voucher
                Button { showingVoucherSheet = true } label: {
                    sectionCard(title: "Voucher", icon: "ticket.fill") {
                        HStack {
                            if let voucher = appliedVoucher {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(voucher.code)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundStyle(GroceryTheme.primary)
                                    Text("-$\(Int(voucherDiscount)) applied")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(GroceryTheme.primary)
                                }
                            } else {
                                Text("Apply a voucher code")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(GroceryTheme.subtitle)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(GroceryTheme.muted)
                        }
                    }
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingVoucherSheet) {
                    voucherSheet
                }

                // Order remarks
                sectionCard(title: "Order Remarks", icon: "text.bubble.fill") {
                    TextField("Any special instructions for this order?", text: $orderRemarks, axis: .vertical)
                        .font(.system(.subheadline, design: .rounded))
                        .lineLimit(2...4)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                // Price breakdown
                priceBreakdown

                // Place order buttons
                VStack(spacing: 12) {
                    // Apple Pay button
                    if ApplePayService.isAvailable && paymentMethod == "Apple Pay" {
                        ApplePayButtonView {
                            payWithApplePay()
                        }
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // GCash button
                    if paymentMethod == "GCash" {
                        Button {
                            showingGCashPayment = true
                        } label: {
                            HStack {
                                Text("G")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                Text("Pay with GCash — $\(Int(total))")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.0, green: 0.44, blue: 0.87))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    // Credit/Debit Card button
                    if paymentMethod == "Credit Card" || paymentMethod == "Debit Card" {
                        Button {
                            showingCardPayment = true
                        } label: {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("Pay with \(paymentMethod) — $\(Int(total))")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(paymentMethod == "Credit Card"
                                ? Color(red: 0.15, green: 0.15, blue: 0.20)
                                : Color(red: 0.0, green: 0.35, blue: 0.55))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    // Cash on Delivery — direct place order
                    if paymentMethod == "Cash on Delivery" {
                        Button {
                            placeOrder()
                        } label: {
                            HStack {
                                Image(systemName: "banknote.fill")
                                Text("Place Order (COD) — $\(Int(total))")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(GroceryTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                .sheet(isPresented: $showingGCashPayment) {
                    GCashPaymentView(
                        amount: total,
                        orderDescription: "\(cartStore.totalItems) items from GroceryApp"
                    ) {
                        showingGCashPayment = false
                        placeOrder()
                    } onCancel: {
                        showingGCashPayment = false
                    }
                }
                .sheet(isPresented: $showingCardPayment) {
                    CardPaymentView(
                        cardType: paymentMethod,
                        amount: total,
                        orderDescription: "\(cartStore.totalItems) items"
                    ) { maskedCard in
                        showingCardPayment = false
                        // Update payment detail with the actual card used
                        cardPaymentDetail = maskedCard
                        placeOrder()
                    } onCancel: {
                        showingCardPayment = false
                    }
                }
            }
            .padding(16)
        }
        .background(GroceryTheme.background)
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if orderPlaced {
                successOverlay
            }
        }
        .navigationDestination(isPresented: $navigateToOrder) {
            if let order = placedOrder {
                OrderDetailView(order: order)
            }
        }
        .task {
            await loadAddresses()
        }
    }

    // MARK: - Load Addresses

    private func loadAddresses() async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let dtos: [AddressDTO] = try await APIClient.shared.get("/api/addresses")
            deliveryAddresses = dtos
            // Select the default address
            if let defaultAddr = dtos.first(where: { $0.isDefault }) {
                selectedAddressId = defaultAddr.id
            } else if let first = dtos.first {
                selectedAddressId = first.id
            }
        } catch {
            print("⚠️ [Checkout] Failed to load addresses: \(error)")
        }
    }

    // MARK: - Place Order

    private func placeOrder() {
        Task {
            await placeOrderOnServer()
        }
    }

    private func paymentMethodToInt(_ method: String) -> Int {
        switch method {
        case "Credit Card", "Debit Card": return 0  // Card
        case "Apple Pay": return 1
        case "GCash": return 2
        case "Cash on Delivery": return 4
        default: return 0
        }
    }

    private func placeOrderOnServer() async {
        guard APIClient.shared.isAuthenticated else {
            placeOrderLocally()
            return
        }

        let request = CreateOrderRequest(
            addressId: selectedAddressId,
            voucherCode: appliedVoucher?.code,
            notes: orderRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : orderRemarks.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            let orderDTO: OrderDTO = try await APIClient.shared.post("/api/orders", body: request)
            print("✅ [Checkout] Order created: \(orderDTO.orderNumber)")

            // Create payment record on the server
            let checkoutReq = CheckoutPaymentRequest(
                orderId: orderDTO.id,
                method: paymentMethodToInt(paymentMethod),
                stripeToken: nil,
                returnUrl: nil
            )
            do {
                let paymentResult: PaymentResultDTO = try await APIClient.shared.post("/api/payments/checkout", body: checkoutReq)
                print("✅ [Checkout] Payment recorded — success: \(paymentResult.success), status: \(paymentResult.status)")
            } catch {
                print("⚠️ [Checkout] Payment record failed: \(error) — order still placed")
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"

            placedOrder = OrderItem(
                id: orderDTO.id,
                orderNumber: orderDTO.orderNumber,
                date: formatter.string(from: orderDTO.createdAt),
                items: orderDTO.items?.reduce(0) { $0 + $1.quantity } ?? cartStore.totalItems,
                total: NSDecimalNumber(decimal: orderDTO.totalAmount).doubleValue,
                status: .processing,
                orderRemarks: orderDTO.notes ?? "",
                paymentMethod: paymentMethod,
                paymentDetail: paymentDetailText
            )

            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    orderPlaced = true
                    successScale = 1
                }
                cartStore.clearCart()
            }
        } catch {
            print("❌ [Checkout] API order failed: \(error), falling back to local")
            await MainActor.run {
                placeOrderLocally()
            }
        }
    }

    private func placeOrderLocally() {
        let orderNumber = "#GR-\(Int.random(in: 2000...9999))"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let dateStr = formatter.string(from: Date())

        placedOrder = OrderItem(
            orderNumber: orderNumber,
            date: dateStr,
            items: cartStore.totalItems,
            total: total,
            status: .processing,
            orderRemarks: orderRemarks.trimmingCharacters(in: .whitespacesAndNewlines),
            paymentMethod: paymentMethod,
            paymentDetail: paymentDetailText
        )

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            orderPlaced = true
            successScale = 1
        }

        cartStore.items.removeAll()
    }

    // MARK: - Apple Pay

    private func payWithApplePay() {
        let items = cartStore.items.map { item in
            (name: "\(item.product.name) x\(item.quantity)", amount: item.product.price * Double(item.quantity))
        }

        let request = ApplePayService.createPaymentRequest(
            items: items,
            deliveryFee: deliveryFee,
            platformFee: platformFee,
            otherCharges: otherCharges,
            voucherDiscount: voucherDiscount
        )

        applePayCoordinator.present(request: request) {
            // Success
            placeOrder()
        } onFailure: {
            print("❌ Apple Pay failed")
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(GroceryTheme.primary.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(successScale)

                    Circle()
                        .fill(GroceryTheme.primary)
                        .frame(width: 80, height: 80)
                        .scaleEffect(successScale)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(successScale)
                }

                Text("Order Placed!")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                if let order = placedOrder {
                    Text("Order \(order.orderNumber)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("$\(Int(order.total)) • \(order.items) item(s)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 10) {
                    Button {
                        orderPlaced = false
                        navigateToOrder = true
                    } label: {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                            Text("View Order Status")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .foregroundStyle(GroceryTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        orderPlaced = false
                    } label: {
                        Text("Continue Shopping")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
        }
        .transition(.opacity)
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
        VStack(spacing: 8) {
            Label("Payment Summary", systemImage: "list.bullet.rectangle")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            priceRow("Subtotal", value: "$\(Int(subtotal))")
            priceRow("Delivery Fee", value: "$\(Int(deliveryFee))")
            priceRow("Platform Fee", value: "$\(Int(platformFee))")
            priceRow("Other Charges", value: "$\(Int(otherCharges))")

            if let voucher = appliedVoucher {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket.fill")
                            .font(.caption2)
                        Text("Voucher (\(voucher.code))")
                            .font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(GroceryTheme.primary)
                    Spacer()
                    Text("-$\(Int(voucherDiscount))")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(GroceryTheme.primary)
                }
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

    private func priceRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(GroceryTheme.subtitle)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(GroceryTheme.title)
        }
    }

    // MARK: - Voucher Sheet

    private var voucherSheet: some View {
        NavigationView {
            List {
                // Applied voucher remove option
                if appliedVoucher != nil {
                    Section {
                        Button {
                            appliedVoucher = nil
                            showingVoucherSheet = false
                        } label: {
                            Label("Remove Applied Voucher", systemImage: "xmark.circle")
                                .foregroundStyle(GroceryTheme.badge)
                        }
                    }
                }

                Section("Available Vouchers") {
                    ForEach(availableVouchers, id: \.code) { voucher in
                        Button {
                            appliedVoucher = (code: voucher.code, discount: voucher.discount)
                            showingVoucherSheet = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "ticket.fill")
                                    .font(.title3)
                                    .foregroundStyle(GroceryTheme.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(voucher.code)
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(GroceryTheme.title)
                                    Text(voucher.description)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(GroceryTheme.muted)
                                }

                                Spacer()

                                if appliedVoucher?.code == voucher.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(GroceryTheme.primary)
                                } else {
                                    Text("Apply")
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(GroceryTheme.primaryLight)
                                        .foregroundStyle(GroceryTheme.primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vouchers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingVoucherSheet = false }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CheckoutView()
    }
    .groceryPreviewEnvironment()
}
