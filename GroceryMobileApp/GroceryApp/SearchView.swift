import SwiftUI

struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Search input
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(GroceryTheme.muted)
                        TextField("Search", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Search suggestions
                    VStack(spacing: 0) {
                        ForEach(Array(zip(SampleData.searchItems, SampleData.searchEmojis)), id: \.0) { item, emoji in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 40, height: 40)
                                    Text(emoji)
                                        .font(.title3)
                                }
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundStyle(GroceryTheme.title)
                                Spacer()
                            }
                            .padding(.vertical, 8)

                            if item != SampleData.searchItems.last {
                                Divider()
                            }
                        }
                    }

                    // Filter chips
                    HStack(spacing: 10) {
                        filterChip(icon: "line.3.horizontal.decrease", label: "Shorts")
                        filterChip(label: "Brand")
                        filterChip(label: "Popularity")
                    }

                    // Quick categories
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(SampleData.quickCategories, id: \.name) { cat in
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 80)
                                    Text(cat.emoji)
                                        .font(.system(size: 36))
                                }
                                Text(cat.name)
                                    .font(.caption)
                                    .foregroundStyle(GroceryTheme.subtitle)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(GroceryTheme.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(GroceryTheme.title)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(GroceryTheme.title)
                    }
                }
            }
        }
    }

    private func filterChip(icon: String? = nil, label: String) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(label)
                .font(.caption)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(GroceryTheme.card)
        .foregroundStyle(GroceryTheme.title)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(GroceryTheme.cardBorder, lineWidth: 1))
    }
}

#Preview {
    SearchView()
}
