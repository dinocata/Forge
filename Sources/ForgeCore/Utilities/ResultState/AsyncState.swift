//
//  AsyncState.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//
//  Platform-specific conveniences (e.g. iOS `Preferences`-bound init)
//  live in the Robyn target.

import Combine
import Foundation
import SwiftUI

/// How an operation performed on an ``AsyncState`` reports itself while it runs.
///
/// Declared alongside the state rather than inside it: nested in a generic type these would be a
/// different type per element, and a set of options describes the operation, not what it returns.
public struct AsyncOperationOptions: Sendable {

    /// How long the operation may run before it is worth saying so, which is what keeps a fast
    /// answer from flashing a spinner on its way past.
    public var showLoadingAfter: TimeInterval

    /// How long the loading state stays once shown, so it reads as loading rather than as a blink.
    public var minimumLoadingDuration: TimeInterval

    /// Whether a state that already holds a success stays on screen while it is refreshed.
    public var skipLoadingWhenSuccessful: Bool

    /// Whether giving up puts back the state the operation found.
    ///
    /// Only for a caller that cancels on its own — an operation replaced by a newer one leaves the
    /// state to its replacement regardless. See ``AsyncState/perform(options:operation:)``.
    public var resetOnCancellation: Bool

    public init(
        showLoadingAfter: TimeInterval = 0.2,
        minimumLoadingDuration: TimeInterval = 0.4,
        skipLoadingWhenSuccessful: Bool = true,
        resetOnCancellation: Bool = true
    ) {
        self.showLoadingAfter = showLoadingAfter
        self.minimumLoadingDuration = minimumLoadingDuration
        self.skipLoadingWhenSuccessful = skipLoadingWhenSuccessful
        self.resetOnCancellation = resetOnCancellation
    }
}

/// State management class that provides delayed loading behavior for
/// asynchronous operations. Wraps a `ResultState<T>` and prevents UI
/// flicker by enforcing a minimum loading-state duration.
@MainActor
@Observable
public final class AsyncState<T> {
    public typealias ValueUpdateClosure = (T?) -> Void

    public var value: T? {
        get {
            state.value ?? cachedValue
        }
        set {
            if let newValue {
                state = .success(newValue)
            } else {
                state = .initial
            }
        }
    }

    public var isSuccess: Bool { state.isSuccess }
    public var isLoading: Bool { state.isLoading }
    public var isFailure: Bool { state.isFailure }
    public var isInitial: Bool { state.isInitial }

    @ObservationIgnored
    public var animation: Animation?

    public var state: ResultState<T> {
        didSet {
            switch state {
            case .initial:
                cachedValue = nil
                if shouldNotifyValueUpdate {
                    onValueUpdate?(nil)
                }
            case .success(let value):
                cachedValue = value
                if shouldNotifyValueUpdate {
                    onValueUpdate?(value)
                }
            default:
                break
            }
        }
    }

    @ObservationIgnored
    private var cachedValue: T?

    @ObservationIgnored
    private let onValueUpdate: ValueUpdateClosure?

    /// Settable from extensions (e.g. iOS `Preferences` bridging) so they
    /// can suppress callbacks while syncing.
    @ObservationIgnored
    public var shouldNotifyValueUpdate: Bool = true

    @ObservationIgnored
    public var cancellables: Set<AnyCancellable> = []

    /// Which operation currently owns this state.
    ///
    /// Every write made by ``perform(options:operation:)`` is checked against this, so only the
    /// most recently started operation can change what is shown. Without it, an operation that is superseded while still in flight goes on to write
    /// anyway — its result, its delayed loading, or the state it captured on the way in — over the
    /// answer that replaced it.
    ///
    /// Wrapping addition on a 64-bit counter: at a million operations a second it would take some
    /// 585,000 years to come back around, and a collision needs an operation still running when it
    /// does.
    @ObservationIgnored
    private var currentOperationID: UInt64 = 0

    /// The operation in flight, held so the next one can stop it.
    ///
    /// Superseded work is not merely ignored, it is cancelled: a fetch nobody will read should not
    /// go on occupying the network or the database.
    @ObservationIgnored
    private var operationTask: Task<Void, Never>?

    public init(
        initialState: ResultState<T> = .initial,
        animation: Animation? = .default,
        onValueUpdate: ValueUpdateClosure? = nil
    ) {
        self.state = initialState
        self.animation = animation
        self.onValueUpdate = onValueUpdate
    }

