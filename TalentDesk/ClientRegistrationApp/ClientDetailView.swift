import SwiftUI

struct ClientDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var clientStore: ClientStore
    let clientID: UUID
    @State private var showingAddressSheet = false
    @State private var showingSkillsSheet = false
    @State private var showingAddSkillSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditSheet = false

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

                            if client.skills.isEmpty {
                                Button("Add Skills") {
                                    showingAddSkillSheet = true
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                            } else {
                                Button("Manage Skills") {
                                    showingSkillsSheet = true
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                            }
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

                        // Edit
                        Button {
                            showingEditSheet = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Edit Client", systemImage: "pencil.line")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                            }
                        }
                        .buttonStyle(AppPrimaryButtonStyle())

                        // Delete
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Client", systemImage: "trash.fill")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.12))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    }
                }
                .background(AppTheme.surface)
                .ignoresSafeArea(edges: .top)
                .navigationBarHidden(true)
                .alert(
                    "Delete Client",
                    isPresented: $showingDeleteConfirmation
                ) {
                    Button("Yes", role: .destructive) {
                        if let index = clientStore.clients.firstIndex(where: { $0.id == clientID }) {
                            clientStore.clients.remove(at: index)
                        }
                        dismiss()
                    }
                    Button("No", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete this client? This action cannot be undone.")
                }
                .toolbar {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.accent)
                }
                .sheet(isPresented: $showingEditSheet) {
                    if let c = clientStore.client(withID: clientID) {
                        ClientEditSheet(clientStore: clientStore, client: c)
                    }
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
                .sheet(isPresented: $showingAddSkillSheet) {
                    if let c = clientStore.client(withID: clientID) {
                        ClientSkillEditorSheet(title: "Add Skill") { skill in
                            var updated = c
                            updated.skills.append(skill)
                            clientStore.update(updated)
                        }
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
