import Foundation

struct GroceryProduct: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let price: Double
    let originalPrice: Double?
    let discount: String?
    let emoji: String
    let category: String
}

struct GroceryCategory: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
}

enum SampleData {
    static let categories: [GroceryCategory] = [
        GroceryCategory(name: "Veggie", emoji: "🥕"),
        GroceryCategory(name: "Fruits", emoji: "🍎"),
        GroceryCategory(name: "Meats", emoji: "🥩"),
        GroceryCategory(name: "Snacks", emoji: "🍿"),
        GroceryCategory(name: "Drinks", emoji: "🥤"),
    ]

    static let deals: [GroceryProduct] = [
        GroceryProduct(name: "Orange Tomatoes", location: "Colando, San Francisco", price: 12, originalPrice: 18, discount: "20% off", emoji: "🍅", category: "Veggie"),
        GroceryProduct(name: "Ripe Avocado", location: "Colando, San Francisco", price: 8, originalPrice: 12, discount: "30% off", emoji: "🥑", category: "Veggie"),
        GroceryProduct(name: "Red Apples", location: "Fresno, California", price: 10, originalPrice: 15, discount: "35% off", emoji: "🍎", category: "Fruits"),
        GroceryProduct(name: "Sweet Corn", location: "Austin, Texas", price: 6, originalPrice: 9, discount: "15% off", emoji: "🌽", category: "Veggie"),
        GroceryProduct(name: "Fresh Strawberry", location: "Portland, Oregon", price: 14, originalPrice: 22, discount: "40% off", emoji: "🍓", category: "Fruits"),
        GroceryProduct(name: "Green Pepper", location: "Denver, Colorado", price: 5, originalPrice: 7, discount: "25% off", emoji: "🫑", category: "Veggie"),
        GroceryProduct(name: "Organic Mango", location: "Miami, Florida", price: 18, originalPrice: 28, discount: "35% off", emoji: "🥭", category: "Fruits"),
        GroceryProduct(name: "Baby Spinach", location: "Seattle, Washington", price: 9, originalPrice: 12, discount: "10% off", emoji: "🥬", category: "Veggie"),
    ]

    static let freshProducts: [GroceryProduct] = [
        GroceryProduct(name: "Organic Carrots", location: "Colando, San Francisco", price: 20, originalPrice: 30, discount: "10% off", emoji: "🥕", category: "Veggie"),
        GroceryProduct(name: "Orange Bananas", location: "Colando, San Francisco", price: 25, originalPrice: 30, discount: nil, emoji: "🍌", category: "Fruits"),
        GroceryProduct(name: "Fresh Broccoli", location: "Colando, San Francisco", price: 16, originalPrice: 20, discount: "20% off", emoji: "🥦", category: "Veggie"),
        GroceryProduct(name: "Water Melon", location: "Colando, San Francisco", price: 18, originalPrice: 24, discount: nil, emoji: "🍉", category: "Fruits"),
    ]

    static let searchItems: [String] = [
        "Bakery & Biscuits", "Coffee", "Bread", "Egg", "Milk"
    ]

    static let searchEmojis: [String] = ["🍪", "☕", "🍞", "🥚", "🥛"]

    static let quickCategories: [(name: String, emoji: String)] = [
        ("Milk", "🥛"), ("Bread & pav", "🍞"), ("Munchies", "🍿")
    ]
}
