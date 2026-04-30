import SwiftUI
import MapKit

struct AddressItem: Identifiable {
    let id: UUID
    var label: String
    var address: String
    var isDefault: Bool
    var deliveryInstructions: String
    var contactNumber: String
    var latitude: Double
    var longitude: Double

    init(id: UUID = UUID(), label: String, address: String, isDefault: Bool, deliveryInstructions: String, contactNumber: String, latitude: Double, longitude: Double) {
        self.id = id
        self.label = label
        self.address = address
        self.isDefault = isDefault
        self.deliveryInstructions = deliveryInstructions
        self.contactNumber = contactNumber
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct AddressListView: View {
    @State private var addresses: [AddressItem] = []
    @State private var editingAddress: AddressItem?
    @State private var showingAddSheet = false
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(addresses) { item in
                    Button {
                        editingAddress = item
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(GroceryTheme.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.label)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundStyle(GroceryTheme.title)
                                    if item.isDefault {
                                        Text("Default")
                                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(GroceryTheme.primary.opacity(0.12))
                                            .foregroundStyle(GroceryTheme.primary)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(item.address)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(GroceryTheme.muted)
                                    .multilineTextAlignment(.leading)
                                if !item.deliveryInstructions.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "text.bubble")
                                            .font(.caption2)
                                        Text(item.deliveryInstructions)
                                            .font(.system(.caption2, design: .rounded))
                                    }
                                    .foregroundStyle(GroceryTheme.primary.opacity(0.7))
                                    .lineLimit(1)
                                }
                                if !item.contactNumber.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.caption2)
                                        Text(item.contactNumber)
                                            .font(.system(.caption2, design: .rounded))
                                    }
                                    .foregroundStyle(GroceryTheme.primary)
                                }
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
        .navigationTitle("Addresses")
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
        .sheet(item: $editingAddress) { address in
            AddressEditSheet(address: address) { updated in
                if let index = addresses.firstIndex(where: { $0.id == updated.id }) {
                    if updated.isDefault {
                        for i in addresses.indices { addresses[i].isDefault = false }
                    }
                    addresses[index] = updated
                }
                Task { await updateAddressOnServer(updated) }
            } onDelete: { toDelete in
                addresses.removeAll { $0.id == toDelete.id }
                Task { await deleteAddressOnServer(toDelete.id) }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddressEditSheet(address: nil) { newAddress in
                if newAddress.isDefault {
                    for i in addresses.indices { addresses[i].isDefault = false }
                }
                addresses.append(newAddress)
                Task { await saveAddressToServer(newAddress) }
            }
        }
        .task { await loadAddresses() }
        .refreshable { await loadAddresses() }
    }

    private func loadAddresses() async {
        guard APIClient.shared.isAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let dtos: [AddressDTO] = try await APIClient.shared.get("/api/addresses")
            addresses = dtos.map(\.asAddressItem)
        } catch {
            print("⚠️ Failed to load addresses: \(error)")
        }
    }

    private func saveAddressToServer(_ item: AddressItem) async {
        guard APIClient.shared.isAuthenticated else { return }
        let parts = item.address.components(separatedBy: ", ")
        let request = CreateAddressRequest(
            label: item.label,
            street: parts.first ?? item.address,
            city: parts.count > 1 ? parts[1] : "",
            province: parts.count > 2 ? parts[2] : "",
            zipCode: parts.count > 3 ? parts[3] : "",
            country: nil,
            deliveryInstructions: item.deliveryInstructions.isEmpty ? nil : item.deliveryInstructions,
            contactNumber: item.contactNumber.isEmpty ? nil : item.contactNumber,
            latitude: item.latitude != 0 ? item.latitude : nil,
            longitude: item.longitude != 0 ? item.longitude : nil,
            isDefault: item.isDefault
        )
        do {
            let _: AddressDTO = try await APIClient.shared.post("/api/addresses", body: request)
            await loadAddresses()
        } catch {
            print("⚠️ Failed to save address: \(error)")
        }
    }

    private func updateAddressOnServer(_ item: AddressItem) async {
        guard APIClient.shared.isAuthenticated else { return }
        let parts = item.address.components(separatedBy: ", ")
        let request = UpdateAddressRequest(
            label: item.label,
            street: parts.first ?? item.address,
            city: parts.count > 1 ? parts[1] : "",
            province: parts.count > 2 ? parts[2] : "",
            zipCode: parts.count > 3 ? parts[3] : "",
            country: nil,
            deliveryInstructions: item.deliveryInstructions.isEmpty ? nil : item.deliveryInstructions,
            contactNumber: item.contactNumber.isEmpty ? nil : item.contactNumber,
            latitude: item.latitude != 0 ? item.latitude : nil,
            longitude: item.longitude != 0 ? item.longitude : nil,
            isDefault: item.isDefault
        )
        do {
            let _: AddressDTO = try await APIClient.shared.put("/api/addresses/\(item.id.uuidString)", body: request)
        } catch {
            print("⚠️ Failed to update address: \(error)")
        }
    }

    private func deleteAddressOnServer(_ id: UUID) async {
        guard APIClient.shared.isAuthenticated else { return }
        do {
            try await APIClient.shared.delete("/api/addresses/\(id.uuidString)")
        } catch {
            print("⚠️ Failed to delete address: \(error)")
        }
    }
}

