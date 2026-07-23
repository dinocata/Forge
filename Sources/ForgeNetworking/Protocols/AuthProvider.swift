/// Supplies a credential for targets that opt in to authentication.
public protocol AuthProvider: Sendable {
    func getToken() async throws -> String
}
