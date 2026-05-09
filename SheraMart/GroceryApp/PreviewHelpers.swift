import SwiftUI

extension View {
    func groceryPreviewEnvironment() -> some View {
        self
            .environment(FavoritesStore())
            .environment(CartStore())
            .environment(GrocerySettingsStore())
            .environment(AuthStore())
            .environment(ProductStore())
            .environment(AppNavigationStore())
    }
}
