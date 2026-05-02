import Foundation

// MARK: - API Configuration

enum APIConfig {
    // Change this to your server's IP/hostname
    // Use "https://192.168.7.136:5002" for iOS Simulator on the same machine
    // Use "https://<your-mac-ip>:5001" for a physical device
    static let baseURL = "https://127.0.0.1:5001"
    //static let baseURL = "https://sandboxapi.sansharecab.com"

    static var base: URL {
        URL(string: baseURL)!
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case cancelled
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case badRequest(String)
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .cancelled: "Request cancelled."
        case .invalidURL: "Invalid URL"
        case .unauthorized: "Session expired. Please log in again."
        case .forbidden: "You don't have permission for this action."
        case .notFound: "Resource not found."
        case .badRequest(let msg): msg
        case .serverError(let code): "Server error (\(code))"
        case .decodingError(let err): "Data error: \(err.localizedDescription)"
        case .networkError(let err): err.localizedDescription
        case .unknown: "An unknown error occurred."
        }
    }

    var isCancellation: Bool {
        switch self {
        case .cancelled:
            return true
        case .networkError(let err):
            if err is CancellationError {
                return true
            }
            if let urlError = err as? URLError, urlError.code == .cancelled {
                return true
            }
            let nsError = err as NSError
            return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
        default:
            return false
        }
    }
}

// MARK: - Paged Result

struct PagedResult<T: Decodable>: Decodable {
    let items: [T]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

// MARK: - API Client

final class APIClient: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    static let shared = APIClient()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    /// Exposed for multipart uploads that need the same SSL trust as the main session
    var trustedSession: URLSession { session }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }

            // Try without fractional seconds
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }

            // Try common .NET format
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
                df.dateFormat = fmt
                if let date = df.date(from: str) { return date }
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // Allow self-signed certs in development (session-level)
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.performDefaultHandling, nil)
    }

    // Allow self-signed certs in development (task-level — used by async data(for:))
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.performDefaultHandling, nil)
    }

    // MARK: - Token Management

    private var token: String? {
        get { UserDefaults.standard.string(forKey: "jwt_token") }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: "jwt_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "jwt_token")
            }
        }
    }

    /// True only if a token exists AND it has not expired
    var isAuthenticated: Bool {
        guard let token else { return false }
        return !isTokenExpired(token)
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }

    // MARK: - Token Expiry Check

    private func isTokenExpired(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return true }

        // Base64url decode the payload
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Pad to multiple of 4
        let remainder = base64.count % 4
        if remainder > 0 { base64 += String(repeating: "=", count: 4 - remainder) }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return true // Can't decode → treat as expired
        }

        return Date(timeIntervalSince1970: exp) < Date()
    }

    // MARK: - Request Building

    private func buildRequest(
        path: String,
        method: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        cachePolicy: NSURLRequest.CachePolicy? = nil
    ) throws -> URLRequest {
        var components = URLComponents(url: APIConfig.base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        if let cachePolicy {
            request.cachePolicy = cachePolicy
        }
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let anonymousAuthEndpoints = [
            "/api/auth/login",
            "/api/auth/register",
            "/api/auth/verify-email"
        ]

        if let token, !anonymousAuthEndpoints.contains(path) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if method == "GET" {
            request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
            request.setValue("no-cache", forHTTPHeaderField: "Pragma")
            request.setValue("0", forHTTPHeaderField: "Expires")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    // MARK: - Execute

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if error is CancellationError {
                throw APIError.cancelled
            }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw APIError.cancelled
            }
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            clearToken() // Token expired — force re-login
            NotificationCenter.default.post(name: .apiUnauthorized, object: nil)
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 400:
            if let body = try? decoder.decode(ErrorBody.self, from: data), let msg = body.error {
                throw APIError.badRequest(msg)
            }
            if let body = try? decoder.decode(ErrorsBody.self, from: data),
               let first = body.errors?.first {
                throw APIError.badRequest(first)
            }
            throw APIError.badRequest("Bad request")
        default:
            throw APIError.serverError(http.statusCode)
        }
    }

    private func executeNoContent(_ request: URLRequest) async throws {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if error is CancellationError {
                throw APIError.cancelled
            }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw APIError.cancelled
            }
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 400:
            if let body = try? decoder.decode(ErrorBody.self, from: data), let msg = body.error {
                throw APIError.badRequest(msg)
            }
            if let body = try? decoder.decode(ErrorsBody.self, from: data),
               let first = body.errors?.first {
                throw APIError.badRequest(first)
            }
            throw APIError.badRequest("Bad request")
        default:
            throw APIError.serverError(http.statusCode)
        }
    }

    // MARK: - Public Methods

    func get<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        let request = try buildRequest(path: path, method: "GET", queryItems: query)
        return try await execute(request)
    }

    func getUncached<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        let request = try buildRequest(
            path: path,
            method: "GET",
            queryItems: query,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        return try await execute(request)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let request = try buildRequest(path: path, method: "POST", body: body)
        return try await execute(request)
    }

    func postNoBody<T: Decodable>(_ path: String) async throws -> T {
        let request = try buildRequest(path: path, method: "POST")
        return try await execute(request)
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let request = try buildRequest(path: path, method: "PUT", body: body)
        return try await execute(request)
    }

    func putNoContent(_ path: String) async throws {
        let request = try buildRequest(path: path, method: "PUT")
        try await executeNoContent(request)
    }

    func delete(_ path: String) async throws {
        let request = try buildRequest(path: path, method: "DELETE")
        try await executeNoContent(request)
    }
}

// MARK: - Error Body

private struct ErrorBody: Decodable {
    let error: String?
}

private struct ErrorsBody: Decodable {
    let errors: [String]?
}

// MARK: - Notification Names

extension Notification.Name {
    static let apiUnauthorized = Notification.Name("APIClientUnauthorized")
}
