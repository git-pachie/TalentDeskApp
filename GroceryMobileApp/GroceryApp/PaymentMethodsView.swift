import SwiftUI

struct PaymentItem: Identifiable {
    let id = UUID()
    var name: String
    var detail: String
    var icon: String
    var isDefault: Bool
}

struct PaymentMethodsView: View {
    @State private var methods: [PaymentItem] = [
        PaymentItem(name: "Credit Card", detail: "•••• •••• •••• 4242", icon: "creditcard.fill", isDefault: true),
        PaymentItem(name: "Debit Card", detail: "•••• •••• •••• 8910", icon: "creditcard", isDefault: false),
        PaymentItem(name: "Apple Pay", detail: "Connected", icon: "apple.logo", isDefault: false),
        PaymentItem(name: "Cash on Delivery", detail: "Pay when delivered", icon: "banknote.fill", isDefault: false),
    ]
    @State private var editingMethod: PaymentItem?
    @State private var showingAddSheet = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(methods) { method in
                    Button {
                        editingMethod = method
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: method.icon)
                                .font(.title3)
                                .foregroundStyle(GroceryTheme.primary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(method.name)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundStyle(GroceryTheme.title)
                                    if method.isDefault {
                                        Text("Default")
                                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(GroceryTheme.primary.opacity(0.12))
                                            .foregroundStyle(GroceryTheme.primary)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(method.detail)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(GroceryTheme.muted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(GroceryTheme.muted)
                        }
                        .padding(14)
                        .background(GroceryTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(GroceryTheme.background)
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(GroceryTheme.primary)
                }
            }
        }
        .sheet(item: $editingMethod) { method in
            PaymentEditSheet(method: method) { updated in
                if let index = methods.firstIndex(where: { $0.id == updated.id }) {
                    if updated.isDefault {
                        for i in methods.indices { methods[i].isDefault = false }
                    }
                    methods[index] = updated
                }
            } onDelete: { toDelete in
                methods.removeAll { $0.id == toDelete.id }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            PaymentEditSheet(method: nil) { newMethod in
                if newMethod.isDefault {
                    for i in methods.indices { methods[i].isDefault = false }
                }
                methods.append(newMethod)
            }
        }
    }
}

// MARK: - Payment Edit Sheet

struct PaymentEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var detail: String
    @State private var isDefault: Bool
    @State private var showingDeleteAlert = false

    private let existingID: UUID?
    private let onSave: (PaymentItem) -> Void
    private var onDelete: ((PaymentItem) -> Void)?
    private let isNew: Bool

    private let iconOptions = [
        ("creditcard.fill", "Credit Card"),
        ("creditcard", "Debit Card"),
        ("apple.logo", "Apple Pay"),
        ("banknote.fill", "Cash"),
    ]
    @State private var selectedIcon: String

    init(method: PaymentItem?, onSave: @escaping (PaymentItem) -> Void, onDelete: ((PaymentItem) -> Void)? = nil) {
        self.existingID = method?.id
        self.isNew = method == nil
        self._name = State(initialValue: method?.name ?? "")
        self._detail = State(initialValue: method?.detail ?? "")
        self._isDefault = State(initialValue: method?.isDefault ?? false)
        self._selectedIcon = State(initialValue: method?.icon ?? "creditcard.fill")
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(isNew ? "New Payment Method" : "Edit Payment Method", systemImage: "creditcard.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.primary)

                        // Icon picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Type")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(GroceryTheme.muted)
                            HStack(spacing: 10) {
                                ForEach(iconOptions, id: \.0) { icon, label in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: icon)
                                                .font(.title3)
                                            Text(label)
                                                .font(.system(.caption2, design: .rounded))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedIcon == icon ? GroceryTheme.primaryLight : Color(.systemGray6))
                                        .foregroundStyle(selectedIcon == icon ? GroceryTheme.primary : GroceryTheme.muted)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(selectedIcon == icon ? GroceryTheme.primary : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        inputField(label: "Name", placeholder: "e.g. My Visa Card", text: $name)
                        inputField(label: "Details", placeholder: "e.g. •••• 4242", text: $detail)

                        Toggle(isOn: $isDefault) {
                            Text("Set as default")
                                .font(.system(.subheadline, design: .rounded))
                        }
                        .tint(GroceryTheme.primary)
                    }
                    .padding(14)
                    .background(GroceryTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                    Button {
                        let item = PaymentItem(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                               detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                                               icon: selectedIcon,
                                               isDefault: isDefault)
                        onSave(item)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isValid ? GroceryTheme.primary : Color(.systemGray4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!isValid)

                    if !isNew {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Text("Delete Payment Method")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(GroceryTheme.badge.opacity(0.12))
                                .foregroundStyle(GroceryTheme.badge)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(16)
            }
            .background(GroceryTheme.background)
            .navigationTitle(isNew ? "Add Payment" : "Edit Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Delete Payment Method", isPresented: $showingDeleteAlert) {
                Button("Yes", role: .destructive) {
                    onDelete?(PaymentItem(name: name, detail: detail, icon: selectedIcon, isDefault: isDefault))
                    dismiss()
                }
                Button("No", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this payment method?")
            }
        }
    }

    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(GroceryTheme.muted)
            TextField(placeholder, text: text)
                .font(.system(.subheadline, design: .rounded))
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        PaymentMethodsView()
    }
}
