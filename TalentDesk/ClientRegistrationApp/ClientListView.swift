import SwiftUI

struct ClientListView: View {
    @Bindable var clientStore: ClientStore
    @State private var searchText = ""

    private var filteredClients: [ClientRegistration] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clientStore.clients }
        return clientStore.clients.filter { client in
            [client.firstName, client.lastName, client.mobile, client.email, "\(client.age)"]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            AppScreenHeader(title: "Clients", subtitle: "\(clientStore.clients.count) registered")

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.mutedText)
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Search clients")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedText)
                    }
                    TextField("", text: $searchText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.darkText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.secondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if filteredClients.isEmpty {
                Spacer()
                ContentUnavailableView(
                    searchText.isEmpty ? "No Clients Yet" : "No Results",
                    systemImage: searchText.isEmpty ? "person.2.slash" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "Registered clients will appear here." : "Try a different search term.")
                )
                .foregroundStyle(AppTheme.subtitleText)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredClients) { client in
                            NavigationLink {
                                ClientDetailView(clientStore: clientStore, clientID: client.id)
                            } label: {
                                HStack(spacing: 12) {
                                    ClientPhotoView(photoData: client.photoData, size: 44)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(client.firstName) \(client.lastName)")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(AppTheme.darkText)
                                        Text(client.email)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.subtitleText)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.mutedText)
                                }
                                .padding(12)
                                .background(AppTheme.secondarySurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(AppTheme.surface)
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
    }

    private func deleteClients(at offsets: IndexSet) {
        clientStore.delete(at: offsets, from: filteredClients)
    }
}

#Preview {
    let store = ClientStore()
    store.clients = [
        ClientRegistration(firstName: "Jane", lastName: "Doe", age: 29, mobile: "5551234567", email: "jane@example.com"),
        ClientRegistration(firstName: "John", lastName: "Smith", age: 42, mobile: "5559876543", email: "john@example.com")
    ]
    return NavigationStack {
        ClientListView(clientStore: store)
    }
}