// MARK: - Address Edit Sheet

struct AddressEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var label: String
    @State private var address: String
    @State private var isDefault: Bool
    @State private var deliveryInstructions: String
    @State private var contactNumber: String
    @State private var mapPosition: MapCameraPosition
    @State private var pinCoordinate: CLLocationCoordinate2D
    @State private var showingDeleteAlert = false
    @State private var isGeocodingAddress = false

    private let existingID: UUID?
    private let onSave: (AddressItem) -> Void
    private var onDelete: ((AddressItem) -> Void)?
    private let isNew: Bool

    init(address item: AddressItem?, onSave: @escaping (AddressItem) -> Void, onDelete: ((AddressItem) -> Void)? = nil) {
        self.existingID = item?.id
        self.isNew = item == nil
        self._label = State(initialValue: item?.label ?? "")
        self._address = State(initialValue: item?.address ?? "")
        self._isDefault = State(initialValue: item?.isDefault ?? false)
        self._deliveryInstructions = State(initialValue: item?.deliveryInstructions ?? "")
        self._contactNumber = State(initialValue: item?.contactNumber ?? "")

        let lat = item?.latitude ?? 40.7128
        let lon = item?.longitude ?? -74.0060
        self._pinCoordinate = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lon))
        self._mapPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var isValid: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Map
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tap to Pin Location", systemImage: "map.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.primary)

                        MapReader { proxy in
                            Map(position: $mapPosition) {
                                Annotation("", coordinate: pinCoordinate) {
                                    VStack(spacing: 0) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.largeTitle)
                                            .foregroundStyle(GroceryTheme.badge)
                                        Image(systemName: "arrowtriangle.down.fill")
                                            .font(.caption2)
                                            .foregroundStyle(GroceryTheme.badge)
                                            .offset(y: -4)
                                    }
                                }
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onTapGesture { position in
                                if let coordinate = proxy.convert(position, from: .local) {
                                    pinCoordinate = coordinate
                                    mapPosition = .region(MKCoordinateRegion(
                                        center: coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    ))
                                    reverseGeocode(coordinate)
                                }
                            }
                        }

                        if isGeocodingAddress {
                            HStack(spacing: 6) {
                                ProgressView().scaleEffect(0.7)
                                Text("Getting address...")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(GroceryTheme.muted)
                            }
                        } else {
                            Text("Tap on the map to set delivery pin")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(GroceryTheme.muted)
                        }
                    }
                    .padding(14)
                    .background(GroceryTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                    // Address fields
                    VStack(alignment: .leading, spacing: 14) {
                        Label(isNew ? "New Address" : "Edit Address", systemImage: "mappin.circle.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.primary)

                        inputField(label: "Label", placeholder: "e.g. Home, Office", text: $label)
                        inputField(label: "Address", placeholder: "Street, city, state, zip", text: $address)

                        // Delivery instructions
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delivery Instructions")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(GroceryTheme.muted)
                            TextField("e.g. Leave at front door, ring bell twice", text: $deliveryInstructions, axis: .vertical)
                                .font(.system(.subheadline, design: .rounded))
                                .lineLimit(2...4)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        // Contact number
                        inputField(label: "Contact Number", placeholder: "e.g. +1 (555) 123-4567", text: $contactNumber)
                            .keyboardType(.phonePad)

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

                    // Save
                    Button {
                        let item = AddressItem(
                            id: existingID ?? UUID(),
                            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                            isDefault: isDefault,
                            deliveryInstructions: deliveryInstructions.trimmingCharacters(in: .whitespacesAndNewlines),
                            contactNumber: contactNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                            latitude: pinCoordinate.latitude,
                            longitude: pinCoordinate.longitude
                        )
                        onSave(item)
                        dismiss()
                    } label: {
                        Text("Save Address")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isValid ? GroceryTheme.primary : Color(.systemGray4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!isValid)

                    // Delete
                    if !isNew {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Text("Delete Address")
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
            .navigationTitle(isNew ? "Add Address" : "Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Delete Address", isPresented: $showingDeleteAlert) {
                Button("Yes", role: .destructive) {
                    onDelete?(AddressItem(id: existingID ?? UUID(), label: label, address: address, isDefault: isDefault, deliveryInstructions: deliveryInstructions, contactNumber: contactNumber, latitude: pinCoordinate.latitude, longitude: pinCoordinate.longitude))
                    dismiss()
                }
                Button("No", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this address?")
            }
        }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isGeocodingAddress = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            isGeocodingAddress = false
            guard let placemark = placemarks?.first else { return }

            var parts: [String] = []
            if let street = placemark.thoroughfare {
                if let number = placemark.subThoroughfare {
                    parts.append("\(number) \(street)")
                } else {
                    parts.append(street)
                }
            }
            if let city = placemark.locality { parts.append(city) }
            if let state = placemark.administrativeArea { parts.append(state) }
            if let zip = placemark.postalCode { parts.append(zip) }

            if !parts.isEmpty {
                address = parts.joined(separator: ", ")
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
        AddressListView()
    }
}
