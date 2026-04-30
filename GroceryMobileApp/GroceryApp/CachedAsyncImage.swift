import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    let emoji: String

    @State private var image: UIImage?
    @State private var isLoading = false

    /// Shared session that trusts self-signed dev certificates (same as APIClient)
    private static let imageSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config, delegate: ImageSessionDelegate.shared, delegateQueue: nil)
    }()

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
            guard let url else { return }
            // Reset when URL changes so the new image loads
            if image != nil { image = nil }
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
            let (data, response) = try await Self.imageSession.data(for: request)
            if let uiImage = UIImage(data: data) {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                self.image = uiImage
            }
        } catch {
            print("⚠️ [Image] Failed to load \(url): \(error.localizedDescription)")
        }
    }
}

/// Delegate that accepts self-signed certificates for image loading in development
private final class ImageSessionDelegate: NSObject, URLSessionDelegate {
    static let shared = ImageSessionDelegate()

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.performDefaultHandling, nil)
    }
}
