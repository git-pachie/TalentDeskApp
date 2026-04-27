import SwiftUI

struct HomeView: View {
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
            }
            .background(GroceryTheme.background)
        }
    }

    // MARK: - Delivery Header

    private var deliveryHeader: some View {
        HStack(spacing: 8) {
            GroceryIconView(size: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text("Delivery to")
                    .font(.caption)
                    .foregroundStyle(GroceryTheme.muted)
                HStack(spacing: 4) {
                    Text("Home, New York")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GroceryTheme.title)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GroceryTheme.title)
                }
            }

            Spacer()

            Button { } label: {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(GroceryTheme.title)
            }

            NavigationLink {
                SearchView()
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

            HStack(spacing: 0) {
                ForEach(SampleData.categories) { cat in
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
                    .frame(maxWidth: .infinity)
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
                    ForEach(SampleData.deals) { product in
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

#Preview {
    HomeView()
}
