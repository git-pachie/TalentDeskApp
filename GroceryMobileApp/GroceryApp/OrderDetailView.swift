import SwiftUI
import PhotosUI

struct OrderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var order: OrderItem
    private let lockBackNavigation: Bool
    @State private var orderDetail: OrderDTO?
    @State private var rating: Int = 0
    @State private var remarks: String = ""
    @State private var showingRatingSubmitted = false
    @State private var reviewPhotos: [Data] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isReviewSubmitted = false
    @State private var isSubmittingReview = false
    @State private var lastRefreshDate = Date()
    @State private var isLoading = false
    @State private var photoViewerPhotos: [String] = []
    @State private var photoViewerIndex: Int = 0
    @State private var showingPhotoViewer = false

    init(order: OrderItem, lockBackNavigation: Bool = false) {
        self._order = State(initialValue: order)
        self.lockBackNavigation = lockBackNavigation
    }

    // Use API data for price breakdown when available
    private var subtotal: Double {
        orderDetail.map { NSDecimalNumber(decimal: $0.subTotal).doubleValue } ?? order.total
    }
    private var deliveryFee: Double {
        orderDetail.map { NSDecimalNumber(decimal: $0.deliveryFee).doubleValue } ?? 0
    }
    private var platformFee: Double {
        orderDetail?.platformFee.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0
    }
    private var otherCharges: Double {
        orderDetail?.otherCharges.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0
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

                // Delivery schedule
                deliveryScheduleSection

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
        .navigationBarBackButtonHidden(lockBackNavigation)
        .toolbar {
            if lockBackNavigation {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
        .sheet(isPresented: $showingPhotoViewer) {
            ReviewPhotoViewerSheet(
                photos: photoViewerPhotos,
                initialIndex: photoViewerIndex
            )
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

            // Check if user already submitted a review for this order
            if let existingReviews = dto.reviews, !existingReviews.isEmpty {
                isReviewSubmitted = true
                if let first = existingReviews.first {
                    rating = first.rating
                    remarks = first.comment ?? ""
                }
            }

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
                Text(order.status.displayName)
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
                ForEach(["Pending", "Paid", "Processing", "Out for Delivery", "Delivered"], id: \.self) { step in
                    let isActive = stepIsActive(step)
                    VStack(spacing: 4) {
                        Circle()
                            .fill(isActive ? GroceryTheme.primary : Color(.systemGray4))
                            .frame(width: 12, height: 12)
                        Text(step)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(isActive ? GroceryTheme.title : GroceryTheme.muted)
                            .multilineTextAlignment(.center)
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
        let steps = ["Pending", "Paid", "Processing", "Out for Delivery", "Delivered"]
        let currentIndex: Int
        switch order.status {
        case .pending:        currentIndex = 0
        case .paid:           currentIndex = 1
        case .processing:     currentIndex = 2
        case .outForDelivery: currentIndex = 3
        case .delivered:      currentIndex = 4
        case .cancelled:      currentIndex = -1
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
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemGray6))
                            .frame(width: 44, height: 44)
                            .overlay {
                                if let urlString = item.productImageUrl, let url = URL(string: urlString) {
                                    CachedAsyncImage(url: url, emoji: "🛒", lastModified: item.productImageDateModified)
                                } else {
                                    Text("🛒").font(.title3)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(GroceryTheme.title)
                            Text("x\(item.quantity) @ ₱\(NSDecimalNumber(decimal: item.unitPrice).intValue)")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(GroceryTheme.muted)
                            if let r = item.remarks, !r.isEmpty {
                                HStack(spacing: 3) {
                                    Image(systemName: "text.bubble.fill")
                                        .font(.system(size: 9))
                                    Text(r)
                                        .font(.system(.caption2, design: .rounded))
                                }
                                .foregroundStyle(GroceryTheme.primary)
                            }
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(addr.label)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                    Text(addr.fullAddress)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)

                    if let contact = addr.contactNumber, !contact.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption2)
                            Text(contact)
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundStyle(GroceryTheme.primary)
                    }

                    if let instructions = addr.deliveryInstructions, !instructions.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "text.bubble.fill")
                                .font(.caption2)
                            Text(instructions)
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(GroceryTheme.subtitle)
                    }
                }
            } else {
                Text("No address on file")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.muted)
            }
        }
    }

    // MARK: - Delivery Schedule Section

    private var deliveryScheduleSection: some View {
        infoCard(title: "Delivery Schedule", icon: "calendar.badge.clock") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Date")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                    Spacer()
                    if let deliveryDate = orderDetail?.deliveryDate {
                        Text(Self.utcDateFormatter.string(from: deliveryDate))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.title)
                    } else {
                        Text("—")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(GroceryTheme.muted)
                    }
                }
                HStack {
                    Text("Time Slot")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                    Spacer()
                    Text(orderDetail?.deliveryTimeSlot ?? "Anytime")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                }
            }
        }
    }

    /// DateFormatter fixed to UTC so the stored UTC-midnight date displays
    /// the same calendar date the user originally picked (no local-time shift).
    private static let utcDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

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

            if platformFee > 0 {
                priceRow("Platform Fee", value: "₱\(Int(platformFee))")
            }

            if otherCharges > 0 {
                priceRow("Other Charges", value: "₱\(Int(otherCharges))")
            }

            if discountAmount > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Discount")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(GroceryTheme.subtitle)
                        if let code = orderDetail?.voucherCode {
                            Text(code)
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundStyle(GroceryTheme.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(GroceryTheme.primaryLight)
                                .clipShape(Capsule())
                        }
                    }
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
            Label(isReviewSubmitted ? "Order Review" : "Rate this Order", systemImage: "star.fill")
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
                // Show submitted review photos from API
                if let reviews = orderDetail?.reviews, !reviews.isEmpty {
                    let allPhotos = reviews.flatMap { $0.photos ?? [] }
                    if !allPhotos.isEmpty {
                        let photoUrls = allPhotos.map { photo -> String in
                                    let url = photo.photoUrl
                                    if url.hasPrefix("http") { return url }
                                    return "\(APIConfig.baseURL)\(url)"
                                }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(allPhotos.enumerated()), id: \.element.id) { idx, photo in
                                    let resolvedUrl = photo.photoUrl.hasPrefix("http")
                                        ? photo.photoUrl
                                        : "\(APIConfig.baseURL)\(photo.photoUrl)"
                                    if let url = URL(string: resolvedUrl) {
                                        Button {
                                            photoViewerPhotos = photoUrls
                                            photoViewerIndex = idx
                                            showingPhotoViewer = true
                                        } label: {
                                            CachedAsyncImage(url: url, emoji: "🖼️")
                                                .frame(width: 72, height: 72)
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .stroke(GroceryTheme.primary.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                Text("Review submitted ✓")
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
                                            guard !isSubmittingReview else { return }
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
                            .disabled(isSubmittingReview)
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
                        if isSubmittingReview {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(isSubmittingReview ? "Submitting..." : "Submit Review")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background((rating > 0 && !isSubmittingReview) ? GroceryTheme.primary : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(rating == 0 || isSubmittingReview)
            }
        }
        .padding(14)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func submitReview() async {
        guard rating > 0, !isSubmittingReview else { return }
        isSubmittingReview = true
        defer { isSubmittingReview = false }

        // 1. Upload photos first if any
        var uploadedPhotoUrls: [String] = []
        if !reviewPhotos.isEmpty {
            uploadedPhotoUrls = await uploadReviewPhotos(reviewPhotos)
        }

        // 2. Submit ONE review per order (using first item as product anchor)
        //    The review captures the overall order experience — rating, comment, photos
        guard let firstItem = orderDetail?.items?.first else {
            // No items loaded — mark submitted locally only
            isReviewSubmitted = true
            showingRatingSubmitted = true
            return
        }

        let request = CreateReviewRequest(
            productId: firstItem.productId,
            orderId: order.id,
            rating: rating,
            comment: remarks.isEmpty ? nil : remarks,
            photoUrls: uploadedPhotoUrls.isEmpty ? nil : uploadedPhotoUrls
        )

        do {
            let _: ReviewDTO = try await APIClient.shared.post("/api/reviews", body: request)
            print("✅ [Review] Submitted for order \(order.orderNumber)")
            isReviewSubmitted = true
            showingRatingSubmitted = true
            // Reload to fetch the saved review with photos from server
            await loadOrderDetail()
        } catch APIError.badRequest(let msg) {
            if msg.lowercased().contains("already") {
                // Already reviewed — just mark as submitted
                isReviewSubmitted = true
            } else {
                print("⚠️ [Review] Failed: \(msg)")
            }
        } catch {
            print("⚠️ [Review] Failed: \(error)")
        }
    }

    private func uploadReviewPhotos(_ photos: [Data]) async -> [String] {
        var urls: [String] = []
        do {
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()

            for (index, photoData) in photos.enumerated() {
                // Compress to JPEG
                let jpeg = UIImage(data: photoData)?.jpegData(compressionQuality: 0.75) ?? photoData
                let filename = "review_\(index).jpg"

                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(jpeg)
                body.append("\r\n".data(using: .utf8)!)
            }
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            // Use APIClient's session so self-signed cert is trusted
            var urlRequest = URLRequest(url: URL(string: "\(APIConfig.baseURL)/api/reviews/upload")!)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            if let token = UserDefaults.standard.string(forKey: "jwt_token") {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            urlRequest.httpBody = body

            // Use APIClient's trusted session
            let session = APIClient.shared.trustedSession
            let (data, response) = try await session.data(for: urlRequest)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "unknown"
                print("⚠️ [Review] Upload failed — response: \(body)")
                return []
            }

            struct UploadResult: Decodable { let urls: [String] }
            let result = try JSONDecoder().decode(UploadResult.self, from: data)
            urls = result.urls
            print("✅ [Review] Uploaded \(urls.count) photo(s): \(urls)")
        } catch {
            print("⚠️ [Review] Photo upload failed: \(error)")
        }
        return urls
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

// MARK: - Review Photo Viewer Sheet

struct ReviewPhotoViewerSheet: View {
    let photos: [String]
    let initialIndex: Int
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(photos: [String], initialIndex: Int) {
        self.photos = photos
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $currentIndex) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { idx, urlString in
                        if let url = URL(string: urlString) {
                            CachedAsyncImage(url: url, emoji: "🖼️")
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Counter
                VStack {
                    Spacer()
                    Text("\(currentIndex + 1) / \(photos.count)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
    }
}
