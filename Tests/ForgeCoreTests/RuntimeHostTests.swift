// Created by Dino Catalinac on 07.10.2026.

import Testing
@testable import ForgeCore

private let previewEnvironment = ["XCODE_RUNNING_FOR_PREVIEWS": "1"]

@Test func runtimeHostIsAppWithoutPreviewsOrXCTest() {
    #expect(RuntimeHost(environment: [:], isXCTestLoaded: false) == .app)
}

@Test func runtimeHostIsTestsWhenXCTestIsLoaded() {
    #expect(RuntimeHost(environment: [:], isXCTestLoaded: true) == .tests)
}

/// XCTest's environment variables are not what decides it, since a test launch can lack them.
@Test func runtimeHostIgnoresXCTestEnvironmentVariables() {
    #expect(RuntimeHost(environment: ["XCTestConfigurationFilePath": "/tmp/config"], isXCTestLoaded: false) == .app)
}

@Test func runtimeHostIsPreviewWhenXcodeRendersPreviews() {
    #expect(RuntimeHost(environment: previewEnvironment, isXCTestLoaded: false) == .preview)
}

@Test func runtimeHostPrefersPreviewOverTests() {
    #expect(RuntimeHost(environment: previewEnvironment, isXCTestLoaded: true) == .preview)
}

@Test func runtimeHostIgnoresAPreviewVariableThatIsNotSet() {
    #expect(RuntimeHost(environment: ["XCODE_RUNNING_FOR_PREVIEWS": "0"], isXCTestLoaded: false) == .app)
}
