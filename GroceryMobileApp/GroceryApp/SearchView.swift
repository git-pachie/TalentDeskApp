import SwiftUI

struct SearchView: View {
    @Environment(ProductStore.self) private var productStore
    @State private var searchText = ""
    @State private var results: [GroceryProduct] = []
    @State private var isSearchActive = false
    @State private var searchTask: Task<Void, Never>?

    private var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search input
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(GroceryTheme.muted)
                    TextField("Search by name, category...", text: $searchText)
                        .font(.subheadline)
                    if hasQuery {
                        Button {
                            searchText = ""
                            results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(GroceryTheme.muted)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if hasQuery {
                    searchResultsView
                } else {
                    defaultContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(GroceryTheme.background)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { _, newValue in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                let query = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if query.isEmpty {
                    results = []
                } else {
                    results = await productStore.search(query: query)
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(GroceryTheme.muted)

            if results.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term.")
                )
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 14) {
                    ForEach(results) { product in
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

    // MARK: - Default Content

    private var defaultContent: some View {
        let popularProducts = productStore.allProducts.isEmpty ? SampleData.allProducts : productStore.allProducts
        let categories = productStore.categories.isEmpty ? SampleData.categories : productStore.categories

        return VStack(alignment: .leading, spacing: 16) {
            Text("Popular Searches")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)

            ForEach(Array(popularProducts.prefix(6))) { product in
                Button {
                    searchText = product.name
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemGray6))
                            .frame(width: 40, height: 40)
                            .overlay {
                                if let urlString = product.imageURL, let url = URL(string: urlString) {
                                    CachedAsyncImage(url: url, emoji: product.emoji, lastModified: product.imageDateModified)
                                } else {
                                    Text(product.emoji).font(.title3)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name)
                                .font(.subheadline)
                                .foregroundStyle(GroceryTheme.title)
                            Text(product.category)
                                .font(.caption2)
                                .foregroundStyle(GroceryTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(GroceryTheme.muted)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            Divider()

            Text("Browse Categories")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(categories) { cat in
                    Button {
                        searchText = cat.name
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(GroceryTheme.primaryLight)
                                    .frame(height: 60)
                                Text(cat.emoji)
                                    .font(.system(size: 28))
                            }
                            Text(cat.name)
                                .font(.caption2)
                                .foregroundStyle(GroceryTheme.subtitle)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .groceryPreviewEnvironment()
}
