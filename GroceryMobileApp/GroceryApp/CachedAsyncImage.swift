import CryptoKit
import SwiftUI

struct CachedAsyncImage: View {
    enum DisplayMode {
        case fill
        case fit
    }

    let url: URL?
    let emoji: String
    let lastModified: Date?
    let displayMode: DisplayMode

    @State private var image: UIImage?
    @State private var isLoading = false

    init(url: URL?, emoji: String, lastModified: Date? = nil, displayMode: DisplayMode = .fill) {
        self.url = url
        self.emoji = emoji
        self.lastModified = lastModified
        self.displayMode = displayMode
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .modifier(ImageDisplayModeModifier(displayMode: displayMode))
            } else if isLoading {
                ProgressView()
            } else {
                Text(emoji)
                    .font(.system(size: 72))
            }
        }
        .task(id: cacheTaskKey) {
            guard let url else { return }
            image = nil
            await loadImage(from: url)
        }
    }

    private var cacheTaskKey: String {
        "\(url?.absoluteString ?? "nil")|\(lastModified?.timeIntervalSince1970 ?? 0)"
    }

    private func loadImage(from url: URL) async {
        isLoading = true
        defer { isLoading = false }

        if let cachedImage = await ProductImageDiskCache.shared.loadImage(for: url, lastModified: lastModified) {
            image = cachedImage
            return
        }

        do {
            let (data, _) = try await APIClient.shared.trustedSession.data(for: URLRequest(url: url))
            guard let uiImage = UIImage(data: data) else { return }
            await ProductImageDiskCache.shared.store(data: data, for: url, lastModified: lastModified)
            image = uiImage
        } catch {
            print("⚠️ [Image] Failed to load \(url): \(error.localizedDescription)")
        }
    }
}

private struct ImageDisplayModeModifier: ViewModifier {
    let displayMode: CachedAsyncImage.DisplayMode

    func body(content: Content) -> some View {
        switch displayMode {
        case .fill:
            content.scaledToFill()
        case .fit:
            content.scaledToFit()
        }
    }
}

actor ProductImageDiskCache {
    static let shared = ProductImageDiskCache()

    private struct CacheEntry: Codable {
        let fileName: String
        let lastModified: Date?
    }

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let metadataURL: URL
    private var metadata: [String: CacheEntry] = [:]
    private var didLoadMetadata = false

    init() {
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        cacheDirectory = baseDirectory.appendingPathComponent("ProductImageCache", isDirectory: true)
        metadataURL = cacheDirectory.appendingPathComponent("metadata.json")
    }

    func loadImage(for url: URL, lastModified: Date?) async -> UIImage? {
        await ensureLoaded()
        let key = url.absoluteString

        guard let entry = metadata[key] else { return nil }
        if let lastModified, entry.lastModified != lastModified {
            removeEntry(for: key, entry: entry)
            return nil
        }

        let fileURL = cacheDirectory.appendingPathComponent(entry.fileName)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            removeEntry(for: key, entry: entry)
            return nil
        }

        return image
    }

    func store(data: Data, for url: URL, lastModified: Date?) async {
        await ensureLoaded()
        let key = url.absoluteString
        let fileName = hashedFileName(for: key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: fileURL, options: .atomic)
            metadata[key] = CacheEntry(fileName: fileName, lastModified: lastModified)
            try persistMetadata()
        } catch {
            print("⚠️ [ImageCache] Failed to store \(url): \(error.localizedDescription)")
        }
    }

    private func ensureLoaded() async {
        guard !didLoadMetadata else { return }
        didLoadMetadata = true

        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            guard fileManager.fileExists(atPath: metadataURL.path) else { return }
            let data = try Data(contentsOf: metadataURL)
            metadata = try JSONDecoder().decode([String: CacheEntry].self, from: data)
        } catch {
            metadata = [:]
        }
    }

    private func persistMetadata() throws {
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL, options: .atomic)
    }

    private func removeEntry(for key: String, entry: CacheEntry) {
        let fileURL = cacheDirectory.appendingPathComponent(entry.fileName)
        try? fileManager.removeItem(at: fileURL)
        metadata.removeValue(forKey: key)
        try? persistMetadata()
    }

    private func hashedFileName(for key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
