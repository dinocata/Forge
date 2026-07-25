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

/// State management class that provides delayed loading behavior for
/// asynchronous operations. Wraps a `ResultState<T>` and prevents UI
/// flicker by enforcing a minimum loading-state duration.
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
}

@MainActor
extension AsyncState {

    /// Performs an asynchronous operation with delayed loading behavior.
    ///
    /// - If the operation completes within `showLoadingAfter`, no loading state is shown.
    /// - If it takes longer, the loading state is shown for at least `minimumLoadingDuration`.
    /// - If the operation is cancelled and `resetOnCancellation` is true, the state reverts.
    /// - If the operation fails, the state becomes `.failure`.
    @discardableResult
    public func perform(
        showLoadingAfter: TimeInterval = 0.2,
        minimumLoadingDuration: TimeInterval = 0.4,
        skipLoadingWhenSuccessful: Bool = true,
        resetOnCancellation: Bool = true,
        operation: () async throws -> T
    ) async -> ResultState<T> {
        let originalState: ResultState<T> = state
        let startDate: Date = .now
        let totalLoadingTime: TimeInterval = showLoadingAfter + minimumLoadingDuration

        let loaderTask = Task {
            guard !originalState.isSuccess || !skipLoadingWhenSuccessful else {
                return
            }
            try await Task.sleep(for: .seconds(showLoadingAfter))
            updateState(.loading)
        }

        do {
            let result: T = try await operation()
            try Task.checkCancellation()
            await handleLoaderTask(loaderTask, startDate: startDate, totalLoadingTime: totalLoadingTime)
            updateState(.success(result))
        } catch is CancellationError {
            loaderTask.cancel()
            if resetOnCancellation {
                updateState(originalState)
            }
        } catch {
            await handleLoaderTask(loaderTask, startDate: startDate, totalLoadingTime: totalLoadingTime)
            updateState(.failure(error))
        }

        return state
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

    public func reset() {
        updateState(.initial)
    }
}

extension AsyncState: Equatable {

    public static func == (lhs: AsyncState, rhs: AsyncState) -> Bool {
        lhs.state == rhs.state
    }
}
