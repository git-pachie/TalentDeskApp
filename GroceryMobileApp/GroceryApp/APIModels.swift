import Foundation

// MARK: - Auth

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let phoneNumber: String?
}

struct AuthResponse: Decodable {
    let success: Bool
    let token: String?
    let expiresAt: Date?
    let user: UserDTO?
    let errors: [String]?
}

struct UserDTO: Codable, Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let phoneNumber: String?
    let profileImageUrl: String?
    let roles: [String]?

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - Categories

struct CategoryDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let imageUrl: String?
    let isActive: Bool
    let productCount: Int

    /// Map to the app's GroceryCategory
    var asGroceryCategory: GroceryCategory {
        GroceryCategory(id: id, name: name, emoji: emojiForCategory(name))
    }
}

private func emojiForCategory(_ name: String) -> String {
    let map: [String: String] = [
        "fruits": "🍎", "vegetables": "🥕", "veggie": "🥕",
        "meats": "🥩", "meat": "🥩", "snacks": "🍿",
        "drinks": "🥤", "beverages": "🥤", "dairy": "🧀",
        "bakery": "🍞", "bread": "🍞", "seafood": "🦐",
        "frozen": "🧊", "organic": "🌿", "condiments": "🧂",
    ]
    return map[name.lowercased()] ?? "🛒"
}

// MARK: - Products

struct ProductDTO: Decodable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let price: Decimal
    let discountPrice: Decimal?
    let stockQuantity: Int
    let unit: String?
    let isActive: Bool
    let categoryId: UUID
    let categoryName: String
    let images: [ProductImageDTO]
    let averageRating: Double
    let reviewCount: Int

    /// Map to the app's GroceryProduct
    var asGroceryProduct: GroceryProduct {
        let priceDouble = NSDecimalNumber(decimal: price).doubleValue
        let originalDouble = discountPrice != nil ? priceDouble : nil
        let discountDouble = discountPrice.map { NSDecimalNumber(decimal: $0).doubleValue }
        let actualPrice = discountDouble ?? priceDouble
        let discountText: String? = if let orig = originalDouble, orig > 0 {
            "\(Int(((orig - actualPrice) / orig) * 100))% off"
        } else {
            nil
        }
        let primaryImage = images.first(where: { $0.isPrimary })?.imageUrl ?? images.first?.imageUrl

        return GroceryProduct(
            id: id,
            name: name,
            location: categoryName,
            price: discountDouble ?? priceDouble,
            originalPrice: discountPrice != nil ? priceDouble : nil,
            discount: discountText,
            emoji: emojiForCategory(categoryName),
            category: categoryName,
            imageURL: primaryImage
        )
    }
}

struct ProductImageDTO: Decodable, Identifiable {
    let id: UUID
    let imageUrl: String
    let isPrimary: Bool
    let sortOrder: Int
}

// MARK: - Cart

struct CartItemDTO: Decodable, Identifiable {
    let id: UUID
    let productId: UUID
    let productName: String
    let productImageUrl: String?
    let unitPrice: Decimal
    let quantity: Int
    let totalPrice: Decimal
}

struct AddToCartRequest: Encodable {
    let productId: UUID
    let quantity: Int
}

struct UpdateCartItemRequest: Encodable {
    let quantity: Int
}

// MARK: - Orders

struct OrderDTO: Decodable, Identifiable {
    let id: UUID
    let orderNumber: String
    let subTotal: Decimal
    let discountAmount: Decimal
    let deliveryFee: Decimal
    let totalAmount: Decimal
    let status: String
    let notes: String?
    let createdAt: Date
    let items: [OrderItemDTO]?
    let payment: PaymentSummaryDTO?
    let address: OrderAddressDTO?

    var asOrderItem: OrderItem {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return OrderItem(
            id: id,
            orderNumber: orderNumber,
            date: formatter.string(from: createdAt),
            items: items?.reduce(0) { $0 + $1.quantity } ?? 0,
            total: NSDecimalNumber(decimal: totalAmount).doubleValue,
            status: OrderStatus.from(status),
            orderRemarks: notes ?? "",
            paymentMethod: payment?.method ?? "Unknown",
            paymentDetail: ""
        )
    }
}

