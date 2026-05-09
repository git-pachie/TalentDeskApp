import Foundation
import Observation

@Observable
final class ProductStore {
    var categories: [GroceryCategory] = []
    var deals: [GroceryProduct] = []
    var freshProducts: [GroceryProduct] = []
    var isLoading = false
    var errorMessage: String?

    /// All loaded products for search/favorites
    var allProducts: [GroceryProduct] {
        let combined = deals + freshProducts
        // Deduplicate by id
        var seen = Set<UUID>()
        return combined.filter { seen.insert($0.id).inserted }
    }

    func loadHome() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Load categories and products in parallel
        async let categoriesTask: () = loadCategories()
        async let productsTask: () = loadProducts()

        await categoriesTask
        await productsTask
    }

    func loadCategories() async {
        do {
            let dtos: [CategoryDTO] = try await APIClient.shared.get("/api/categories")
            categories = dtos.filter(\.isActive).map(\.asGroceryCategory)
        } catch {
            if let apiError = error as? APIError, apiError.isCancellation {
                return
            }
            print("⚠️ Categories API failed, using sample data: \(error)")
            categories = SampleData.categories
        }
    }

    func loadProducts() async {
        do {
            let todayDeals: [TodayDealDTO] = try await APIClient.shared.get("/api/today-deals")
            deals = todayDeals
                .filter(\.isActive)
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { $0.product.asGroceryProduct }

            // Load fresh products
            let freshResult: PagedResult<ProductDTO> = try await APIClient.shared.get(
                "/api/products",
                query: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "pageSize", value: "20"),
                ]
            )
            freshProducts = freshResult.items.filter(\.isActive).map(\.asGroceryProduct)
        } catch {
            if let apiError = error as? APIError, apiError.isCancellation {
                return
            }
            print("⚠️ Products API failed, using sample data: \(error)")
            deals = SampleData.deals
            freshProducts = SampleData.freshProducts
        }
    }

    func search(query: String) async -> [GroceryProduct] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        do {
            let result: PagedResult<ProductDTO> = try await APIClient.shared.get(
                "/api/products/search",
                query: [
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "pageSize", value: "20"),
                ]
            )
            return result.items.filter(\.isActive).map(\.asGroceryProduct)
        } catch {
            if let apiError = error as? APIError, apiError.isCancellation {
                return []
            }
            print("⚠️ Search API failed, falling back to local: \(error)")
            let q = query.lowercased()
            return allProducts.filter {
                $0.name.localizedCaseInsensitiveContains(q) ||
                $0.category.localizedCaseInsensitiveContains(q)
            }
        }
    }

    func productsByCategory(_ categoryId: UUID) async -> [GroceryProduct] {
        do {
            let result: PagedResult<ProductDTO> = try await APIClient.shared.get(
                "/api/products",
                query: [
                    URLQueryItem(name: "categoryId", value: categoryId.uuidString),
                    URLQueryItem(name: "pageSize", value: "50"),
                ]
            )
            return result.items.filter(\.isActive).map(\.asGroceryProduct)
        } catch {
            if let apiError = error as? APIError, apiError.isCancellation {
                return []
            }
            print("⚠️ Category products API failed: \(error)")
            return []
        }
    }

    func productDetail(_ id: UUID) async -> ProductDTO? {
        do {
            return try await APIClient.shared.get("/api/products/\(id.uuidString)")
        } catch {
            if let apiError = error as? APIError, apiError.isCancellation {
                return nil
            }
            print("⚠️ Product detail API failed: \(error)")
            return nil
        }
    }
}
