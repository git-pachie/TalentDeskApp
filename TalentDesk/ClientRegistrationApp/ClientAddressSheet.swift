import SwiftUI

struct ClientAddressSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var clientStore: ClientStore
    @State private var draftClient: ClientRegistration

    init(clientStore: ClientStore, client: ClientRegistration) {
        self.clientStore = clientStore
        _draftClient = State(initialValue: client)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Address") {
                    TextField("Street, city, state, zip", text: addressBinding, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.subheadline)
                }
            }
            .navigationTitle("Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveAddress)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var addressBinding: Binding<String> {
        Binding(
            get: { draftClient.address ?? "" },
            set: { draftClient.address = $0 }
        )
    }

    private func saveAddress() {
        let trimmed = draftClient.address?.trimmingCharacters(in: .whitespacesAndNewlines)
        draftClient.address = trimmed?.isEmpty == true ? nil : trimmed
        clientStore.update(draftClient)
        dismiss()
    }
}

#Preview {
    let store = ClientStore()
    let client = ClientRegistration(
        firstName: "Jane", lastName: "Doe", age: 29,
        mobile: "5551234567", email: "jane@example.com",
        address: "123 Main St\nMiami, FL 33101"
    )
    store.add(client)
    return ClientAddressSheet(clientStore: store, client: client)
}
