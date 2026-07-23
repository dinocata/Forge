import Foundation

/// Type-specialized facade around `NetworkService` for a target family.
public final class APIClient<TargetType: Target, APIErrorResponse: Decodable & Sendable>: Sendable {

    private let network: NetworkService<APIErrorResponse>

    public var baseURL: URL {
        network.baseURL
    }

    public init(network: NetworkService<APIErrorResponse>) {
        self.network = network
    }

    public func request(_ target: TargetType) async throws {
        try await network.request(target)
    }

    public func request<T: Decodable>(_ target: TargetType, responseType: T.Type = T.self) async throws -> T {
        try await network.request(target, responseType: responseType)
    }

    public func requestData(_ target: TargetType) async throws -> Data {
        try await network.requestData(target)
    }

    public func requestByteSequence(
        _ target: TargetType
    ) async throws -> AsyncMapSequence<URLSession.AsyncBytes, Data> {
        try await network.requestByteSequence(target)
    }

    public func upload(_ target: TargetType, files: [UploadFile]) async throws {
        let _: EmptyCodable = try await network.upload(target, files: files)
    }

    public func upload<T: Decodable>(_ target: TargetType, files: [UploadFile]) async throws -> T {
        try await network.upload(target, files: files)
    }
}
