// Created by Dino Catalinac on 19.08.2026.

import Foundation

public extension Bundle {

    /// The app's display name, falling back to its bundle name.
    ///
    /// `nil` for a bundle carrying neither key, which in practice means a test
    /// bundle. A caller that needs a guaranteed name supplies its own fallback,
    /// since only it knows what the app is called.
    var appName: String? {
        let displayName = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = object(forInfoDictionaryKey: "CFBundleName") as? String

        return displayName ?? bundleName
    }

    /// Marketing version and build, e.g. `1.4.0 (212)`.
    ///
    /// Falls back to the version alone where there is no build number, and to
    /// `nil` where there is neither. Diagnostic only — nothing should branch on it.
    var appVersion: String? {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String

        return switch (version, build) {
        case (let version?, let build?): "\(version) (\(build))"
        case (let version?, nil): version
        default: nil
        }
    }
}
