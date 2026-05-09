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
            if let serverId = items[index].serverCartItemId {
                let q = items[index].quantity
                let r = items[index].remarks
                Task { await updateCartItemOnServer(serverId, quantity: q, remarks: r) }
            }
        } else {
            items.append(CartItem(id: product.id, product: product, quantity: quantity, remarks: ""))
            Task { await addToCartOnServer(productId: product.id, quantity: quantity, remarks: nil) }
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
                    let r = items[index].remarks
                    Task { await updateCartItemOnServer(serverId, quantity: quantity, remarks: r) }
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
            let serverId = items[index].serverCartItemId
            let qty = items[index].quantity
            Task {
                // If serverCartItemId not yet set, wait up to 3s for it
                var resolvedId = serverId
                if resolvedId == nil {
                    for _ in 0..<6 {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        if let idx = self.items.firstIndex(where: { $0.product.id == product.id }),
                           let sid = self.items[idx].serverCartItemId {
                            resolvedId = sid
                            break
                        }
                    }
                }
                guard let sid = resolvedId else {
                    print("⚠️ [Cart] No serverCartItemId for remarks update — skipping")
                    return
                }
                await updateCartItemOnServer(sid, quantity: qty, remarks: remarks)
            }
        }
    }

    func clearCart() {
        items.removeAll()
    }

    // MARK: - API Sync

    // Also restore remarks from server on load
    func loadFromServer() async {
        guard APIClient.shared.isAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let serverItems: [CartItemDTO] = try await APIClient.shared.get("/api/cart")
            let merged = serverItems.map { dto -> CartItem in
                let product = GroceryProduct(
                    id: dto.productId,
                    name: dto.productName,
                    location: "",
                    price: NSDecimalNumber(decimal: dto.unitPrice).doubleValue,
                    originalPrice: nil,
                    discount: nil,
                    emoji: "🛒",
                    category: "",
                    imageURL: dto.productImageFullUrl ?? dto.productImageUrl,
                    imageDateModified: dto.productImageDateModified
                )
                let serverRemarks = dto.remarks ?? ""
                let localRemarks = items.first(where: { $0.product.id == dto.productId })?.remarks ?? ""
                let finalRemarks = serverRemarks.isEmpty ? localRemarks : serverRemarks
                return CartItem(
                    id: dto.productId,
                    product: product,
                    quantity: dto.quantity,
                    remarks: finalRemarks,
                    serverCartItemId: dto.id
                )
            }
            await MainActor.run { items = merged }
        } catch {
            print("⚠️ Failed to load cart from server: \(error)")
        }
    }

    private func addToCartOnServer(productId: UUID, quantity: Int, remarks: String?) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let dto: CartItemDTO = try await APIClient.shared.post(
                "/api/cart",
                body: AddToCartRequest(productId: productId, quantity: quantity, remarks: remarks)
            )
            await MainActor.run {
                if let index = items.firstIndex(where: { $0.product.id == productId }) {
                    items[index].serverCartItemId = dto.id
                }
            }
        } catch {
            print("⚠️ Failed to add to cart on server: \(error)")
        }
    }

    private func updateCartItemOnServer(_ id: UUID, quantity: Int, remarks: String?) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            let _: CartItemDTO = try await APIClient.shared.put(
                "/api/cart/\(id.uuidString)",
                body: UpdateCartItemRequest(quantity: quantity, remarks: remarks)
            )
            print("✅ [Cart] Updated item \(id) — qty:\(quantity) remarks:\(remarks ?? "nil")")
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
