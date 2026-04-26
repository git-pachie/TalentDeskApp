import SwiftUI

struct ClientDetailView: View {
    @Bindable var clientStore: ClientStore
    let clientID: UUID
    @State private var showingAddressSheet = false
    @State private var showingSkillsSheet = false

    private var client: ClientRegistration? {
        clientStore.client(withID: clientID)
    }

    var body: some View {
        Group {
            if let client {
                List {
                    // Profile header
                    Section {
                        VStack(spacing: 10) {
                            ClientPhotoView(photoData: client.photoData, size: 80)
                            VStack(spacing: 2) {
                                Text("\(client.firstName) \(client.lastName)")
                                    .font(.headline)
                                Text(client.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }

                    Section("Details") {
                        LabeledContent("Name", value: client.firstName)
                        LabeledContent("Last Name", value: client.lastName)
                        LabeledContent("Age", value: "\(client.age)")
                        LabeledContent("Mobile", value: client.mobile)
                        LabeledContent("Email", value: client.email)
                    }

                    Section("Skills") {
                        if client.skills.isEmpty {
                            Text("No skills added")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(client.skills) { skill in
                                HStack {
                                    Text(skill.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(formattedRate(skill.hourlyRate))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Button(client.skills.isEmpty ? "Add Skills" : "Manage Skills") {
                            showingSkillsSheet = true
                        }
                        .font(.subheadline)
                    }

                    Section("Address") {
                        if let address = client.address, !address.isEmpty {
                            Text(address)
                                .font(.subheadline)
                        } else {
                            Text("No address added")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Button(client.address == nil ? "Add Address" : "Update Address") {
                            showingAddressSheet = true
                        }
                        .font(.subheadline)
                    }
                }
                .toolbar {
                    NavigationLink("Edit") {
                        ClientEditView(clientStore: clientStore, client: client)
                    }
                    .font(.subheadline)
                }
                .sheet(isPresented: $showingAddressSheet) {
                    if let c = clientStore.client(withID: clientID) {
                        ClientAddressSheet(clientStore: clientStore, client: c)
                    }
                }
                .sheet(isPresented: $showingSkillsSheet) {
                    if let c = clientStore.client(withID: clientID) {
                        ClientSkillsSheet(clientStore: clientStore, client: c)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Client Not Found",
                    systemImage: "person.slash",
                    description: Text("This client may have been deleted.")
                )
            }
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedRate(_ rate: Double?) -> String {
        guard let rate else { return "Rate not set" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: rate)) ?? String(format: "%.2f", rate)
    }
}

#Preview {
    let store = ClientStore()
    let client = ClientRegistration(firstName: "Jane", lastName: "Doe", age: 29, mobile: "5551234567", email: "jane@example.com")
    store.add(client)
    return NavigationStack {
        ClientDetailView(clientStore: store, clientID: client.id)
    }
}
