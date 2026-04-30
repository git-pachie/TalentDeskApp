import SwiftUI
import PhotosUI

struct OrderDetailView: View {
    @State private var order: OrderItem
    @State private var orderDetail: OrderDTO?
    @State private var rating: Int = 0
    @State private var remarks: String = ""
    @State private var showingRatingSubmitted = false
    @State private var reviewPhotos: [Data] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isReviewSubmitted = false
    @State private var lastRefreshDate = Date()
    @State private var isLoading = false

    init(order: OrderItem) {
        self._order = State(initialValue: order)
    }

    // Use API data for price breakdown when available
    private var subtotal: Double {
        orderDetail.map { NSDecimalNumber(decimal: $0.subTotal).doubleValue } ?? order.total
    }
    private var deliveryFee: Double {
        orderDetail.map { NSDecimalNumber(decimal: $0.deliveryFee).doubleValue } ?? 0
    }
    private var discountAmount: Double {
        orderDetail.map { NSDecimalNumber(decimal: $0.discountAmount).doubleValue } ?? 0
    }
    private var grandTotal: Double {
        orderDetail.map { NSDecimalNumber(decimal: $0.totalAmount).doubleValue } ?? order.total
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Last updated
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                    Text("Updated \(lastRefreshDate.formatted(date: .omitted, time: .shortened))")
                        .font(.system(.caption2, design: .rounded))
                }
                .foregroundStyle(GroceryTheme.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)

                // Order header
                orderHeader

                // Status timeline
                statusCard

                Divider()

                // Items ordered
                itemsSection

                Divider()

                // Order remarks
                if let notes = orderDetail?.notes, !notes.isEmpty {
                    infoCard(title: "Order Remarks", icon: "text.bubble.fill") {
                        Text(notes)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(GroceryTheme.title)
                    }
                } else if !order.orderRemarks.isEmpty {
                    infoCard(title: "Order Remarks", icon: "text.bubble.fill") {
                        Text(order.orderRemarks)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(GroceryTheme.title)
                    }
                }

                // Delivery address
                addressSection

                // Payment method
                paymentSection

                // Price breakdown
                priceBreakdown

