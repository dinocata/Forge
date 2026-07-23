import Foundation

public struct APIError<Response: Decodable & Sendable>: LocalizedError, Sendable {
    public let statusCode: HttpStatusCode
    public let response: Response?

    public init(_ statusCode: HttpStatusCode, response: Response? = nil) {
        self.statusCode = statusCode
        self.response = response
    }

    public var errorDescription: String? {
        guard let response else { return statusCode.description }
        return "\(statusCode.description) - \(response)"
    }
}

public typealias DefaultApiError = APIError<EmptyCodable>
