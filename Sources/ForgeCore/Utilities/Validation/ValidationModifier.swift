//
//  ValidationModifier.swift
//  AppCore
//
//  Created by Dino Catalinac on 14.04.2025..
//
//  SwiftUI view modifier that provides real-time validation for text
//  input fields. Cross-platform — SwiftUI, the Validator framework, and
//  `FormFieldState` all live in AppCore now.

import SwiftUI

/// A SwiftUI view modifier that provides real-time validation for text input fields.
///
/// This modifier automatically validates text input as the user types, providing visual feedback
/// through form field states (normal, loading, success, error). It supports both local and remote
/// validation with debouncing to prevent excessive API calls.
///
/// The modifier integrates with the app's validation system to provide:
/// - Real-time validation feedback
/// - Debounced remote validation (400ms delay)
/// - Automatic state transitions with smooth animations
/// - Auto-reset of success states after 3 seconds
/// - Form-level validation state tracking via preference keys
///
/// ## Usage
/// ```swift
/// InputField("Username", text: $username)
///     .wrapInFormContainer(label: "Username")
///     .validate(username, with: UsernameValidator(...))
/// ```
private struct ValidationModifier: ViewModifier {

    let text: String
    let validators: [any Validator]
    let errorAsInfoText: Bool
    let validateImmediately: Bool
    let shouldReset: Bool
    let onValidationStateUpdate: ((FormFieldState) -> Void)?

    @State private var isModified: Bool = false
    @State private var validationState: AsyncState<Void> = .init(animation: .spring(duration: 0.3))

    private var formFieldState: FormFieldState {
        guard isModified else {
            return .normal
        }

        switch validationState.state {
        case .initial, .loading:
            return .normal
        case .success:
            return .success
        case .failure(let validationError as ValidationError):
            switch validationError {
            case .alreadyExists:
                return .error(validationError)
            default:
                return errorAsInfoText ? .info(validationError) : .error(validationError)
            }
        case .failure:
            return errorAsInfoText ? .info(.generic()) : .error(.generic())
        }
    }

    func body(content: Content) -> some View {
        content
            .formFieldState(formFieldState)
            .task(id: text) {
                guard isModified || validateImmediately else {
                    isModified = true
                    return
                }

                isModified = true

                guard performValidation() else {
                    return
                }

                await performAsyncValidation()
            }
            .animation(.spring(duration: 0.3), value: formFieldState)
            .preference(
                key: ValidationStatePreferenceKey.self,
                value: validationState.isLoading || validationState.isFailure
            )
            .onChange(of: shouldReset) { _, newValue in
                guard newValue else {
                    return
                }

                guard isModified || !validationState.isInitial else {
                    return
                }

                isModified = false
                validationState.reset()
            }
            .onChange(of: formFieldState) { _, newValue in
                onValidationStateUpdate?(newValue)
            }
    }

    private func performValidation() -> Bool {
        do {
            for validator in validators {
                try validator.validate(text)
            }

            return true
        } catch {
            validationState.updateState(.failure(error))
            return false
        }
    }

    private func performAsyncValidation() async {
        let asyncValidators: [AsyncValidator] = validators.compactMap { $0 as? AsyncValidator }
        guard !asyncValidators.isEmpty else {
            validationState.updateState(.success)
            return
        }

        await validationState.perform(showLoadingAfter: 0, skipLoadingWhenSuccessful: false, resetOnCancellation: false) {
            for validator in asyncValidators {
                try await validator.validateAsync(text)
            }
        }
    }
}

public extension View {
    /// Applies real-time validation to a view with the specified validators.
    ///
    /// This method creates a validation modifier that automatically validates the provided text
    /// as the user types. The validation runs through all provided validators sequentially,
    /// stopping at the first validation error encountered.
    ///
    /// - Parameters:
    ///   - text: The text to validate
    ///   - validators: One or more validators to apply to the text
    ///   - errorAsInfoText: If true, validation errors are displayed as info text rather than error text
    ///   - shouldReset: Set this to true to reset the validation state back to neutral
    /// - Returns: A view with validation applied
    func validate(
        _ text: String,
        with validators: any Validator...,
        errorAsInfoText: Bool = false,
        validateImmediately: Bool = false,
        shouldReset: Bool = false,
        onValidationStateUpdate: ((FormFieldState) -> Void)? = nil
    ) -> some View {
        modifier(
            ValidationModifier(
                text: text,
                validators: validators,
                errorAsInfoText: errorAsInfoText,
                validateImmediately: validateImmediately,
                shouldReset: shouldReset,
                onValidationStateUpdate: onValidationStateUpdate
            )
        )
    }
}