    public convenience init(
        initialValue: T?,
        animation: Animation? = .default,
        onValueUpdate: ValueUpdateClosure? = nil
    ) {
        if let initialValue {
            self.init(
                initialState: .success(initialValue),
                animation: animation,
                onValueUpdate: onValueUpdate
            )
        } else {
            self.init(animation: animation, onValueUpdate: onValueUpdate)
        }
    }

    public func getValue() throws -> T {
        guard let value else {
            throw ResultStateError.noValue
        }
        return value
    }

    /// Performs an asynchronous operation, reporting itself as ``AsyncOperationOptions`` describes.
    ///
    /// - If the operation completes within `showLoadingAfter`, no loading state is shown.
    /// - If it takes longer, the loading state is shown for at least `minimumLoadingDuration`.
    /// - If the operation is cancelled and `resetOnCancellation` is true, the state reverts.
    /// - If the operation fails, the state becomes `.failure`.
    ///
    /// Asking for an operation while one is in flight replaces it: the one already running is
    /// cancelled and can no longer write here, whatever it goes on to do. That is what makes this
    /// safe to drive from a `.task(id:)` whose id keeps changing, where the losing call would
    /// otherwise land after the winner and undo it.
    ///
    /// Being replaced is not the same as being given up on, which is why `resetOnCancellation`
    /// still means what it says: a caller that cancels on its own — a view that went away — puts
    /// back the state it found, because nothing has taken ownership from it.
    @discardableResult
    public func perform(
        options: AsyncOperationOptions = .init(),
        operation: @escaping () async throws -> T
    ) async -> ResultState<T> {
        currentOperationID &+= 1
        let operationID = currentOperationID
        operationTask?.cancel()

        let task = Task { [weak self] in
            guard let self else {
                return
            }

            await run(operationID: operationID, options: options, operation: operation)
        }
        operationTask = task

        // The task is unstructured, so it does not inherit the caller's cancellation — and the
        // caller is usually a `.task` modifier, whose cancellation is the whole point. Bridged
        // rather than inherited, so that both kinds of cancellation reach the work.
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }

        return state
    }

    private func run(
        operationID: UInt64,
        options: AsyncOperationOptions,
        operation: () async throws -> T
    ) async {
        let originalState: ResultState<T> = state
        let startDate: Date = .now
        let totalLoadingTime: TimeInterval = options.showLoadingAfter + options.minimumLoadingDuration

        let loaderTask = Task {
            guard !originalState.isSuccess || !options.skipLoadingWhenSuccessful else {
                return
            }
            try await Task.sleep(for: .seconds(options.showLoadingAfter))
            updateState(.loading, from: operationID)
        }

        do {
            let result: T = try await operation()
            try Task.checkCancellation()
            await handleLoaderTask(loaderTask, startDate: startDate, totalLoadingTime: totalLoadingTime)
            updateState(.success(result), from: operationID)
        } catch is CancellationError {
            loaderTask.cancel()
            if options.resetOnCancellation {
                updateState(originalState, from: operationID)
            }
        } catch {
            await handleLoaderTask(loaderTask, startDate: startDate, totalLoadingTime: totalLoadingTime)
            updateState(.failure(error), from: operationID)
        }
    }

    /// Writes only while `operationID` still owns the state — see ``currentOperationID``.
    private func updateState(_ newState: ResultState<T>, from operationID: UInt64) {
        guard operationID == currentOperationID else {
            return
        }

        updateState(newState)
    }

    private func handleLoaderTask(
        _ task: Task<Void, Error>,
        startDate: Date,
        totalLoadingTime: TimeInterval
    ) async {
        let remainingLoadingTask = Task {
            if state.isLoading {
                let elapsedTime: TimeInterval = Date().timeIntervalSince(startDate)
                let remainingTime: TimeInterval = totalLoadingTime - elapsedTime
                if remainingTime > 0 {
                    try await Task.sleep(for: .seconds(remainingTime))
                }
            }
            task.cancel()
        }
        try? await remainingLoadingTask.value
    }

    public func updateState(_ newState: ResultState<T>) {
        if let animation {
            withAnimation(animation) {
                state = newState
            }
        } else {
            state = newState
        }
    }

    /// Returns to `.initial`, and gives up on whatever was being performed.
    ///
    /// The operation is superseded as well as cancelled, so a reset cannot be undone a moment
    /// later by work that was already on its way out.
    public func reset() {
        currentOperationID &+= 1
        operationTask?.cancel()
        operationTask = nil
        updateState(.initial)
    }
}

extension AsyncState: Equatable {

    public static func == (lhs: AsyncState, rhs: AsyncState) -> Bool {
        lhs.state == rhs.state
    }
}
