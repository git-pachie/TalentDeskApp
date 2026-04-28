import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    let emoji: String

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
            } else {
                Text(emoji)
                    .font(.system(size: 72))
            }
        }
        .task(id: url) {
            guard let url, image == nil else { return }
            await loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) async {
        isLoading = true
        defer { isLoading = false }

        // Check URLCache first
        let request = URLRequest(url: url)
        if let cached = URLCache.shared.cachedResponse(for: request),
           let uiImage = UIImage(data: cached.data) {
            self.image = uiImage
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let uiImage = UIImage(data: data) {
                // Store in cache
                let cachedResponse = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                self.image = uiImage
            }
        } catch {
            // Fall back to emoji (already shown)
        }
    }
}
