/// Supplies a credential for targets that opt in to authentication.
public protocol TokenProvider: Sendable {
    func getToken() async throws -> String
}
