// Created by Dino Catalinac on 07.10.2026.

import Foundation

/// What launched the current process: the app itself, a test run, or Xcode's SwiftUI previews.
///
/// Check `RuntimeHost.current == .app` before anything that should only happen in real use, such as
/// reporting analytics or crashes, so test runs and previews stay silent.
public enum RuntimeHost: Sendable {
    /// The app, run by a person or the system.
    case app
    /// A test run hosting the app, or a test bundle.
    case tests
    /// Xcode rendering SwiftUI previews.
    case preview

    /// The host of this process, which does not change while it runs.
    public static let current = RuntimeHost(
        environment: ProcessInfo.processInfo.environment,
        isXCTestLoaded: NSClassFromString("XCTestCase") != nil
    )

    /// Previews come first because they are the more specific host. Tests are recognised by XCTest
    /// being loaded rather than by its environment variables, which a test launch can lack.
    init(environment: [String: String], isXCTestLoaded: Bool) {
        if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self = .preview
        } else {
            self = isXCTestLoaded ? .tests : .app
        }
    }
}
