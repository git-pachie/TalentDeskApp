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
                ScrollView {
                    VStack(spacing: 0) {
                        AppScreenHeader(
                            title: "\(client.firstName) \(client.lastName)",
                            subtitle: client.email
                        )

                        VStack(spacing: 16) {
                            // Profile photo
                            VStack(spacing: 10) {
                                ClientPhotoView(photoData: client.photoData, size: 80)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .dashboardCard()

                        // Details
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Details", systemImage: "person.text.rectangle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)

                            detailRow(label: "Name", value: client.firstName)
                            detailRow(label: "Last Name", value: client.lastName)
                            detailRow(label: "Age", value: "\(client.age)")
                            detailRow(label: "Mobile", value: client.mobile)
                            detailRow(label: "Email", value: client.email)
                        }
                        .dashboardCard()

                        // Skills
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Skills", systemImage: "list.bullet.clipboard")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)

                            if client.skills.isEmpty {
                                Text("No skills added")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.mutedText)
                            } else {
                                ForEach(client.skills) { skill in
                                    HStack {
                                        Text(skill.name)
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.darkText)
                                        Spacer()
                                        Text(formattedRate(skill.hourlyRate))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.subtitleText)
                                    }
                                    if skill.id != client.skills.last?.id {
                                        Divider().overlay(AppTheme.cardBorder)
                                    }
                                }
                            }

                            Button(client.skills.isEmpty ? "Add Skills" : "Manage Skills") {
                                showingSkillsSheet = true
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dashboardCard()

                        // Address
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Address", systemImage: "mappin.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)

                            if let address = client.address, !address.isEmpty {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.darkText)
                            } else {
                                Text("No address added")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.mutedText)
                            }

                            Button(client.address == nil ? "Add Address" : "Update Address") {
                                showingAddressSheet = true
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dashboardCard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    }
                }
                .background(AppTheme.surface)
                .ignoresSafeArea(edges: .top)
                .navigationBarHidden(true)
                .toolbar {
                    NavigationLink("Edit") {
                        ClientEditView(clientStore: clientStore, client: client)
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.accent)
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
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtitleText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.darkText)
        }
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