struct OrderItemDTO: Decodable {
    let productId: UUID
    let productName: String
    let unitPrice: Decimal
    let quantity: Int
    let totalPrice: Decimal
}

struct PaymentSummaryDTO: Decodable {
    let method: String
    let status: String
    let paidAt: Date?
}

struct OrderAddressDTO: Decodable {
    let label: String
    let street: String
    let city: String
    let province: String
    let zipCode: String

    var fullAddress: String {
        [street, city, province, zipCode].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

struct CreateOrderRequest: Encodable {
    let addressId: UUID?
    let voucherCode: String?
    let notes: String?
}

// MARK: - Addresses

struct AddressDTO: Decodable, Identifiable {
    let id: UUID
    let label: String
    let street: String
    let city: String
    let province: String
    let zipCode: String
    let country: String?
    let latitude: Double?
    let longitude: Double?
    let isDefault: Bool

    var fullAddress: String {
        [street, city, province, zipCode].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var asAddressItem: AddressItem {
        AddressItem(
            id: id,
            label: label,
            address: fullAddress,
            isDefault: isDefault,
            deliveryInstructions: "",
            contactNumber: "",
            latitude: latitude ?? 0,
            longitude: longitude ?? 0
        )
    }
}

struct CreateAddressRequest: Encodable {
    let label: String
    let street: String
    let city: String
    let province: String
    let zipCode: String
    let country: String?
    let isDefault: Bool
}

struct UpdateAddressRequest: Encodable {
    let label: String?
    let street: String?
    let city: String?
    let province: String?
    let zipCode: String?
    let country: String?
    let isDefault: Bool?
}

// MARK: - Favorites

struct FavoriteDTO: Decodable {
    let id: UUID
    let productId: UUID
    let product: ProductDTO?
}

// MARK: - Vouchers

struct VoucherDTO: Decodable, Identifiable {
    let id: UUID
    let code: String
    let description: String?
    let type: String
    let value: Decimal
    let maxDiscount: Decimal?
    let minimumSpend: Decimal
    let usageLimit: Int
    let usedCount: Int
    let isActive: Bool
    let startDate: Date?
    let expiryDate: Date

    var asVoucherItem: VoucherItem {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let discountText: String = if type.lowercased() == "percentage" {
            "\(NSDecimalNumber(decimal: value).intValue)%"
        } else {
            "$\(NSDecimalNumber(decimal: value).intValue)"
        }
        return VoucherItem(
            id: id,
            code: code,
            description: description ?? "",
            discount: discountText,
            minOrder: minimumSpend > 0 ? "Min. $\(NSDecimalNumber(decimal: minimumSpend).intValue)" : "No minimum",
            validUntil: formatter.string(from: expiryDate),
            isActive: isActive && expiryDate > Date()
        )
    }
}

struct ApplyVoucherRequest: Encodable {
    let code: String
    let cartTotal: Decimal
}

struct VoucherValidationResult: Decodable {
    let isValid: Bool
    let errorMessage: String?
    let discountAmount: Decimal
    let voucher: VoucherDTO?
}

// MARK: - Reviews

struct ReviewDTO: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let userName: String
    let productId: UUID
    let rating: Int
    let comment: String?
    let createdAt: Date
}

struct CreateReviewRequest: Encodable {
    let productId: UUID
    let orderId: UUID
    let rating: Int
    let comment: String?
}

// MARK: - Payments

struct CheckoutPaymentRequest: Encodable {
    let orderId: UUID
    let method: Int // 0=Card, 1=ApplePay, 2=GCash, 3=PayMaya, 4=COD
    let stripeToken: String?
    let returnUrl: String?
}

struct PaymentResultDTO: Decodable {
    let success: Bool
    let paymentId: UUID
    let status: String
    let redirectUrl: String?
    let failureReason: String?
}
