import SwiftUI

struct GroceryIconView: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [GroceryTheme.primary, GroceryTheme.primary.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text("🛒")
                .font(.system(size: size * 0.5))
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        GroceryIconView(size: 40)
        GroceryIconView(size: 60)
        GroceryIconView(size: 100)
    }
}
