import SwiftUI

struct HomeView: View {
    @Environment(AppNavigationStore.self) private var navigationStore
    @Environment(ProductStore.self) private var productStore
    @State private var showingAddressPicker = false
    @State private var selectedAddressIndex = 0
    @State private var specialOffersRenderID = UUID()
    @State private var specialOffers: [HomeSpecialOffer] = []
    @State private var addresses: [(label: String, address: String, contact: String, instructions: String)] = [
        ("Home", "123 Main St, New York, NY 10001", "+1 (555) 123-4567", ""),
    ]
    private let adaptiveProductColumns = [
        GridItem(.adaptive(minimum: 170, maximum: 240), spacing: 12)
    ]
    private let adaptiveCategoryColumns = [
        GridItem(.adaptive(minimum: 76, maximum: 110), spacing: 12)
    ]

    private var currentAddress: (label: String, address: String, contact: String, instructions: String) {
        guard selectedAddressIndex < addresses.count else {
            return ("Home", "Set delivery address", "", "")
        }
        return addresses[selectedAddressIndex]
    }

    var body: some View {
        NavigationStack {
            RefreshableScrollContainer(onRefresh: {
                print("🔄 Home pull-to-refresh triggered")
                await refreshHomeContent()
            }) {
                VStack(alignment: .leading, spacing: 20) {
                    // Delivery header
                    deliveryHeader

                    // Search bar
                    searchBar

                    // Special Offers banner
                    specialOfferBanner

                    // Shop By Categories
                    categoriesSection

                    // Today's Deals
                    dealsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .task {
                await refreshHomeContent(initialLoadOnlyIfNeeded: true)
                await loadAddresses()
            }
            .background(GroceryTheme.background)
        }
    }

    // MARK: - Delivery Header

    private var deliveryHeader: some View {
        HStack(spacing: 8) {
            GroceryIconView(size: 38)

            Button {
                showingAddressPicker = true
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Delivery to")
                        .font(.caption)
                        .foregroundStyle(GroceryTheme.muted)
                    HStack(spacing: 4) {
                        Text(currentAddress.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GroceryTheme.title)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(GroceryTheme.title)
                    }
                    Text(currentAddress.address)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(GroceryTheme.muted)
                        .lineLimit(1)
                    if !currentAddress.contact.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 8))
                            Text(currentAddress.contact)
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(GroceryTheme.primary)
                    }
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingAddressPicker) {
                NavigationView {
                    List(Array(addresses.enumerated()), id: \.offset) { index, addr in
                        Button {
                            selectedAddressIndex = index
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
                                    Text(addr.address)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(GroceryTheme.subtitle)
                                    if !addr.contact.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "phone.fill")
                                                .font(.caption2)
                                            Text(addr.contact)
                                                .font(.system(.caption2, design: .rounded))
                                        }
                                        .foregroundStyle(GroceryTheme.primary)
                                    }
                                    if !addr.instructions.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "text.bubble.fill")
                                                .font(.caption2)
                                            Text(addr.instructions)
                                                .font(.system(.caption2, design: .rounded))
                                        }
                                        .foregroundStyle(GroceryTheme.muted)
                                    }
                                }

                                Spacer()

                                if index == selectedAddressIndex {
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
                .presentationDetents([.medium, .large])
            }

            Spacer()

            Button { } label: {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(GroceryTheme.title)
            }

            NavigationLink {
                CartView()
            } label: {
                Image(systemName: "cart")
                    .font(.title3)
                    .foregroundStyle(GroceryTheme.title)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(GroceryTheme.muted)
                Text("Search by fresh groceries...")
                    .font(.subheadline)
                    .foregroundStyle(GroceryTheme.muted)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Special Offer Banner (Carousel)

    @State private var currentBannerID: UUID?

    private var banners: [HomeSpecialOffer] {
        if specialOffers.isEmpty {
            return [
                HomeSpecialOffer(
                    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                    title: "Up To 50 % Discount",
                    subtitle: "Shop fresh products,\ngrab exclusive deals.",
                    emoji: "🥕🍅🥦",
                    color: GroceryTheme.primaryBanner
                ),
                HomeSpecialOffer(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
                    title: "Free Delivery",
                    subtitle: "On orders above ₱30.\nFresh to your door.",
                    emoji: "🚚📦✨",
                    color: Color(red: 0.90, green: 0.92, blue: 1.0)
                ),
                HomeSpecialOffer(
                    id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
                    title: "Buy 1 Get 1 Free",
                    subtitle: "Selected fruits & veggies\nthis weekend only.",
                    emoji: "🍎🥑🍇",
                    color: Color(red: 1.0, green: 0.93, blue: 0.85)
                ),
            ]
        }

        return specialOffers
    }

    private var specialOfferBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Special Offers")
                .font(.headline)
                .foregroundStyle(GroceryTheme.title)

            TabView(selection: Binding(
                get: { currentBannerID ?? banners.first?.id },
                set: { currentBannerID = $0 }
            )) {
                ForEach(banners) { banner in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(banner.color)

                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(banner.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(GroceryTheme.title)
                                Text(banner.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(GroceryTheme.subtitle)
                                Button("Shop Now") { }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(GroceryTheme.primary)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.leading, 20)

                            Spacer()

                            Text(banner.emoji)
                                .font(.system(size: 44))
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.horizontal, 2)
                    .tag(banner.id)
                }
            }
            .id(specialOffersRenderID)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 160)

            // Page dots
            HStack(spacing: 6) {
                Spacer()
                ForEach(Array(banners.enumerated()), id: \.element.id) { index, banner in
                    Circle()
                        .fill(banner.id == (currentBannerID ?? banners.first?.id) ? GroceryTheme.primary : GroceryTheme.muted.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
                Spacer()
            }
        }
        .id(specialOffersRenderID)
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Shop By Categories")
                    .font(.headline)
                    .foregroundStyle(GroceryTheme.title)
                Spacer()
                Button("See All") { }
                    .font(.subheadline)
                    .foregroundStyle(GroceryTheme.primary)
            }

            LazyVGrid(columns: adaptiveCategoryColumns, spacing: 14) {
                ForEach(productStore.categories.isEmpty ? SampleData.categories : productStore.categories) { cat in
                    Button {
                        navigationStore.pendingCategorySelection = cat
                        navigationStore.selectedTab = 1
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(GroceryTheme.primaryLight)
                                    .frame(width: 52, height: 52)
                                Text(cat.emoji)
                                    .font(.title2)
                            }
                            Text(cat.name)
                                .font(.caption2)
                                .foregroundStyle(GroceryTheme.subtitle)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Today's Deals

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Deals")
                    .font(.headline)
                    .foregroundStyle(GroceryTheme.title)
                Spacer()
                NavigationLink("See All") {
                    FreshProductsView()
                }
                .font(.subheadline)
                .foregroundStyle(GroceryTheme.primary)
            }

            LazyVGrid(columns: adaptiveProductColumns, spacing: 14) {
                ForEach(productStore.deals.isEmpty ? SampleData.deals : productStore.deals) { product in
                        NavigationLink {
                            ItemDetailView(product: product)
                        } label: {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
    }
}

// MARK: - Deal Card

extension HomeView {
    @MainActor
    func refreshHomeContent(initialLoadOnlyIfNeeded: Bool = false) async {
        if !initialLoadOnlyIfNeeded || productStore.categories.isEmpty {
            await productStore.loadHome()
        }
        await loadSpecialOffers()
    }

    @MainActor
    func loadSpecialOffers() async {
        do {
            let cacheBust = URLQueryItem(name: "_cb", value: UUID().uuidString)
            let offers: [SpecialOfferDTO] = try await APIClient.shared.getUncached("/api/special-offers", query: [cacheBust])
            specialOffers = offers
                .filter(\.isActive)
                .sorted { lhs, rhs in
                    if lhs.sortOrder == rhs.sortOrder {
                        return lhs.title < rhs.title
                    }
                    return lhs.sortOrder < rhs.sortOrder
                }
                .map { offer in
                    HomeSpecialOffer(
                        id: offer.id,
                        title: offer.title,
                        subtitle: offer.subtitle,
                        emoji: offer.emoji,
                        color: Color(hex: offer.backgroundColorHex) ?? GroceryTheme.primaryBanner
                    )
                }

            currentBannerID = specialOffers.first?.id
            specialOffersRenderID = UUID()
            print("✅ Refreshed special offers: \(specialOffers.map(\.title))")
        } catch {
            if error is CancellationError || (error as? APIError)?.isCancellation == true {
                return
            }
            print("⚠️ Failed to load special offers: \(error)")
        }
    }

    func loadAddresses() async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let dtos: [AddressDTO] = try await APIClient.shared.get("/api/addresses")
            if !dtos.isEmpty {
                addresses = dtos.map { (label: $0.label, address: $0.fullAddress, contact: $0.contactNumber ?? "", instructions: $0.deliveryInstructions ?? "") }
                if let defaultIdx = dtos.firstIndex(where: { $0.isDefault }) {
                    selectedAddressIndex = defaultIdx
                }
            }
        } catch {
            print("⚠️ Failed to load addresses: \(error)")
        }
    }
}

