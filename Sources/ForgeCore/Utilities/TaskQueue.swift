//
//  TaskQueue.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation
import OrderedCollections

/// Runs asynchronous operations serially in first-in, first-out order.
///
/// Each call to ``enqueue(_:)`` waits only for its own operation and receives that operation's
/// value or error. A failure does not stop later operations; call ``cancelAll()`` when it should.
public actor TaskQueue<Value: Sendable> {
    /// Whether an operation is running or waiting to run.
    public var hasActiveTasks: Bool {
        activeTask != nil || !tasks.isEmpty
    }

    private var tasks: IdentifiedArrayOf<TaskEntry<Value>> = []
    private var activeTask: ActiveTask?
    private var nextSequence = 0
    private var drainResults: [Int: Result<Value, Error>] = [:]
    private var drainWaiters: IdentifiedArrayOf<DrainWaiter<Value>> = []

    public init() {}

    /// Enqueues an operation and returns that operation's value when its turn finishes.
    ///
    /// Cancelling the caller cancels this operation without affecting the others in the queue.
    /// Annotate the closure with a global actor when its work requires one, such as
    /// `queue.enqueue { @MainActor in ... }` for UI work.
    public func enqueue(
        _ operation: @Sendable @escaping () async throws -> Value
    ) async throws -> Value {
        let taskID = UUID()
        let sequence = nextSequence
        nextSequence += 1

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                tasks.append(
                    TaskEntry(
                        id: taskID,
                        sequence: sequence,
                        operation: operation,
                        complete: { continuation.resume(with: $0) }
                    )
                )
                startNextTaskIfNeeded()
            }
        } onCancel: {
            Task { await self.cancel(taskID) }
        }
    }

    /// Waits until the queue first becomes empty and returns every value produced in FIFO order.
    ///
    /// Operations enqueued while waiting join the same drain. If any operation fails, this still
    /// waits for the queue to empty before throwing the first failure in FIFO order. Results from
    /// operations completed earlier in the same drain are included. Cancelling a waiter does not
    /// cancel queue operations, and calling this on an empty queue returns immediately.
    @discardableResult
    public func waitForAll() async throws -> [Value] {
        guard hasActiveTasks else {
            return []
        }

        let waiterID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                drainWaiters.append(DrainWaiter(id: waiterID, continuation: continuation))
            }
        } onCancel: {
            Task { await self.cancelWaiter(waiterID) }
        }
    }

    /// Cancels the active operation and every operation still waiting to run.
    ///
    /// Pending callers resume immediately. The active operation resumes after it cooperates with
    /// cancellation by reaching a cancellation-aware suspension point or returning.
    public func cancelAll() {
        let pendingTasks = tasks
        tasks.removeAll()

        for task in pendingTasks {
            complete(task, with: .failure(CancellationError()))
        }

        activeTask?.task.cancel()
        completeDrainIfNeeded()
    }

    private func cancel(_ taskID: UUID) {
        if activeTask?.id == taskID {
            activeTask?.task.cancel()
        } else if let task = tasks.remove(id: taskID) {
            complete(task, with: .failure(CancellationError()))
            completeDrainIfNeeded()
        }
    }

    private func cancelWaiter(_ waiterID: UUID) {
        drainWaiters.remove(id: waiterID)?.continuation.resume(throwing: CancellationError())
    }

    private func startNextTaskIfNeeded() {
        guard activeTask == nil, let task = tasks.first else {
            return
        }

        tasks.remove(id: task.id)
        let runningTask = Task { [self] in
            let result: Result<Value, Error>

            do {
                try Task.checkCancellation()
                let value = try await task.operation()
                try Task.checkCancellation()
                result = .success(value)
            } catch let operationError {
                result = .failure(Task.isCancelled ? CancellationError() : operationError)
            }

            finishTask(task, with: result)
        }
        activeTask = ActiveTask(id: task.id, task: runningTask)
    }

    private func finishTask(_ task: TaskEntry<Value>, with result: Result<Value, Error>) {
        guard activeTask?.id == task.id else {
            return
        }

        complete(task, with: result)
        activeTask = nil
        startNextTaskIfNeeded()
        completeDrainIfNeeded()
    }

    private func complete(_ task: TaskEntry<Value>, with result: Result<Value, Error>) {
        drainResults[task.sequence] = result
        task.complete(result)
    }

    private func completeDrainIfNeeded() {
        guard hasActiveTasks == false else {
            return
        }

        let result = drainResult()
        let waiters = drainWaiters
        drainWaiters.removeAll()
        drainResults.removeAll()
        nextSequence = 0
        waiters.forEach { $0.continuation.resume(with: result) }
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

private struct ActiveTask {
    let id: UUID
    let task: Task<Void, Never>
}

private struct TaskEntry<Value: Sendable>: Identifiable, Sendable {
    let id: UUID
    let sequence: Int
    let operation: @Sendable () async throws -> Value
    let complete: @Sendable (Result<Value, Error>) -> Void
}

private struct DrainWaiter<Value: Sendable>: Identifiable {
    let id: UUID
    let continuation: CheckedContinuation<[Value], Error>
}
