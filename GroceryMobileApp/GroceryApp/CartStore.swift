import Foundation
import Observation

struct CartItem: Identifiable {
    let id: UUID
    let product: GroceryProduct
    var quantity: Int
    var remarks: String
}

@Observable
final class CartStore {
    var items: [CartItem] = []

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }

    func add(_ product: GroceryProduct, quantity: Int = 1) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantity
        } else {
            items.append(CartItem(id: product.id, product: product, quantity: quantity, remarks: ""))
        }
    }

    func remove(_ product: GroceryProduct) {
        items.removeAll { $0.product.id == product.id }
    }

    func updateQuantity(for product: GroceryProduct, quantity: Int) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            if quantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = quantity
            }
        }
    }

    func isInCart(_ product: GroceryProduct) -> Bool {
        items.contains { $0.product.id == product.id }
    }

    func updateRemarks(for product: GroceryProduct, remarks: String) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].remarks = remarks
        }
    }
}
