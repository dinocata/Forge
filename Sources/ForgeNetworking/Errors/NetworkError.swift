import Foundation

public enum NetworkError: Error {
    case url(URLError.Code)
    case encoding(EncodingError)
    case decoding(DecodingError)
    case invalidResponse
    case unknown(Error)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .url(let code): "URLError: \(code)"
        case .encoding(let error): error.localizedDescription
        case .decoding(let error): error.localizedDescription
        case .invalidResponse: "Invalid HTTP response"
        case .unknown(let error): error.localizedDescription
        }
    }
}
