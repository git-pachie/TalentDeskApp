import Foundation
import Observation

@Observable
final class FavoritesStore {
    var favoriteIDs: Set<UUID> = []

    func isFavorite(_ product: GroceryProduct) -> Bool {
        favoriteIDs.contains(product.id)
    }

    func toggle(_ product: GroceryProduct) {
        if favoriteIDs.contains(product.id) {
            favoriteIDs.remove(product.id)
        } else {
            favoriteIDs.insert(product.id)
        }
    }

    func favorites(from products: [GroceryProduct]) -> [GroceryProduct] {
        products.filter { favoriteIDs.contains($0.id) }
    }
}
