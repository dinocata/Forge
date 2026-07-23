import Foundation

public extension URLRequest {
    init(baseURL: URL, target: some Target, bodyEncoder: JSONEncoder = JSONEncoder()) throws {
        guard let url = URL(string: target.path, relativeTo: baseURL), var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        if !target.queryItems.isEmpty {
            components.queryItems = target.queryItems
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        guard let resolvedURL = components.url else { throw URLError(.badURL) }
        self.init(url: resolvedURL)
        httpMethod = target.method.rawValue
        if let body = target.bodyData { httpBody = try bodyEncoder.encode(body) }
    }

    var cURL: String { cURLString() }
    var cURLCompact: String { cURL.replacingOccurrences(of: " \\\\n    ", with: " ") }

    private static let sensitiveHeaderFields: Set<String> = ["authorization", "cookie", "x-api-key", "x-auth-token"]

    private func cURLString() -> String {
        var components = ["curl -v"]
        if let httpMethod { components.append("-X \(httpMethod)") }
        for (key, value) in (allHTTPHeaderFields ?? [:]).sorted(by: { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }) {
            let safeValue: String
            if Self.sensitiveHeaderFields.contains(key.lowercased()) {
                let parts = value.split(separator: " ", maxSplits: 1)
                safeValue = parts.count == 2 ? "\(parts[0]) <redacted>" : "<redacted>"
            } else {
                safeValue = value.replacingOccurrences(of: "\"", with: "\\\"")
            }
            components.append("-H \"\(key): \(safeValue)\"")
        }
        if let httpBody, !httpBody.isEmpty { components.append("-d \"<redacted body: \(httpBody.count) bytes>\"") }
        if let url { components.append("\"\(url.absoluteString.replacingOccurrences(of: "\"", with: "\\\""))\"") }
        return components.joined(separator: " \\\\n    ")
    }
}
