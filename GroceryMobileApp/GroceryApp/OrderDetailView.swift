import SwiftUI
import PhotosUI

struct OrderDetailView: View {
    let order: OrderItem
    @State private var rating: Int = 0
    @State private var remarks: String = ""
    @State private var showingRatingSubmitted = false
    @State private var reviewPhotos: [Data] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isReviewSubmitted = false

    private var deliveryFee: Double { 5 }
    private var platformFee: Double { 2 }
    private var voucher: Double { order.status == .delivered ? -5 : 0 }
    private var otherCharges: Double { 1 }
    private var grandTotal: Double { order.total + deliveryFee + platformFee + voucher + otherCharges }

    private let sampleProducts: [(emoji: String, name: String, qty: Int, price: Int)] = [
        ("🍅", "Orange Tomatoes", 2, 12),
        ("🥑", "Ripe Avocado", 1, 8),
        ("🍎", "Red Apples", 1, 10),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Order header
                orderHeader

                // Status timeline
                statusCard

                Divider()

                // Items ordered
                itemsSection

                Divider()

                // Delivery address
                infoCard(title: "Delivery Address", icon: "mappin.circle.fill") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Home")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.title)
                        Text("123 Main St, New York, NY 10001")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(GroceryTheme.muted)
                    }
                }

                // Payment method
                infoCard(title: "Payment Method", icon: "creditcard.fill") {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .foregroundStyle(GroceryTheme.primary)
                        Text("Credit Card •••• 4242")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(GroceryTheme.title)
                    }
                }

                // Delivered by
                infoCard(title: "Delivered By", icon: "bicycle") {
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(GroceryTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("John Rider")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(GroceryTheme.title)
                            Text("GroceryExpress Partner")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(GroceryTheme.muted)
                        }
                    }
                }

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

    // MARK: - Export Functions

    private func generatePDF() -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Order_\(order.orderNumber).pdf")

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let page = context.cgContext

                // Title
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.label
                ]
                "Order Details".draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttrs)

                // Order info
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
                drawRow("Items:", "\(order.items) items")

                y += 10
                // Divider line
                page.setStrokeColor(UIColor.separator.cgColor)
                page.move(to: CGPoint(x: 40, y: y))
                page.addLine(to: CGPoint(x: 572, y: y))
                page.strokePath()
                y += 16

                // Items
                "Items Ordered".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.label])
                y += 28

                for item in sampleProducts {
                    drawRow("\(item.emoji) \(item.name) x\(item.qty)", "$\(item.price * item.qty)")
                }

                y += 10
                page.move(to: CGPoint(x: 40, y: y))
                page.addLine(to: CGPoint(x: 572, y: y))
                page.strokePath()
                y += 16

                // Price breakdown
                "Payment Summary".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.label])
                y += 28

                drawRow("Subtotal:", "$\(Int(order.total))")
                drawRow("Delivery Fee:", "$\(Int(deliveryFee))")
                drawRow("Platform Fee:", "$\(Int(platformFee))")
                if voucher != 0 {
                    drawRow("Voucher:", "-$\(Int(abs(voucher)))")
                }
                drawRow("Other Charges:", "$\(Int(otherCharges))")

                y += 6
                page.move(to: CGPoint(x: 40, y: y))
                page.addLine(to: CGPoint(x: 572, y: y))
                page.strokePath()
                y += 12

                "Grand Total:".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.label])
                "$\(Int(grandTotal))".draw(at: CGPoint(x: 250, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor(red: 0.329, green: 0.690, blue: 0.314, alpha: 1)])
                y += 30

                // Delivery info
                drawRow("Delivery Address:", "123 Main St, New York, NY 10001")
                drawRow("Payment Method:", "Credit Card •••• 4242")
                drawRow("Delivered By:", "John Rider")

                // Footer
                y += 20
                let footerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.tertiaryLabel
                ]
                "Generated by GroceryApp".draw(at: CGPoint(x: 40, y: y), withAttributes: footerAttrs)
            }
            return url
        } catch {
            print("PDF generation failed: \(error)")
            return nil
        }
    }

    private func exportAndShare() {
        guard let url = generatePDF() else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var presenter = rootVC
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            activityVC.popoverPresentationController?.sourceView = presenter.view
            presenter.present(activityVC, animated: true)
        }
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(isReviewSubmitted ? "Your Review" : "Rate this Order", systemImage: "star.fill")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.primary)

            // Stars
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
                // Display submitted review
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

                if !reviewPhotos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(reviewPhotos.enumerated()), id: \.offset) { _, data in
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }
                }

                Text("Review submitted")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GroceryTheme.primary)
            } else {
                // Edit mode
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

                // Photos
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

                // Submit button
                Button {
                    isReviewSubmitted = true
                    showingRatingSubmitted = true
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
                ForEach(["Placed", "Confirmed", "Shipped", "Delivered"], id: \.self) { step in
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
        }
        .padding(14)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func stepIsActive(_ step: String) -> Bool {
        let steps = ["Placed", "Confirmed", "Shipped", "Delivered"]
        let currentIndex: Int
        switch order.status {
        case .processing: currentIndex = 1
        case .shipped: currentIndex = 2
        case .delivered: currentIndex = 3
        case .cancelled: currentIndex = 0
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

            ForEach(sampleProducts, id: \.name) { item in
                HStack(spacing: 10) {
                    Text(item.emoji)
                        .font(.title2)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(GroceryTheme.title)
                        Text("x\(item.qty)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(GroceryTheme.muted)
                    }
                    Spacer()
                    Text("$\(item.price * item.qty)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GroceryTheme.title)
                }
                if item.name != sampleProducts.last?.name {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
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

            priceRow("Subtotal", value: "$\(Int(order.total))")
            priceRow("Delivery Fee", value: "$\(Int(deliveryFee))")
            priceRow("Platform Fee", value: "$\(Int(platformFee))")

            if voucher != 0 {
                HStack {
                    Text("Voucher")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GroceryTheme.subtitle)
                    Spacer()
                    Text("-$\(Int(abs(voucher)))")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(GroceryTheme.primary)
                }
            }

            priceRow("Other Charges", value: "$\(Int(otherCharges))")

            Divider()

            HStack {
                Text("Grand Total")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GroceryTheme.title)
                Spacer()
                Text("$\(Int(grandTotal))")
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
}

#Preview {
    NavigationStack {
        OrderDetailView(order: OrderItem(orderNumber: "#GR-1042", date: "Apr 28, 2026", items: 3, total: 45, status: .shipped))
    }
}
