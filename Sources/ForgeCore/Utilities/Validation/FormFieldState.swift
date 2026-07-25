//
//  FormFieldState.swift
//  AppCore
//
//  Created by Ivan Matkovic on 21.04.2025..
//
//  Visual state for form fields driven by validation outcomes. Set on
//  the SwiftUI environment via `.formFieldState(_:)` — form components
//  (text fields, checkboxes, etc.) read it from `@Environment(\.formFieldState)`
//  to style themselves.

import SwiftUI

public enum FormFieldState: Equatable, Sendable {
    case normal
    case success
    case loading
    case info(ValidationError)
    case error(ValidationError)

    public var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }

    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    public var validationInfoMessage: String? {
        switch self {
        case .info(let validationError):
            return validationError.message
        default:
            return nil
        }
    }

    public var validationErrorMessage: String? {
        switch self {
        case .error(let validationError):
            return validationError.message
        default:
            return nil
        }
    }
}

// MARK: - SwiftUI Environment

public extension EnvironmentValues {

    @Entry var formFieldState: FormFieldState = .normal
}

public extension View {

    func formFieldState(_ formFieldState: FormFieldState) -> some View {
        environment(\.formFieldState, formFieldState)
    }
}
