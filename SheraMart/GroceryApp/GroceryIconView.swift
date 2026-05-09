import SwiftUI

struct GroceryIconView: View {
    var size: CGFloat = 44
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image("SheraMartIcon")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.06),
                        lineWidth: 1
                    )
            )
    }
}

#Preview {
    HStack(spacing: 20) {
        GroceryIconView(size: 40)
        GroceryIconView(size: 60)
        GroceryIconView(size: 100)
    }
}
