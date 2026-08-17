import Foundation

public enum HttpMethod: String, Sendable {
    case head = "HEAD"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