private struct HomeSpecialOffer: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let emoji: String
    let color: Color
}

private extension Color {
    init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard normalized.count == 6, let value = UInt64(normalized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self = Color(red: red, green: green, blue: blue)
    }
}

private struct RefreshableScrollContainer<Content: View>: UIViewControllerRepresentable {
    let onRefresh: () async -> Void
    let content: Content

    init(onRefresh: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }

    func makeUIViewController(context: Context) -> RefreshableScrollViewController<Content> {
        let controller = RefreshableScrollViewController(rootView: content)
        controller.onRefresh = onRefresh
        return controller
    }

    func updateUIViewController(_ uiViewController: RefreshableScrollViewController<Content>, context: Context) {
        uiViewController.update(rootView: content)
        uiViewController.onRefresh = onRefresh
    }
}

private final class RefreshableScrollViewController<Content: View>: UIViewController {
    private let scrollView = UIScrollView()
    private let refreshControl = UIRefreshControl()
    private let hostingController: UIHostingController<Content>

    var onRefresh: (() async -> Void)?

    init(rootView: Content) {
        hostingController = UIHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        addChild(hostingController)
        scrollView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = UIColor.clear
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    func update(rootView: Content) {
        hostingController.rootView = rootView
    }

    @objc
    private func handleRefresh() {
        Task { @MainActor in
            await onRefresh?()
            refreshControl.endRefreshing()
        }
    }
}

#Preview {
    HomeView()
        .groceryPreviewEnvironment()
}
