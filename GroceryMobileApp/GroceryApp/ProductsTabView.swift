import SwiftUI

struct ProductsTabView: View {
    @Environment(ProductStore.self) private var productStore
    @State private var searchText = ""
    @State private var selectedCategory: GroceryCategory?
    @State private var products: [GroceryProduct] = []
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var hasMore = true
    @State private var searchTask: Task<Void, Never>?

    private var categories: [GroceryCategory] {
        productStore.categories.isEmpty ? SampleData.categories : productStore.categories
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Category filter
                categoryChips
                    .padding(.bottom, 12)

                // Product grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 14) {
                        ForEach(products) { product in
                            NavigationLink {
                                ItemDetailView(product: product)
                            } label: {
                                ProductCard(product: product)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                // Load more when reaching the last few items
                                if product.id == products.suffix(3).first?.id && hasMore && !isLoading {
                                    Task { await loadMore() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    if isLoading {
                        ProgressView()
                            .padding()
                    }

                    if !isLoading && products.isEmpty {
                        ContentUnavailableView(
                            "No Products",
                            systemImage: "bag",
                            description: Text(searchText.isEmpty ? "No products available." : "No results for \"\(searchText)\"")
                        )
                        .padding(.top, 40)
                    }
                }
            }
            .background(GroceryTheme.background)
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if productStore.categories.isEmpty {
                    await productStore.loadCategories()
                }
                await loadProducts(reset: true)
            }
            .refreshable {
                await loadProducts(reset: true)
            }
            .onChange(of: searchText) { _, _ in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }
                    await loadProducts(reset: true)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(GroceryTheme.muted)
            TextField("Search products...", text: $searchText)
                .font(.system(.subheadline, design: .rounded))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(GroceryTheme.muted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GroceryTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(GroceryTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                    Task { await loadProducts(reset: true) }
                } label: {
                    chipLabel("All", emoji: "🛒", isSelected: selectedCategory == nil)
                }
                .buttonStyle(.plain)

                ForEach(categories) { cat in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat.id == selectedCategory?.id ? nil : cat
                        }
                        Task { await loadProducts(reset: true) }
                    } label: {
                        chipLabel(cat.name, emoji: cat.emoji, isSelected: selectedCategory?.id == cat.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chipLabel(_ text: String, emoji: String, isSelected: Bool) -> some View {
        HStack(spacing: 5) {
            Text(emoji)
                .font(.system(size: 14))
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? GroceryTheme.primary : GroceryTheme.card)
        .foregroundStyle(isSelected ? .white : GroceryTheme.title)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(isSelected ? Color.clear : GroceryTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Data Loading

    private func loadProducts(reset: Bool) async {
        if reset {
            currentPage = 1
            hasMore = true
        }

        isLoading = true
        defer { isLoading = false }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "pageSize", value: "20"),
            URLQueryItem(name: "sortBy", value: "newest"),
        ]

        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: query))
        }

        if let cat = selectedCategory {
            queryItems.append(URLQueryItem(name: "categoryId", value: cat.id.uuidString))
        }

        do {
            let result: PagedResult<ProductDTO> = try await APIClient.shared.get("/api/products", query: queryItems)
            let mapped = result.items.filter(\.isActive).map(\.asGroceryProduct)

            if reset {
                products = mapped
            } else {
                products.append(contentsOf: mapped)
            }

            hasMore = result.page < result.totalPages
        } catch {
            print("⚠️ Products load failed: \(error)")
            if reset && products.isEmpty {
                products = SampleData.freshProducts
            }
        }
    }

    private func loadMore() async {
        currentPage += 1
        await loadProducts(reset: false)
    }
}

#Preview {
    ProductsTabView()
        .groceryPreviewEnvironment()
}
