import SwiftUI

@Observable
final class AppNavigationStore {
    var selectedTab = 0
    var pendingCategorySelection: GroceryCategory?
}

struct RootTabView: View {
    @Environment(CartStore.self) private var cartStore
    @Environment(AppNavigationStore.self) private var navigationStore

    var body: some View {
        @Bindable var navigationStore = navigationStore

        TabView(selection: $navigationStore.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            ProductsTabView()
                .tabItem {
                    Image(systemName: "bag.fill")
                    Text("Products")
                }
                .tag(1)

            CartView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Cart")
                }
                .badge(cartStore.totalItems)
                .tag(2)

            FavoritesView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(GroceryTheme.primary)
    }
}

#Preview {
    RootTabView()
        .groceryPreviewEnvironment()
}
