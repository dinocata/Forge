import Foundation

/// Describes an endpoint independently of the transport implementation.
public protocol Target: Sendable {
    var path: String { get }
    var method: HttpMethod { get }
    var queryItems: [URLQueryItem] { get }
    var bodyData: (any Encodable)? { get }
    var additionalHeaders: [String: String] { get }
    var isAuthenticationRequired: Bool { get }
    var ignoredStatusCodes: Set<HttpStatusCode> { get }
}

public extension Target {
    var queryItems: [URLQueryItem] { [] }
    var bodyData: (any Encodable)? { nil }
    var additionalHeaders: [String: String] { [:] }
    var isAuthenticationRequired: Bool { false }
    var ignoredStatusCodes: Set<HttpStatusCode> { [] }

    var requestDescription: String {
        var components = URLComponents()
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return "\(method.rawValue) \(components.string ?? path)"
    }
}
