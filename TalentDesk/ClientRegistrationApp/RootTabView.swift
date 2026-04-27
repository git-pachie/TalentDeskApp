import SwiftUI

struct RootTabView: View {
    @Bindable var sessionStore: AppSessionStore
    @Bindable var clientStore: ClientStore

    var body: some View {
        TabView {
            HomeDashboardView(sessionStore: sessionStore)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RegistrationView(clientStore: clientStore)
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }

            NavigationStack {
                ClientListView(clientStore: clientStore)
            }
            .tabItem {
                Label("Clients", systemImage: "person.2.fill")
            }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    RootTabView(sessionStore: AppSessionStore(), clientStore: ClientStore())
}
