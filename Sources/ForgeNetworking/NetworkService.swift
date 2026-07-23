
import ForgeCore
import Foundation

// swiftlint:disable file_length
public final class NetworkService<APIErrorResponse: Decodable & Sendable>: Sendable {

    public struct Config: Sendable {
        public let baseURL: URL
        public let defaultHeaders: [String: String]
        public let verboseLogging: Bool
        public let warningResponseTimeMs: TimeInterval
        public let timeoutIntervalForRequest: TimeInterval
        public let timeoutIntervalForResource: TimeInterval

        public init(
            baseURL: URL,
            defaultHeaders: [String: String] = [:],
            verboseLogging: Bool = false,
            warningResponseTimeMs: TimeInterval = 5_000,
            timeoutIntervalForRequest: TimeInterval = 120,
            timeoutIntervalForResource: TimeInterval = 120
        ) {
            self.baseURL = baseURL
            self.defaultHeaders = defaultHeaders
            self.verboseLogging = verboseLogging
            self.warningResponseTimeMs = warningResponseTimeMs
            self.timeoutIntervalForRequest = timeoutIntervalForRequest
            self.timeoutIntervalForResource = timeoutIntervalForResource
        }
    }

    private let config: Config
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    private let authProvider: AuthProvider
    private let logger: ForgeLogger?

    public var baseURL: URL {
        config.baseURL
    }

    public init(
        config: Config,
        sessionConfiguration: URLSessionConfiguration = .default,
        authProvider: AuthProvider,
        logger: ForgeLogger? = nil
    ) {
        self.config = config
        self.authProvider = authProvider
        self.logger = logger

        jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601

        jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        jsonDecoder.dateDecodingStrategy = .iso8601withOptionalFractionalSeconds

        sessionConfiguration.timeoutIntervalForRequest = config.timeoutIntervalForRequest
        sessionConfiguration.timeoutIntervalForResource = config.timeoutIntervalForResource
        session = .init(configuration: sessionConfiguration)
    }

    public func request(_ target: Target) async throws {
        _ = try await request(target, responseType: EmptyCodable.self)
    }

    public func request<T: Decodable>(_ target: Target, responseType: T.Type) async throws -> T {
        let data = try await requestData(target)

        do {
            return try parseResponseData(data, target: target)
        } catch {
            throw await handleError(error, for: target)
        }
    }

    public func requestData(_ target: Target) async throws -> Data {
        logger?.log(message: "Starting request to \(target.requestDescription)")

        do {
            var request = try URLRequest(baseURL: config.baseURL, target: target, bodyEncoder: jsonEncoder)
            try await applyHeaders(for: target, to: &request)
            #if DEBUG
            if config.verboseLogging {
                logger?.log(message: "\(request.cURL)")
            }
            #else
            logger?.log(message: "\(request.cURLCompact)")
            #endif

            let (data, urlResponse) = try await logRequestDuration(for: target.requestDescription) {
                try await session.data(for: request)
            }
            try Task.checkCancellation()
            try validateResponse(urlResponse, data: data)
            return data
        } catch {
            throw await handleError(error, for: target)
        }
    }

    public func upload<T: Decodable>(_ target: Target, files: [UploadFile]) async throws -> T {
        logger?.log(message: "Starting multipart upload request to \(target.requestDescription)")

        do {
            var request: URLRequest = try .init(baseURL: config.baseURL, target: target, bodyEncoder: jsonEncoder)
            var multipartRequest = MultipartRequest()

            for file in files {
                multipartRequest.append(
                    fileData: file.data,
                    withName: file.name,
                    fileName: file.filename,
                    mimeType: file.mimeType
                )
            }

            try await applyHeaders(for: target, to: &request)
            request.setValue(multipartRequest.headerValue, forHTTPHeaderField: "Content-Type")

            #if DEBUG
            if config.verboseLogging {
                logger?.log(message: "\(request.cURL)")
            }
            #else
            logger?.log(message: "\(request.cURLCompact)")
            #endif

            let (data, urlResponse) = try await logRequestDuration(for: target.requestDescription) {
                try await session.upload(for: request, from: multipartRequest.httpBody)
            }
            try Task.checkCancellation()
            try validateResponse(urlResponse, data: data)
            return try parseResponseData(data, target: target)
        } catch {
            throw await handleError(error, for: target)
        }
    }

    public func requestByteSequence(
        _ target: Target
    ) async throws -> AsyncMapSequence<URLSession.AsyncBytes, Data> {
        logger?.log(message: "Starting stream request to \(target.requestDescription)")

        do {
            var request: URLRequest = try .init(baseURL: config.baseURL, target: target, bodyEncoder: jsonEncoder)
            try await applyHeaders(for: target, to: &request)
            #if DEBUG
            if config.verboseLogging {
                logger?.log(message: "\(request.cURL)")
            }
            #else
            logger?.log(message: "\(request.cURLCompact)")
            #endif

            let (bytes, response) = try await logRequestDuration(for: target.requestDescription) {
                try await session.bytes(for: request)
            }
            try Task.checkCancellation()
            try validateResponse(response, data: nil)
            return bytes.map { Data([$0]) }
        } catch {
            throw await handleError(error, for: target)
        }
    }
}

