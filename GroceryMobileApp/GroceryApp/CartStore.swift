import Foundation
import Observation

struct CartItem: Identifiable {
    let id: UUID
    let product: GroceryProduct
    var quantity: Int
    var remarks: String
    var serverCartItemId: UUID? // ID from the API cart item
}

@Observable
final class CartStore {
    var items: [CartItem] = []
    var isLoading = false

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }

    func add(_ product: GroceryProduct, quantity: Int = 1) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantity
            // Sync with API
            if let serverId = items[index].serverCartItemId {
                Task { await updateCartItemOnServer(serverId, quantity: items[index].quantity) }
            }
        } else {
            items.append(CartItem(id: product.id, product: product, quantity: quantity, remarks: ""))
            // Sync with API
            Task { await addToCartOnServer(productId: product.id, quantity: quantity) }
        }
    }

    func remove(_ product: GroceryProduct) {
        if let item = items.first(where: { $0.product.id == product.id }),
           let serverId = item.serverCartItemId {
            Task { await removeFromCartOnServer(serverId) }
        }
        items.removeAll { $0.product.id == product.id }
    }

    func updateQuantity(for product: GroceryProduct, quantity: Int) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            if quantity <= 0 {
                let serverId = items[index].serverCartItemId
                items.remove(at: index)
                if let serverId {
                    Task { await removeFromCartOnServer(serverId) }
                }
            } else {
                items[index].quantity = quantity
                if let serverId = items[index].serverCartItemId {
                    Task { await updateCartItemOnServer(serverId, quantity: quantity) }
                }
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

    func clearCart() {
        items.removeAll()
    }

    // MARK: - API Sync

    func loadFromServer() async {
        guard APIClient.shared.isAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let serverItems: [CartItemDTO] = try await APIClient.shared.get("/api/cart")
            // Merge server items — keep local remarks
            var merged: [CartItem] = []
            for dto in serverItems {
                let product = GroceryProduct(
                    id: dto.productId,
                    name: dto.productName,
                    location: "",
                    price: NSDecimalNumber(decimal: dto.unitPrice).doubleValue,
                    originalPrice: nil,
                    discount: nil,
                    emoji: "🛒",
                    category: "",
                    imageURL: dto.productImageUrl
                )
                let existingRemarks = items.first(where: { $0.product.id == dto.productId })?.remarks ?? ""
                merged.append(CartItem(
                    id: dto.productId,
                    product: product,
                    quantity: dto.quantity,
                    remarks: existingRemarks,
                    serverCartItemId: dto.id
                ))
            }
            items = merged
        } catch {
            print("⚠️ Failed to load cart from server: \(error)")
        }
    }

    private func addToCartOnServer(productId: UUID, quantity: Int) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let dto: CartItemDTO = try await APIClient.shared.post(
                "/api/cart",
                body: AddToCartRequest(productId: productId, quantity: quantity)
            )
            // Update the server cart item ID
            if let index = items.firstIndex(where: { $0.product.id == productId }) {
                items[index].serverCartItemId = dto.id
            }
        } catch {
            print("⚠️ Failed to add to cart on server: \(error)")
        }
    }

    private func updateCartItemOnServer(_ id: UUID, quantity: Int) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let _: CartItemDTO = try await APIClient.shared.put(
                "/api/cart/\(id.uuidString)",
                body: UpdateCartItemRequest(quantity: quantity)
            )
        } catch {
            print("⚠️ Failed to update cart on server: \(error)")
        }
    }

    private func removeFromCartOnServer(_ id: UUID) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            try await APIClient.shared.delete("/api/cart/\(id.uuidString)")
        } catch {
            print("⚠️ Failed to remove from cart on server: \(error)")
        }
    }
}
