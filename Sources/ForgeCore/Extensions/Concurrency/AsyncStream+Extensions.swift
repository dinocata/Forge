//
//  AsyncStream+Extensions.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation

private extension AsyncStream {
    /// Produces an `AsyncStream` from an `AsyncSequence` by consuming it
    /// till it terminates, ignoring any failure.
    init<Base: AsyncSequence>(_ sequence: Base) where Element == Base.Element, Base: Sendable, Base.Element: Sendable {
        self.init { continuation in
            let task = Task {
                do {
                    for try await element in sequence {
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    assertionFailure("AsyncSequence threw \(error.localizedDescription). Use AsyncThrowingStream instead")
                    continuation.finish()
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

private extension AsyncThrowingStream where Failure == Error {
    /// Produces an `AsyncThrowingStream` from an `AsyncSequence` by
    /// consuming it till it terminates, rethrowing any failure.
    init<Base: AsyncSequence>(_ sequence: Base) where Element == Base.Element, Base: Sendable, Base.Element: Sendable {
        self.init { continuation in
            let task = Task {
                do {
                    for try await element in sequence {
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

public extension AsyncSequence where Self: Sendable, Element: Sendable {
    /// Erases this async sequence to an `AsyncStream` that produces
    /// elements till this sequence terminates (or fails).
    func eraseToStream() -> AsyncStream<Element> {
        AsyncStream(self)
    }

    /// Erases this async sequence to an `AsyncThrowingStream` that produces
    /// elements till this sequence terminates, rethrowing any error on
    /// failure.
    func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(self)
    }
}