// MARK: - Request processing
private extension NetworkService {

    func applyHeaders(for target: Target, to request: inout URLRequest) async throws {
        if target.method == .patch {
            request.addValue("application/json-patch+json", forHTTPHeaderField: "Content-Type")
        } else {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        try await applyAuthorizationHeader(for: target, to: &request)

        for (key, value) in config.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        for (key, value) in target.additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    func applyAuthorizationHeader(for target: Target, to request: inout URLRequest) async throws {
        do {
            let token = try await authProvider.getToken()
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } catch {
            if target.isAuthenticationRequired {
                throw APIError<APIErrorResponse>(.unauthorized)
            }
        }
    }
}

// MARK: - Response handling
private extension NetworkService {

    func validateResponse(_ urlResponse: URLResponse, data: Data?) throws {
        guard
            let httpResponse = urlResponse as? HTTPURLResponse,
            let httpStatusCode = HttpStatusCode(rawValue: httpResponse.statusCode)
        else {
            throw NetworkError.url(.badServerResponse)
        }

        if httpStatusCode.isSuccess || httpStatusCode.isRedirection {
            return
        }

        if let data, let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data) {
            throw APIError<APIErrorResponse>(httpStatusCode, response: errorResponse)
        }

        throw APIError<APIErrorResponse>(httpStatusCode)
    }

    func parseResponseData<T: Decodable>(_ data: Data, target: Target) throws -> T {
        if data.isEmpty, let emptyResponse = try handleEmptyResponse(responseType: T.self) {
            return emptyResponse
        }

        do {
            let decodedResponse: T = try jsonDecoder.decode(T.self, from: data)
            if config.verboseLogging {
                logger?.log(message: "Successfully decoded response of type \(T.self)")
            }
            return decodedResponse
        } catch {
            do {
                let jsonString: String = try data.prettyPrintedJSONString()
                logger?.capture(
                    error: error,
                    message:
                    """
                    Decoding error on \(target.requestDescription):
                    \(error)
                    Failed to decode response:
                    \(jsonString)
                    """
                )
            } catch {
                logger?.capture(
                    error: error,
                    message:
                    """
                    Decoding error on \(target.requestDescription):
                    Could not parse JSON from data: \(String(data: data, encoding: .utf8) ?? "")
                    """
                )
            }

            throw error
        }
    }

    @discardableResult
    func logRequestDuration<T>(for requestDescription: String, operation: () async throws -> T) async rethrows -> T {
        let start = ContinuousClock.now
        let result = try await operation()
        let responseTime = start.duration(to: .now) / .milliseconds(1)

        if responseTime > config.warningResponseTimeMs {
            logger?.log(
                message: """
                Response for \(requestDescription) took longer than expected.
                Response time: \(responseTime.formatted(.number.precision(.fractionLength(0)).grouping(.never))) ms
                """,
                level: .warning
            )
        } else {
            logger?.log(
                message: """
                Response for: \(requestDescription)
                Response time: \(responseTime.formatted(.number.precision(.fractionLength(0)).grouping(.never))) ms
                """
            )
        }

        return result
    }
}

// MARK: - Error handling
private extension NetworkService {

    func handleError(_ error: Error, for target: Target) async -> Error {
        switch error {
        case URLError.cancelled:
            logger?.log(message: "Request cancelled: \(target.requestDescription)", level: .warning)
            return CancellationError()
        case let urlError as URLError:
            await handleURLError(urlError, for: target)
            return NetworkError.url(urlError.code)
        case let encodingError as EncodingError:
            return NetworkError.encoding(encodingError)
        case let decodingError as DecodingError:
            return NetworkError.decoding(decodingError)
        case let apiError as APIError<APIErrorResponse>:
            return apiError
        default:
            handleGeneralError(error, for: target)
            return NetworkError.unknown(error)
        }
    }

    func handleURLError(_ urlError: URLError, for target: Target) async {
        let failedRequestMessage = "Failed request: \(target.requestDescription)"

        if urlError.code == .notConnectedToInternet {
            logger?.log(message: "\(failedRequestMessage)\nNo internet connection", level: .warning)
        } else {
            logger?.capture(
                error: urlError,
                message: "\(failedRequestMessage)\n\(urlError.localizedDescription)"
            )
        }
    }

    func handleGeneralError(_ error: Error, for target: Target) {
        logger?.capture(
            error: error,
            message:
            """
            Unexpected error for request: \(target.requestDescription)
            \(error)
            """
        )
    }

    func handleEmptyResponse<T: Decodable>(responseType: T.Type) throws -> T? {
        if responseType == EmptyCodable.self {
            return EmptyCodable() as? T
        }
        return nil
    }
}

private extension Data {
    func prettyPrintedJSONString() throws -> String {
        let jsonObject: Any = try JSONSerialization.jsonObject(with: self, options: [])
        let prettyData: Data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        return String(decoding: prettyData, as: UTF8.self)
    }
}
