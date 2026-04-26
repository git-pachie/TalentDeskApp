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
        NavigationStack {
            List {
                if filteredClients.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Clients Yet" : "No Results",
                        systemImage: searchText.isEmpty ? "person.2.slash" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Registered clients will appear here." : "Try a different search term.")
                    )
                } else {
                    ForEach(filteredClients) { client in
                        NavigationLink {
                            ClientDetailView(clientStore: clientStore, clientID: client.id)
                        } label: {
                            HStack(spacing: 12) {
                                ClientPhotoView(photoData: client.photoData, size: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(client.firstName) \(client.lastName)")
                                        .font(.subheadline.weight(.medium))
                                    Text(client.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: deleteClients)
                }
            }
            .navigationTitle("Clients")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search clients")
            .toolbar { EditButton() }
        }
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
    return ClientListView(clientStore: store)
}
