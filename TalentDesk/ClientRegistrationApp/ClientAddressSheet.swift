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
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Address", systemImage: "mappin.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)

                    TextField("Street, city, state, zip", text: addressBinding, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.darkText)
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        )
                }
                .dashboardCard()
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()
            }
            .background(AppTheme.accent.opacity(0.2))
            .navigationTitle("Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveAddress)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
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
