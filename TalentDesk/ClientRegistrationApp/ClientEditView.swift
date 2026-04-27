import SwiftUI

struct ClientEditView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var clientStore: ClientStore
    @State private var draftClient: ClientRegistration

    init(clientStore: ClientStore, client: ClientRegistration) {
        self.clientStore = clientStore
        _draftClient = State(initialValue: client)
    }

    private var isFormValid: Bool {
        !draftClient.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !draftClient.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        draftClient.age > 0 &&
        draftClient.mobile.trimmingCharacters(in: .whitespacesAndNewlines).count >= 7 &&
        draftClient.email.contains("@")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AppScreenHeader(title: "Edit Client", subtitle: "\(draftClient.firstName) \(draftClient.lastName)")

                VStack(spacing: 16) {
                    ClientPhotoPickerSection(photoData: $draftClient.photoData)
                        .dashboardCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Client Info", systemImage: "pencil.line")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                        editField(label: "First Name", text: $draftClient.firstName)
                            .textInputAutocapitalization(.words)
                        editField(label: "Last Name", text: $draftClient.lastName)
                            .textInputAutocapitalization(.words)

                        HStack {
                            Text("Age")
                                .font(.caption)
                                .foregroundStyle(AppTheme.subtitleText)
                            Spacer()
                        }
                        TextField("", value: $draftClient.age, format: .number)
                            .keyboardType(.numberPad)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.darkText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )

                        editField(label: "Mobile", text: $draftClient.mobile)
                            .keyboardType(.phonePad)
                        editField(label: "Email", text: $draftClient.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .dashboardCard()

                    Button(action: saveClient) {
                        HStack {
                            Spacer()
                            Label("Save Changes", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.5)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(AppTheme.surface)
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
    }

    private func editField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.subtitleText)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedText)
                }
                TextField("", text: text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.darkText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
        }
    }

    private func saveClient() {
        draftClient.firstName = draftClient.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        draftClient.lastName = draftClient.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        draftClient.mobile = draftClient.mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        draftClient.email = draftClient.email.trimmingCharacters(in: .whitespacesAndNewlines)
        clientStore.update(draftClient)
        dismiss()
    }
}

#Preview {
    let store = ClientStore()
    let client = ClientRegistration(firstName: "Jane", lastName: "Doe", age: 29, mobile: "5551234567", email: "jane@example.com")
    store.add(client)
    return NavigationStack {
        ClientEditView(clientStore: store, client: client)
    }
}
