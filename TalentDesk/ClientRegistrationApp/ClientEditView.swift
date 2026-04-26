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
        Form {
            ClientPhotoPickerSection(photoData: $draftClient.photoData)

            Section {
                TextField("First Name", text: $draftClient.firstName)
                    .textInputAutocapitalization(.words)
                TextField("Last Name", text: $draftClient.lastName)
                    .textInputAutocapitalization(.words)
                TextField("Age", value: $draftClient.age, format: .number)
                    .keyboardType(.numberPad)
                TextField("Mobile", text: $draftClient.mobile)
                    .keyboardType(.phonePad)
                TextField("Email", text: $draftClient.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Label("Client Info", systemImage: "pencil.line")
            }
        }
        .navigationTitle("Edit Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: saveClient)
                    .font(.subheadline.weight(.semibold))
                    .disabled(!isFormValid)
            }
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
