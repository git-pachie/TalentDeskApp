import Foundation

struct GroceryProduct: Identifiable, Hashable {
    let id: UUID
    let name: String
    let location: String
    let price: Double
    let originalPrice: Double?
    let discount: String?
    let emoji: String
    let category: String
    let imageURL: String?

    init(id: UUID = UUID(), name: String, location: String, price: Double, originalPrice: Double?, discount: String?, emoji: String, category: String, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.location = location
        self.price = price
        self.originalPrice = originalPrice
        self.discount = discount
        self.emoji = emoji
        self.category = category
        self.imageURL = imageURL
    }
}

struct GroceryCategory: Identifiable {
    let id: UUID
    let name: String
    let emoji: String

    init(id: UUID = UUID(), name: String, emoji: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }
}

enum SampleData {
    static let categories: [GroceryCategory] = [
        GroceryCategory(name: "Veggie", emoji: "🥕"),
        GroceryCategory(name: "Fruits", emoji: "🍎"),
        GroceryCategory(name: "Meats", emoji: "🥩"),
        GroceryCategory(name: "Snacks", emoji: "🍿"),
        GroceryCategory(name: "Drinks", emoji: "🥤"),
        GroceryCategory(name: "Dairy", emoji: "🧀"),
        GroceryCategory(name: "Bakery", emoji: "🍞"),
        GroceryCategory(name: "Seafood", emoji: "🦐"),
        GroceryCategory(name: "Frozen", emoji: "🧊"),
        GroceryCategory(name: "Organic", emoji: "🌿"),
    ]

    static let deals: [GroceryProduct] = [
        GroceryProduct(name: "Orange Tomatoes", location: "Colando, San Francisco", price: 12, originalPrice: 18, discount: "20% off", emoji: "🍅", category: "Veggie", imageURL: "https://images.unsplash.com/photo-1546470427-0d4db154ceb8?w=400"),
        GroceryProduct(name: "Ripe Avocado", location: "Colando, San Francisco", price: 8, originalPrice: 12, discount: "30% off", emoji: "🥑", category: "Veggie", imageURL: "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400"),
        GroceryProduct(name: "Red Apples", location: "Fresno, California", price: 10, originalPrice: 15, discount: "35% off", emoji: "🍎", category: "Fruits", imageURL: "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400"),
        GroceryProduct(name: "Sweet Corn", location: "Austin, Texas", price: 6, originalPrice: 9, discount: "15% off", emoji: "🌽", category: "Veggie", imageURL: "https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400"),
        GroceryProduct(name: "Fresh Strawberry", location: "Portland, Oregon", price: 14, originalPrice: 22, discount: "40% off", emoji: "🍓", category: "Fruits", imageURL: "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=400"),
        GroceryProduct(name: "Green Pepper", location: "Denver, Colorado", price: 5, originalPrice: 7, discount: "25% off", emoji: "🫑", category: "Veggie", imageURL: "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400"),
        GroceryProduct(name: "Organic Mango", location: "Miami, Florida", price: 18, originalPrice: 28, discount: "35% off", emoji: "🥭", category: "Fruits", imageURL: "https://images.unsplash.com/photo-1553279768-865429fa0078?w=400"),
        GroceryProduct(name: "Baby Spinach", location: "Seattle, Washington", price: 9, originalPrice: 12, discount: "10% off", emoji: "🥬", category: "Veggie", imageURL: "https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400"),
    ]

    static let freshProducts: [GroceryProduct] = [
        GroceryProduct(name: "Organic Carrots", location: "Colando, San Francisco", price: 20, originalPrice: 30, discount: "10% off", emoji: "🥕", category: "Veggie", imageURL: "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400"),
        GroceryProduct(name: "Orange Bananas", location: "Colando, San Francisco", price: 25, originalPrice: 30, discount: nil, emoji: "🍌", category: "Fruits", imageURL: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400"),
        GroceryProduct(name: "Fresh Broccoli", location: "Colando, San Francisco", price: 16, originalPrice: 20, discount: "20% off", emoji: "🥦", category: "Veggie", imageURL: "https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=400"),
        GroceryProduct(name: "Water Melon", location: "Colando, San Francisco", price: 18, originalPrice: 24, discount: nil, emoji: "🍉", category: "Fruits", imageURL: "https://images.unsplash.com/photo-1589984662646-e7b2e4962f18?w=400"),
    ]

    static let searchItems: [String] = [
        "Bakery & Biscuits", "Coffee", "Bread", "Egg", "Milk"
    ]

    static let searchEmojis: [String] = ["🍪", "☕", "🍞", "🥚", "🥛"]

    static let quickCategories: [(name: String, emoji: String)] = [
        ("Milk", "🥛"), ("Bread & pav", "🍞"), ("Munchies", "🍿")
    ]

    static let allProducts: [GroceryProduct] = deals + freshProducts
}
