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
        ScrollView {
            VStack(spacing: 0) {
                AppScreenHeader(title: "Add Client", subtitle: "Register a new client profile")

                VStack(spacing: 16) {
                    // Photo
                    ClientPhotoPickerSection(photoData: $photoData)
                        .dashboardCard()

                    // Form fields
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Client Information", systemImage: "person.text.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                        formField(placeholder: "First Name", text: $firstName)
                            .textInputAutocapitalization(.words)
                        formField(placeholder: "Last Name", text: $lastName)
                            .textInputAutocapitalization(.words)
                        formField(placeholder: "Age", text: $age)
                            .keyboardType(.numberPad)
                        formField(placeholder: "Mobile", text: $mobile)
                            .keyboardType(.phonePad)
                        formField(placeholder: "Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .dashboardCard()

                    // Submit button
                    Button(action: submitClient) {
                        HStack {
                            Spacer()
                            Label("Register Client", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.5)

                    // Last registered
                    if let submittedClient {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Last Registered", systemImage: "checkmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)

                            HStack {
                                Text("Name")
                                    .foregroundStyle(AppTheme.subtitleText)
                                Spacer()
                                Text("\(submittedClient.firstName) \(submittedClient.lastName)")
                                    .foregroundStyle(AppTheme.darkText)
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Age")
                                    .foregroundStyle(AppTheme.subtitleText)
                                Spacer()
                                Text("\(submittedClient.age)")
                                    .foregroundStyle(AppTheme.darkText)
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Email")
                                    .foregroundStyle(AppTheme.subtitleText)
                                Spacer()
                                Text(submittedClient.email)
                                    .foregroundStyle(AppTheme.darkText)
                            }
                            .font(.subheadline)
                        }
                        .dashboardCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(AppTheme.surface)
        .ignoresSafeArea(edges: .top)
        .alert("Client Registered", isPresented: $showingSubmissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let submittedClient {
                Text("\(submittedClient.firstName) \(submittedClient.lastName) was saved.")
            }
        }
    }

    private func formField(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
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
