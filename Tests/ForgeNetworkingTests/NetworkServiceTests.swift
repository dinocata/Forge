import Foundation
import Testing
@testable import ForgeNetworking

@Suite("ForgeNetworking")
struct NetworkServiceTests {
    @Test("Builds a request with encoded query values and headers")
    func buildsRequest() async throws {
        let target = TestTarget()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RequestCaptureProtocol.self]
        let service = NetworkService(configuration: .init(baseURL: try #require(URL(string: "https://example.com")), defaultHeaders: ["X-Default": "default"]), sessionConfiguration: configuration)

        let response: EmptyCodable = try await service.request(target)
        _ = response
        let request = try #require(RequestCaptureProtocol.storage.request)
        #expect(request.url?.absoluteString == "https://example.com/widgets?query=a%2Bb")
        #expect(request.value(forHTTPHeaderField: "X-Default") == "default")
        #expect(request.value(forHTTPHeaderField: "X-Target") == "target")
    }

    @Test("cURL output redacts credentials and body")
    func redactsCurl() throws {
        var request = URLRequest(url: try #require(URL(string: "https://example.com")))
        request.setValue("Bearer secret", forHTTPHeaderField: "Authorization")
        request.httpBody = Data("secret".utf8)
        #expect(request.cURL.contains("secret") == false)
        #expect(request.cURL.contains("<redacted body: 6 bytes>"))
    }
}

private struct TestTarget: Target {
    let path = "/widgets"
    let method: HttpMethod = .get
    let queryItems = [URLQueryItem(name: "query", value: "a+b")]
    let additionalHeaders = ["X-Target": "target"]
}

private final class RequestCaptureProtocol: URLProtocol, @unchecked Sendable {
    static let storage = RequestStorage()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.storage.request = request
        let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private final class RequestStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var value: URLRequest?

    var request: URLRequest? {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }
}
