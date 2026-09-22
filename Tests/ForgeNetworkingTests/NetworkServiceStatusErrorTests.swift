// Created by Dino Catalinac on 22.09.2026.

import ForgeCore
import ForgeNetworking
import Foundation
import Synchronization
import Testing

/// A status outside the success and redirection ranges belongs to the caller: it arrives as an
/// `APIError`, and the service reports nothing about it to the logger.
@Suite
struct NetworkServiceStatusErrorTests {

    @Test
    func notFoundReachesTheCallerAsAPIErrorWithoutLogging() async {
        let logger = RecordingLogger()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NotFoundURLProtocol.self]
        let service = NetworkService<ErrorBody>(
            config: .init(baseURL: URL(string: "https://example.test").forceUnwrap),
            sessionConfiguration: configuration,
            tokenProvider: NoTokenProvider(),
            logger: logger
        )

        let error = await #expect(throws: APIError<ErrorBody>.self) {
            try await service.request(ItemTarget())
        }

        #expect(error?.statusCode == .notFound)
        #expect(error?.response == ErrorBody(message: NotFoundURLProtocol.message))
        #expect(logger.capturedErrorCount == 0)
        #expect(logger.warningCount == 0)
    }
}

private struct ErrorBody: Decodable, Sendable, Equatable {
    let message: String
}

private struct ItemTarget: Target {
    var path: String { "/items/1" }
    var method: HttpMethod { .get }
}

private struct NoTokenProvider: TokenProvider {
    struct Missing: Error {}

    func getToken() async throws -> String { throw Missing() }
}

/// Answers every request with a 404 and a JSON error body, so no request leaves the process.
private final class NotFoundURLProtocol: URLProtocol {
    static let message = "No such item"

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url.forceUnwrap
        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil).forceUnwrap
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"message":"\#(Self.message)"}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class RecordingLogger: ForgeLogger {
    private let levels = Mutex<[LogLevel]>([])
    private let captures = Mutex(0)

    var warningCount: Int { levels.withLock { $0.filter { $0 == .warning || $0 == .error }.count } }
    var capturedErrorCount: Int { captures.withLock { $0 } }

    func log(_ message: String, level: LogLevel, file: StaticString, function: StaticString, line: UInt) {
        levels.withLock { $0.append(level) }
    }

    func capture(_ error: Error, message: String?, file: StaticString, function: StaticString, line: UInt) {
        captures.withLock { $0 += 1 }
    }
}
