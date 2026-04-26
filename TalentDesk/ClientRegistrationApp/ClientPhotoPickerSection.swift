import PhotosUI
import SwiftUI

struct ClientPhotoPickerSection: View {
    @Binding var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        Section {
            HStack(spacing: 14) {
                ClientPhotoView(photoData: photoData, size: 60)

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "camera.fill")
                            .font(.subheadline)
                    }

                    if photoData != nil {
                        Button("Remove", role: .destructive) {
                            photoData = nil
                            selectedItem = nil
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .task(id: selectedItem) {
            guard let selectedItem else { return }
            photoData = try? await selectedItem.loadTransferable(type: Data.self)
        }
    }
}
