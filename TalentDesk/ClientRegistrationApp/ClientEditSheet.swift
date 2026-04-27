import SwiftUI

struct ClientEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let clientStore: ClientStore
    private let clientID: UUID

    @State private var firstName: String
    @State private var lastName: String
    @State private var age: String
    @State private var mobile: String
    @State private var email: String
    @State private var photoData: Data?

    init(clientStore: ClientStore, client: ClientRegistration) {
        self.clientStore = clientStore
        self.clientID = client.id
        self._firstName = State(initialValue: client.firstName)
        self._lastName = State(initialValue: client.lastName)
        self._age = State(initialValue: "\(client.age)")
        self._mobile = State(initialValue: client.mobile)
        self._email = State(initialValue: client.email)
        self._photoData = State(initialValue: client.photoData)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    // Photo
                    ClientPhotoPickerSection(photoData: $photoData)
                        .padding(14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(.separator), lineWidth: 1)
                        )

                    inputBox(label: "First Name", text: $firstName)
                        .textInputAutocapitalization(.words)
                    inputBox(label: "Last Name", text: $lastName)
                        .textInputAutocapitalization(.words)
                    inputBox(label: "Age", text: $age)
                        .keyboardType(.numberPad)
                    inputBox(label: "Mobile", text: $mobile)
                        .keyboardType(.phonePad)
                    inputBox(label: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button(action: save) {
                        Text("Save")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func inputBox(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .font(.body)
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
    }

    private func save() {
        guard var client = clientStore.client(withID: clientID) else { return }
        client.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        client.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        client.age = Int(age) ?? client.age
        client.mobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        client.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        client.photoData = photoData
        clientStore.update(client)
        dismiss()
    }
}
