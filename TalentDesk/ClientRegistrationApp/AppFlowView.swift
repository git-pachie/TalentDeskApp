import SwiftUI

struct AppFlowView: View {
    @Bindable var sessionStore: AppSessionStore
    @Bindable var clientStore: ClientStore

    var body: some View {
        switch sessionStore.launchStage {
        case .registration:
            AppRegistrationView(sessionStore: sessionStore)
        case .splash:
            AppSplashView(sessionStore: sessionStore)
        case .ready:
            RootTabView(sessionStore: sessionStore, clientStore: clientStore)
        }
    }
}

#Preview {
    AppFlowView(sessionStore: AppSessionStore(), clientStore: ClientStore())
}
