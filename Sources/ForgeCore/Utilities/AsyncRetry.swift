// Created by Dino Catalinac on 23.07.2026.

import Foundation

/// Performs a retryable async throwing operation with exponential backoff.
/// - Parameters:
///   - maxAttempts: Maximum number of total attempts, including the initial operation.
///     The default value is 4. Set this to 0 for unlimited attempts.
///   - initialInterval: Amount of time that must elapse before the first retry occurs. Default is 1 second.
///   - backoff: Multiplier for the retry interval. Default is 2.0.
///   - maxBackoff: Specifies the maximum interval between retries. Default is 100 seconds.
///     If exponential backoff would exceed this value, the retry delay is capped at `maxBackoff`.
///   - retryHandler: Optional error handler in case you don't need to retry for certain errors
///     or you need to perform extra action before retrying.
///   - operation: Operation block to execute on initial request and every subsequent retry.
public func asyncRetry<T>(
    maxAttempts: Int = 4,
    initialInterval: TimeInterval = 1,
    backoff: Double = 2,
    maxBackoff: Double = 100,
    operation: @Sendable () async throws -> T,
    retryHandler: (@Sendable (Error) async throws -> Void)? = nil
) async throws -> T {
    var retry: Int = 0

    while maxAttempts == 0 || retry < (maxAttempts - 1) {
        do {
            return try await operation()
        } catch {
            if let retryHandler {
                try await retryHandler(error)
            }

            try Task.checkCancellation()

            let nextBackoff: Double = pow(backoff, Double(retry))
            let nextInterval: TimeInterval = min(
                initialInterval * nextBackoff,
                maxBackoff
            )
            try await Task.sleep(for: .seconds(nextInterval))
            retry += 1
        }
    }

    return try await operation()
}
