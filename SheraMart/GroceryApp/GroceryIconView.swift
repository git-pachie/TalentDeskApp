import SwiftUI

struct GroceryIconView: View {
    var size: CGFloat = 44
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [GroceryTheme.primary, GroceryTheme.primary.opacity(0.9)]
                            : [GroceryTheme.primary, GroceryTheme.primary.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark
                                ? Color.white.opacity(0.25)
                                : Color.clear,
                            lineWidth: 1
                        )
                )

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
