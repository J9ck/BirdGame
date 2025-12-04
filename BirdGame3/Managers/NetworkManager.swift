//
//  NetworkManager.swift
//  BirdGame3
//
//  Network manager with error handling and retry logic
//

import Foundation
import Network

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case decodingError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Failed to process server response."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your Wi-Fi or cellular connection and try again."
        case .timeout:
            return "The server might be busy. Wait a moment and try again."
        case .serverError:
            return "Our servers are experiencing issues. We're working on it!"
        case .invalidResponse, .decodingError:
            return "Please update to the latest version of Bird Game 3."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError:
            return true
        case .invalidResponse, .decodingError, .unknown:
            return false
        }
    }
}

// MARK: - Network Status

enum NetworkStatus {
    case connected
    case disconnected
    case unknown
}

// MARK: - Retry Configuration

struct RetryConfiguration {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )
    
    static let aggressive = RetryConfiguration(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 30.0,
        multiplier: 2.0
    )
    
    func delay(for attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(multiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Network Manager

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // MARK: - Published Properties
    
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var isOnline: Bool = true
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private let session: URLSession
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.networkStatus = path.status == .satisfied ? .connected : .disconnected
                
                if path.status == .satisfied {
                    NotificationCenter.default.post(name: .networkConnected, object: nil)
                } else {
                    NotificationCenter.default.post(name: .networkDisconnected, object: nil)
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    // MARK: - Request Methods
    
    func request<T: Decodable>(
        _ url: URL,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String]? = nil,
        retryConfig: RetryConfiguration = .default
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...retryConfig.maxAttempts {
            do {
                return try await performRequest(url, method: method, body: body, headers: headers)
            } catch let error as NetworkError {
                lastError = error
                
                if !error.isRetryable || attempt == retryConfig.maxAttempts {
                    throw error
                }
                
                // Wait before retrying with exponential backoff
                let delay = retryConfig.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Track retry attempt
                AnalyticsManager.shared.trackEvent(
                    "network_retry",
                    category: .error,
                    parameters: [
                        "attempt": String(attempt),
                        "error": error.localizedDescription ?? "unknown"
                    ]
                )
            } catch {
                throw NetworkError.unknown(error)
            }
        }
        
        throw lastError ?? NetworkError.unknown(NSError(domain: "Unknown", code: -1))
    }
    
    private func performRequest<T: Decodable>(
        _ url: URL,
        method: String,
        body: Data?,
        headers: [String: String]?
    ) async throws -> T {
        // Check connectivity first
        guard isOnline else {
            throw NetworkError.noConnection
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bird Game 3/\(Bundle.main.appVersion)", forHTTPHeaderField: "User-Agent")
        
        // Custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError
            }
        case 408, 504:
            throw NetworkError.timeout
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Decodable>(_ url: URL) async throws -> T {
        try await request(url, method: "GET")
    }
    
    func post<T: Decodable, B: Encodable>(_ url: URL, body: B) async throws -> T {
        let bodyData = try JSONEncoder().encode(body)
        return try await request(url, method: "POST", body: bodyData)
    }
    
    // MARK: - Health Check
    
    func checkServerHealth() async -> Bool {
        guard let url = URL(string: "https://api.birdgame3.com/health") else {
            return false
        }
        
        do {
            let _: EmptyResponse = try await get(url)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Empty Response

struct EmptyResponse: Decodable {}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkConnected = Notification.Name("birdgame3_networkConnected")
    static let networkDisconnected = Notification.Name("birdgame3_networkDisconnected")
}

// MARK: - Error Alert View Modifier

struct NetworkErrorAlert: ViewModifier {
    @Binding var error: NetworkError?
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Connection Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                if let error = error, error.isRetryable, let onRetry = onRetry {
                    Button("Retry") {
                        self.error = nil
                        onRetry()
                    }
                }
                Button("OK", role: .cancel) {
                    self.error = nil
                }
            } message: {
                if let error = error {
                    Text("\(error.localizedDescription ?? "Unknown error")\n\n\(error.recoverySuggestion ?? "")")
                }
            }
    }
}

extension View {
    func networkErrorAlert(error: Binding<NetworkError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(NetworkErrorAlert(error: error, onRetry: onRetry))
    }
}