                // Rating section (delivered orders only)
                if order.status == .delivered {
                    ratingSection
                }
            }
            .padding(16)
        }
        .background(GroceryTheme.background)
        .refreshable {
            await loadOrderDetail()
        }
        .task {
            await loadOrderDetail()
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportAndShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(GroceryTheme.primary)
                }
            }
        }
        .alert("Thank You!", isPresented: $showingRatingSubmitted) {
            Button("OK") { }
        } message: {
            Text("Your \(rating)-star rating\(reviewPhotos.isEmpty ? "" : " with \(reviewPhotos.count) photo(s)") has been submitted.")
        }
    }

    // MARK: - Load Order Detail

    @MainActor
    private func loadOrderDetail() async {
        guard APIClient.shared.isAuthenticated else {
            print("⚠️ [OrderDetail] Not authenticated, skipping refresh")
            return
        }

        let endpoint = "/api/orders/\(order.id.uuidString)"
        print("🔄 [OrderDetail] Fetching: \(endpoint)")

        do {
            let dto: OrderDTO = try await APIClient.shared.get(endpoint)
            print("🔄 [OrderDetail] API returned — status: \(dto.status), orderNumber: \(dto.orderNumber)")

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            let statusEnum = OrderStatus.from(dto.status)

            let updatedOrder = OrderItem(
                id: dto.id,
                orderNumber: dto.orderNumber,
                date: formatter.string(from: dto.createdAt),
                items: dto.items?.reduce(0) { $0 + $1.quantity } ?? order.items,
                total: NSDecimalNumber(decimal: dto.totalAmount).doubleValue,
                status: statusEnum,
                orderRemarks: dto.notes ?? "",
                paymentMethod: dto.payment?.method ?? order.paymentMethod,
                paymentDetail: order.paymentDetail
            )

            // Force UI update by setting on main actor outside animation
            order = updatedOrder
            orderDetail = dto
            lastRefreshDate = Date()
            print("✅ [OrderDetail] UI updated — status: \(order.status.rawValue)")
        } catch {
            print("❌ [OrderDetail] Failed to load: \(error)")
        }
    }

    // MARK: - Payment Icon Helper

    private func paymentIcon(for method: String) -> String {
        switch method.lowercased() {
        case "applepay", "apple pay": return "apple.logo"
        case "gcash": return "g.circle.fill"
        case "card", "debit card": return "creditcard"
        case "cashondelivery", "cash on delivery": return "banknote.fill"
        default: return "creditcard.fill"
        }
    }

    // MARK: - Order Header

    private var orderHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.orderNumber)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.title)
                Text(order.date)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: order.status.icon)
                    .font(.caption)
                Text(order.status.rawValue)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(order.status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(order.status.color.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Order Status", systemImage: "clock.fill")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.primary)

            HStack(spacing: 0) {
                ForEach(["Pending", "Paid", "Processing", "Delivered"], id: \.self) { step in
                    let isActive = stepIsActive(step)
                    VStack(spacing: 4) {
                        Circle()
                            .fill(isActive ? GroceryTheme.primary : Color(.systemGray4))
                            .frame(width: 12, height: 12)
                        Text(step)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(isActive ? GroceryTheme.title : GroceryTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Status history timeline from API
            if let history = orderDetail?.statusHistory, !history.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(history.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(index == history.count - 1 ? GroceryTheme.primary : Color(.systemGray4))
                                    .frame(width: 8, height: 8)
                                if index < history.count - 1 {
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(width: 1.5)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.status)
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundStyle(GroceryTheme.title)
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundStyle(GroceryTheme.subtitle)
                                }
                                Text("\(entry.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(entry.createdBy)")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(GroceryTheme.muted)
                            }
                            .padding(.bottom, index < history.count - 1 ? 10 : 0)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func stepIsActive(_ step: String) -> Bool {
        let steps = ["Pending", "Paid", "Processing", "Delivered"]
        let currentIndex: Int
        switch order.status {
        case .pending: currentIndex = 0
        case .paid: currentIndex = 1
        case .processing: currentIndex = 2
        case .delivered: currentIndex = 3
        case .cancelled: currentIndex = -1
        }
        guard let stepIndex = steps.firstIndex(of: step) else { return false }
        return stepIndex <= currentIndex
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Items Ordered")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)

            if let items = orderDetail?.items, !items.isEmpty {
                ForEach(Array(items.enumerated()), id: \.element.productId) { index, item in
                    HStack(spacing: 10) {
                        Text("🛒")
                            .font(.title2)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(GroceryTheme.title)
                            Text("x\(item.quantity) @ ₱\(NSDecimalNumber(decimal: item.unitPrice).intValue)")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(GroceryTheme.muted)
                        }
                        Spacer()
                        Text("₱\(NSDecimalNumber(decimal: item.totalPrice).intValue)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.title)
                    }
                    if index < items.count - 1 {
                        Divider()
                    }
                }
            } else {
                Text("\(order.items) item(s)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
            }
        }
        .padding(14)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Address Section

    private var addressSection: some View {
        infoCard(title: "Delivery Address", icon: "mappin.circle.fill") {
            if let addr = orderDetail?.address {
                VStack(alignment: .leading, spacing: 2) {
                    Text(addr.label)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                    Text(addr.fullAddress)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                }
            } else {
                Text("No address on file")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
            }
        }
    }

    // MARK: - Payment Section

    private var paymentSection: some View {
        infoCard(title: "Payment Method", icon: "creditcard.fill") {
            VStack(alignment: .leading, spacing: 4) {
                let method = orderDetail?.payment?.method ?? order.paymentMethod
                HStack(spacing: 8) {
                    Image(systemName: paymentIcon(for: method))
                        .foregroundStyle(GroceryTheme.primary)
                    Text(method)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                }
                if let paymentStatus = orderDetail?.payment?.status {
                    Text("Status: \(paymentStatus)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                }
            }
        }
    }

    // MARK: - Info Card

    private func infoCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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

            priceRow("Subtotal", value: "₱\(Int(subtotal))")
            priceRow("Delivery Fee", value: "₱\(Int(deliveryFee))")

            if discountAmount > 0 {
                HStack {
                    Text("Discount")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.subtitle)
                    Spacer()
                    Text("-₱\(Int(discountAmount))")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(GroceryTheme.primary)
                }
            }

            Divider()

            HStack {
                Text("Grand Total")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.title)
                Spacer()
                Text("₱\(Int(grandTotal))")
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

    // MARK: - Rating Section

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(isReviewSubmitted ? "Your Review" : "Rate this Order", systemImage: "star.fill")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.primary)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    if isReviewSubmitted {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= rating ? .orange : Color(.systemGray4))
                    } else {
                        Button {
                            withAnimation(.bouncy) { rating = star }
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(star <= rating ? .orange : Color(.systemGray4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if isReviewSubmitted {
                if !remarks.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remarks")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(GroceryTheme.muted)
                        Text(remarks)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(GroceryTheme.title)
                    }
                }
                Text("Review submitted")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.primary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Remarks (optional)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                    TextField("How was your experience?", text: $remarks, axis: .vertical)
                        .font(.system(.subheadline, design: .rounded))
                        .lineLimit(3...5)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Photos (optional)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(reviewPhotos.enumerated()), id: \.offset) { index, data in
                                if let uiImage = UIImage(data: data) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        Button {
                                            reviewPhotos.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(.black.opacity(0.5)))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                            }
                            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 5, matching: .images) {
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                    Text("Add")
                                        .font(.system(.caption2, design: .rounded))
                                }
                                .foregroundStyle(GroceryTheme.primary)
                                .frame(width: 70, height: 70)
                                .background(GroceryTheme.primaryLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(GroceryTheme.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            }
                        }
                    }
                }
                .onChange(of: selectedPhotoItems) { _, newItems in
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                reviewPhotos.append(data)
                            }
                        }
                        selectedPhotoItems = []
                    }
                }

                Button {
                    Task { await submitReview() }
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Review")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(rating > 0 ? GroceryTheme.primary : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(rating == 0)
            }
        }
        .padding(14)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func submitReview() async {
        guard let firstItem = orderDetail?.items?.first else {
            isReviewSubmitted = true
            showingRatingSubmitted = true
            return
        }

        let request = CreateReviewRequest(
            productId: firstItem.productId,
            orderId: order.id,
            rating: rating,
            comment: remarks.isEmpty ? nil : remarks,
            photoUrls: nil
        )

        do {
            let _: ReviewDTO = try await APIClient.shared.post("/api/reviews", body: request)
            print("✅ [Review] Submitted successfully")
        } catch {
            print("⚠️ [Review] Failed to submit: \(error)")
        }

        isReviewSubmitted = true
        showingRatingSubmitted = true
    }

    // MARK: - Export

    private func exportAndShare() {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Order_\(order.orderNumber).pdf")

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let page = context.cgContext
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.label
                ]
                "Order Details".draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttrs)

                let bodyFont = UIFont.systemFont(ofSize: 14)
                let boldFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
                let labelColor = UIColor.secondaryLabel
                let valueColor = UIColor.label
                var y: CGFloat = 80

                func drawRow(_ label: String, _ value: String) {
                    label.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: bodyFont, .foregroundColor: labelColor])
                    value.draw(at: CGPoint(x: 250, y: y), withAttributes: [.font: boldFont, .foregroundColor: valueColor])
                    y += 24
                }

                drawRow("Order Number:", order.orderNumber)
                drawRow("Date:", order.date)
                drawRow("Status:", order.status.rawValue)

                y += 10
                page.setStrokeColor(UIColor.separator.cgColor)
                page.move(to: CGPoint(x: 40, y: y))
                page.addLine(to: CGPoint(x: 572, y: y))
                page.strokePath()
                y += 16

                "Items Ordered".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.label])
                y += 28

                if let items = orderDetail?.items {
                    for item in items {
                        drawRow("\(item.productName) x\(item.quantity)", "₱\(NSDecimalNumber(decimal: item.totalPrice).intValue)")
                    }
                }

                y += 10
                page.move(to: CGPoint(x: 40, y: y))
                page.addLine(to: CGPoint(x: 572, y: y))
                page.strokePath()
                y += 16

                "Payment Summary".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.label])
                y += 28

                drawRow("Subtotal:", "₱\(Int(subtotal))")
                drawRow("Delivery Fee:", "₱\(Int(deliveryFee))")
                if discountAmount > 0 { drawRow("Discount:", "-₱\(Int(discountAmount))") }
                drawRow("Grand Total:", "₱\(Int(grandTotal))")

                y += 16
                if let addr = orderDetail?.address {
                    drawRow("Delivery:", "\(addr.label) — \(addr.fullAddress)")
                }
                drawRow("Payment:", orderDetail?.payment?.method ?? order.paymentMethod)

                y += 20
                "Generated by GroceryApp".draw(at: CGPoint(x: 40, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.tertiaryLabel
                ])
            }

            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var presenter = rootVC
                while let presented = presenter.presentedViewController { presenter = presented }
                activityVC.popoverPresentationController?.sourceView = presenter.view
                presenter.present(activityVC, animated: true)
            }
        } catch {
            print("PDF generation failed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: OrderItem(orderNumber: "#GR-1042", date: "Apr 28, 2026", items: 3, total: 45, status: .processing))
    }
}
