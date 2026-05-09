import Foundation
import Observation

@Observable
final class FavoritesStore {
    var favoriteIDs: Set<UUID> = []
    var favoriteProducts: [GroceryProduct] = []

    func isFavorite(_ product: GroceryProduct) -> Bool {
        favoriteIDs.contains(product.id)
    }

    func toggle(_ product: GroceryProduct) {
        if favoriteIDs.contains(product.id) {
            favoriteIDs.remove(product.id)
            favoriteProducts.removeAll { $0.id == product.id }
            Task { await removeOnServer(productId: product.id) }
        } else {
            favoriteIDs.insert(product.id)
            favoriteProducts.append(product)
            Task { await addOnServer(productId: product.id) }
        }
    }

    func favorites(from products: [GroceryProduct]) -> [GroceryProduct] {
        products.filter { favoriteIDs.contains($0.id) }
    }

    // MARK: - API Sync

    func loadFromServer() async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let dtos: [FavoriteDTO] = try await APIClient.shared.get("/api/favorites")
            favoriteIDs = Set(dtos.map(\.productId))
            favoriteProducts = dtos.compactMap { $0.product?.asGroceryProduct }
        } catch {
            print("⚠️ Failed to load favorites from server: \(error)")
        }
    }

    private func addOnServer(productId: UUID) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let _: FavoriteDTO = try await APIClient.shared.postNoBody("/api/favorites/\(productId.uuidString)")
        } catch {
            print("⚠️ Failed to add favorite on server: \(error)")
        }
    }

    private func removeOnServer(productId: UUID) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            try await APIClient.shared.delete("/api/favorites/\(productId.uuidString)")
        } catch {
            print("⚠️ Failed to remove favorite on server: \(error)")
        }
    }
}
