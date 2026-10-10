// Created by Dino Catalinac on 10.10.2026.

import Foundation

/// An error whose `errorDescription` is written for the user, so it can be shown as it is.
///
/// Conformance is a deliberate choice, made per error type. An error that does not conform should be
/// shown behind a generic message and logged in full, since its description is written for developers.
public protocol UserFacingError: LocalizedError {}
