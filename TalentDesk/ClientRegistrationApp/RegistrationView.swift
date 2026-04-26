import SwiftUI

struct RegistrationView: View {
    @Bindable var clientStore: ClientStore
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = ""
    @State private var mobile = ""
    @State private var email = ""
    @State private var photoData: Data?
    @State private var submittedClient: ClientRegistration?
    @State private var showingSubmissionAlert = false

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(age) != nil &&
        mobile.trimmingCharacters(in: .whitespacesAndNewlines).count >= 7 &&
        email.contains("@")
    }

    var body: some View {
        NavigationStack {
            Form {
                ClientPhotoPickerSection(photoData: $photoData)

                Section {
                    TextField("First Name", text: $firstName)
                        .textInputAutocapitalization(.words)
                    TextField("Last Name", text: $lastName)
                        .textInputAutocapitalization(.words)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Mobile", text: $mobile)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Label("Client Information", systemImage: "person.text.rectangle")
                }

                Section {
                    Button(action: submitClient) {
                        HStack {
                            Spacer()
                            Label("Register Client", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }

                if let submittedClient {
                    Section("Last Registered") {
                        LabeledContent("Name", value: "\(submittedClient.firstName) \(submittedClient.lastName)")
                        LabeledContent("Age", value: "\(submittedClient.age)")
                        LabeledContent("Email", value: submittedClient.email)
                    }
                }
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.large)
            .alert("Client Registered", isPresented: $showingSubmissionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let submittedClient {
                    Text("\(submittedClient.firstName) \(submittedClient.lastName) was saved.")
                }
            }
        }
    }

    private func submitClient() {
        guard let parsedAge = Int(age) else { return }
        let client = ClientRegistration(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            age: parsedAge,
            mobile: mobile.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData
        )
        clientStore.add(client)
        submittedClient = client
        showingSubmissionAlert = true
        resetForm()
    }

    private func resetForm() {
        firstName = ""
        lastName = ""
        age = ""
        mobile = ""
        email = ""
        photoData = nil
    }
}

#Preview {
    RegistrationView(clientStore: ClientStore())
}
