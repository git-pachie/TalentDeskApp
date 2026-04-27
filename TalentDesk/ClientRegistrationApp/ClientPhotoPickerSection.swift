import PhotosUI
import SwiftUI

struct ClientPhotoPickerSection: View {
    @Binding var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 14) {
            ClientPhotoView(photoData: photoData, size: 60)

            VStack(alignment: .leading, spacing: 8) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "camera.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                }

                if photoData != nil {
                    Button("Remove", role: .destructive) {
                        photoData = nil
                        selectedItem = nil
                    }
                    .font(.caption)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: selectedItem) {
            guard let selectedItem else { return }
            photoData = try? await selectedItem.loadTransferable(type: Data.self)
        }
    }
}
