import SwiftUI

struct ClientPhotoView: View {
    let photoData: Data?
    var size: CGFloat = 72

    var body: some View {
        Group {
            if let photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 0.5)
        }
    }
}

#Preview {
    ClientPhotoView(photoData: nil)
}
