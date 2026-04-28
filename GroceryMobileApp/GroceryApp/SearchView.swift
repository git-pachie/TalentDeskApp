import SwiftUI

struct SearchView: View {
    @State private var searchText = ""

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredProducts: [GroceryProduct] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return SampleData.allProducts.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query) ||
            $0.location.localizedCaseInsensitiveContains(query)
        }
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
                    if isSearching {
                        Button {
                            searchText = ""
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

                if isSearching {
                    // Search results
                    searchResults
                } else {
                    // Default content when not searching
                    defaultContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(GroceryTheme.background)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Search Results

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(filteredProducts.count) result\(filteredProducts.count == 1 ? "" : "s")")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(GroceryTheme.muted)

            if filteredProducts.isEmpty {
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
                    ForEach(filteredProducts) { product in
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
        VStack(alignment: .leading, spacing: 16) {
            // Quick search suggestions
            Text("Popular Searches")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)

            ForEach(SampleData.allProducts.prefix(6)) { product in
                Button {
                    searchText = product.name
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemGray6))
                            .frame(width: 40, height: 40)
                            .overlay {
                                if let urlString = product.imageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Text(product.emoji).font(.title3)
                                    }
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

            // Browse by category
            Text("Browse Categories")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GroceryTheme.title)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(SampleData.categories) { cat in
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
    .environment(FavoritesStore())
    .environment(CartStore())
}
