import SwiftUI

struct HomeView: View {
    @Environment(ProductStore.self) private var productStore
    @State private var showingAddressPicker = false
    @State private var selectedAddressIndex = 0
    @State private var refreshID = UUID()
    @State private var addresses: [(label: String, address: String, contact: String)] = [
        ("Home", "123 Main St, New York, NY 10001", "+1 (555) 123-4567"),
    ]

    private var currentAddress: (label: String, address: String, contact: String) {
        guard selectedAddressIndex < addresses.count else {
            return ("Home", "Set delivery address", "")
        }
        return addresses[selectedAddressIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
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
                .id(refreshID)
            }
            .refreshable {
                await productStore.loadHome()
                refreshID = UUID()
            }
            .task {
                if productStore.categories.isEmpty {
                    await productStore.loadHome()
                }
                // Load addresses from API
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
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.caption2)
                                        Text(addr.contact)
                                            .font(.system(.caption2, design: .rounded))
                                    }
                                    .foregroundStyle(GroceryTheme.primary)
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

    private let banners: [(title: String, subtitle: String, emoji: String, color: Color)] = [
        ("Up To 50 % Discount", "Shop fresh products,\ngrab exclusive deals.", "🥕🍅🥦", GroceryTheme.primaryBanner),
        ("Free Delivery", "On orders above $30.\nFresh to your door.", "🚚📦✨", Color(red: 0.90, green: 0.92, blue: 1.0)),
        ("Buy 1 Get 1 Free", "Selected fruits & veggies\nthis weekend only.", "🍎🥑🍇", Color(red: 1.0, green: 0.93, blue: 0.85)),
    ]

    @State private var currentBanner = 0

    private var specialOfferBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Special Offers")
                .font(.headline)
                .foregroundStyle(GroceryTheme.title)

            TabView(selection: $currentBanner) {
                ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
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
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 160)

            // Page dots
            HStack(spacing: 6) {
                Spacer()
                ForEach(0..<banners.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentBanner ? GroceryTheme.primary : GroceryTheme.muted.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
                Spacer()
            }
        }
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

            let rows = [
                GridItem(.fixed(90), spacing: 10),
                GridItem(.fixed(90), spacing: 10)
            ]

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: 14) {
                    ForEach(productStore.categories.isEmpty ? SampleData.categories : productStore.categories) { cat in
                        Button {
                            print("📂 Category tapped: \(cat.name)")
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
                            }
                            .frame(width: 65)
                        }
                        .buttonStyle(.plain)
                    }
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

            LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 14) {
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
    func loadAddresses() async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let dtos: [AddressDTO] = try await APIClient.shared.get("/api/addresses")
            if !dtos.isEmpty {
                addresses = dtos.map { (label: $0.label, address: $0.fullAddress, contact: "") }
                if let defaultIdx = dtos.firstIndex(where: { $0.isDefault }) {
                    selectedAddressIndex = defaultIdx
                }
            }
        } catch {
            print("⚠️ Failed to load addresses: \(error)")
        }
    }
}

#Preview {
    HomeView()
        .groceryPreviewEnvironment()
}
