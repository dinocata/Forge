//
//  ResultState.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//
//  iOS-only conformances (e.g. `AlertableState`) live in the Robyn target.

import Foundation

public enum ResultState<T> {
    case initial
    case loading
    case success(T)
    case failure(Error)

    public var value: T? {
        guard case .success(let value) = self else {
            return nil
        }
        return value
    }

    public var error: Error? {
        guard case .failure(let error) = self else {
            return nil
        }
        return error
    }

    public var isSuccess: Bool {
        value != nil
    }

    public var isLoading: Bool {
        guard case .loading = self else {
            return false
        }
        return true
    }

    public var isInitial: Bool {
        guard case .initial = self else {
            return false
        }
        return true
    }

    public var isFailure: Bool {
        guard case .failure = self else {
            return false
        }
        return true
    }

    public func getValue() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .initial:
            throw ResultStateError.noValue
        case .loading:
            throw ResultStateError.loading
        case .failure(let error):
            throw error
        }
    }

    public func mapToVoid() -> ResultState<Void> {
        map { _ in () }
    }

    public func map<NewSuccess>(_ transform: (T) -> NewSuccess) -> ResultState<NewSuccess> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .initial:
            return .initial
        case .loading:
            return .loading
        case .failure(let error):
            return .failure(error)
        }
    }
}

extension ResultState: Sendable where T == Sendable {}

extension ResultState: Equatable {

    public static func == (lhs: ResultState, rhs: ResultState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial), (.loading, .loading):
            return true

        case (.success(let lhs), .success(let rhs)):
            // Workaround since Swift currently does not support multiple Equatable conformances.
            if let lhsEquatable = lhs as? any Equatable,
               let rhsEquatable = rhs as? any Equatable {
                return lhsEquatable.isEqualTo(rhsEquatable)
            }
            return true

        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription

        default:
            return false
        }
    }
}

extension ResultState where T == Void {

    public static var success: ResultState<Void> {
        .success(())
    }
}
