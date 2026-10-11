//
//  SharedTaskQueue.swift
//  ForgeCore
//
//  Created by Dino Catalinac on 11.10.2026.
//

/// A ``TaskQueue`` that callers on different actors share.
///
/// Each call hops onto this actor, so operations run in the order the calls arrive here. That is
/// call order for a caller awaiting each call in turn, but not for separate tasks started together,
/// which may arrive in either order. Callers on one actor that need call order use a ``TaskQueue``.
public actor SharedTaskQueue<Value: Sendable> {
    private let queue = TaskQueue<Value>()

    /// Whether an operation is running or waiting to run.
    public var hasActiveTasks: Bool {
        queue.hasActiveTasks
    }

    public init() {}

    /// Enqueues `operation` behind every operation that arrived before it, and returns its value
    /// once it has run.
    ///
    /// Cancelling the caller cancels this operation without affecting the others in the queue.
    public func enqueue(_ operation: @escaping @Sendable () async throws -> Value) async throws -> Value {
        try await queue.enqueue(operation).value
    }

    /// See ``TaskQueue/waitForAll(isolation:)``.
    @discardableResult
    public func waitForAll() async throws -> [Value] {
        try await queue.waitForAll()
    }

    /// See ``TaskQueue/cancelAll()``.
    public func cancelAll() {
        queue.cancelAll()
    }
}
