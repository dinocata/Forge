//
//  TaskQueue.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation
import Synchronization

/// Runs asynchronous operations serially, in the order ``enqueue(isolation:_:)`` is called.
///
/// Not `Sendable`: a queue lives on its owner's actor, and enqueuing is a synchronous call there, so
/// each operation's place in line is fixed at the call, even from synchronous code. To share one
/// queue across actors, use ``SharedTaskQueue``.
///
/// A failure does not stop later operations; call ``cancelAll()`` when it should.
public final class TaskQueue<Value: Sendable> {
    /// Whether an operation is running or waiting to run.
    public var hasActiveTasks: Bool {
        !operations.isEmpty
    }

    /// Each unfinished operation by its place in line.
    private var operations: [Int: Task<Value, Error>] = [:]
    /// Finishes once the last enqueued operation has, which the next one waits for.
    private var tail: Task<Void, Never>?
    private var nextSequence = 0
    private var drainResults: [Int: Result<Value, Error>] = [:]
    private var drainWaiters: [OneShot<[Value]>] = []

    public init() {}

    /// Enqueues `operation` behind every operation enqueued before it, and returns at once.
    ///
    /// The operation runs on no actor of its own. Annotate it with a global actor when its work
    /// requires one, such as `queue.enqueue { @MainActor in ... }` for UI work.
    @discardableResult
    public func enqueue(
        isolation: isolated (any Actor)? = #isolation,
        _ operation: @escaping @Sendable () async throws -> Value
    ) -> QueuedOperation<Value> {
        let sequence = nextSequence
        nextSequence += 1

        let previous = tail
        let task = Task<Value, Error> {
            try await waitForTurn(after: previous)
            let value = try await operation()
            try Task.checkCancellation()
            return value
        }
        tail = Task {
            await previous?.value
            _ = await task.result
        }
        operations[sequence] = task

        let completion = Task<Value, Error> {
            _ = isolation
            let result = await task.result
            self.finish(sequence, with: result)
            return try result.get()
        }

        return QueuedOperation(task: task, completion: completion)
    }

    /// Waits until the queue first becomes empty and returns every value produced in FIFO order.
    ///
    /// Operations enqueued while waiting join the same drain. If any operation fails, this still
    /// waits for the queue to empty before throwing the first failure in FIFO order. Results from
    /// operations completed earlier in the same drain are included. Cancelling a waiter does not
    /// cancel queue operations, and calling this on an empty queue returns immediately.
    @discardableResult
    public func waitForAll(isolation: isolated (any Actor)? = #isolation) async throws -> [Value] {
        guard hasActiveTasks else {
            return []
        }

        let waiter = OneShot<[Value]>()
        drainWaiters.append(waiter)

        return try await withTaskCancellationHandler {
            try await waiter.wait()
        } onCancel: {
            waiter.resolve(with: .failure(CancellationError()))
        }
    }

    /// Cancels the active operation and every operation still waiting to run.
    ///
    /// Waiting operations finish with `CancellationError` at once. The active one finishes when it
    /// cooperates with cancellation by reaching a cancellation-aware suspension point or returning.
    public func cancelAll() {
        operations.values.forEach { $0.cancel() }
    }

    private func finish(_ sequence: Int, with result: Result<Value, Error>) {
        operations[sequence] = nil
        drainResults[sequence] = result

        guard !hasActiveTasks else {
            return
        }

        let drainResult = drainResult()
        let waiters = drainWaiters
        drainWaiters.removeAll()
        drainResults.removeAll()
        waiters.forEach { $0.resolve(with: drainResult) }
    }

    private func drainResult() -> Result<[Value], Error> {
        var values: [Value] = []

        for result in drainResults.sorted(by: \.key).map(\.value) {
            switch result {
            case .success(let value):
                values.append(value)
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(values)
    }
}

/// Waits for `previous` to finish, or throws as soon as the caller is cancelled, so a cancelled
/// operation never waits out the ones ahead of it.
private func waitForTurn(after previous: Task<Void, Never>?) async throws {
    if let previous {
        let turn = OneShot<Void>()
        Task {
            await previous.value
            turn.resolve(with: .success(()))
        }

        try await withTaskCancellationHandler {
            try await turn.wait()
        } onCancel: {
            turn.resolve(with: .failure(CancellationError()))
        }
    }

    try Task.checkCancellation()
}

/// One operation enqueued on a ``TaskQueue``.
public struct QueuedOperation<Value: Sendable>: Sendable {
    fileprivate let task: Task<Value, Error>
    fileprivate let completion: Task<Value, Error>

    /// The operation's value once it has run. Cancelling the task awaiting it cancels the operation
    /// without affecting the others in the queue.
    public var value: Value {
        get async throws {
            try await withTaskCancellationHandler {
                try await completion.value
            } onCancel: {
                task.cancel()
            }
        }
    }

    /// Cancels the operation without affecting the others in the queue.
    public func cancel() {
        task.cancel()
    }
}

/// A result delivered once to one waiter, whichever of the two comes first.
private final class OneShot<Success: Sendable>: Sendable {
    private enum State {
        case waiting(CheckedContinuation<Success, Error>?)
        case resolved(Result<Success, Error>)
    }

    private let state = Mutex(State.waiting(nil))

    func wait() async throws -> Success {
        try await withCheckedThrowingContinuation { continuation in
            let resolved: Result<Success, Error>? = state.withLock { state in
                guard case .resolved(let result) = state else {
                    state = .waiting(continuation)
                    return nil
                }

                return result
            }

            if let resolved {
                continuation.resume(with: resolved)
            }
        }
    }

    /// Delivers `result`, unless one was delivered already.
    func resolve(with result: Result<Success, Error>) {
        let continuation: CheckedContinuation<Success, Error>?? = state.withLock { state in
            guard case .waiting(let continuation) = state else {
                return nil
            }

            state = .resolved(result)
            return .some(continuation)
        }

        continuation??.resume(with: result)
    }
}
