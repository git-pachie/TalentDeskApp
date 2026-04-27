import SwiftUI

struct ProfileView: View {
    @Environment(GrocerySettingsStore.self) private var settingsStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(GroceryTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guest User")
                                .font(.system(.headline, design: .rounded))
                            Text("guest@grocery.app")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Appearance
                Section {
                    @Bindable var settings = settingsStore
                    HStack(spacing: 8) {
                        ForEach(GroceryAppearance.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    settings.appearance = mode
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: mode.icon)
                                        .font(.title3)
                                    Text(mode.rawValue)
                                        .font(.system(.caption2, design: .rounded, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    settings.appearance == mode
                                        ? GroceryTheme.primary.opacity(0.15)
                                        : Color(.systemGray6)
                                )
                                .foregroundStyle(
                                    settings.appearance == mode
                                        ? GroceryTheme.primary
                                        : .secondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            settings.appearance == mode
                                                ? GroceryTheme.primary
                                                : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

                Section("Account") {
                    Label("Orders", systemImage: "bag")
                    Label("Addresses", systemImage: "mappin.circle")
                    Label("Payment Methods", systemImage: "creditcard")
                }

                Section("Settings") {
                    Label("Notifications", systemImage: "bell")
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProfileView()
        .environment(GrocerySettingsStore())
}
