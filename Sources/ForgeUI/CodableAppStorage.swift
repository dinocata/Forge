// Created by Dino Catalinac on 25.08.2026.

import Foundation
import ForgePersistence
import SwiftUI

/// A SwiftUI dynamic property that persists a Codable value in `UserDefaults`.
///
/// Like `AppStorage`, the property invalidates its enclosing view when the stored value changes.
/// Values are encoded as JSON data, allowing application-owned value types to participate without
/// adding `RawRepresentable` storage glue solely for SwiftUI observation.
@propertyWrapper
@MainActor
public struct CodableAppStorage<Value: Codable & Equatable & Sendable>: DynamicProperty {
    @AppStorage private var observedData: Data?

    private let defaultValue: Value
    private let key: String
    private let store: UserDefaults

    public init(
        wrappedValue defaultValue: Value,
        _ key: String,
        store: UserDefaults? = nil
    ) {
        self.defaultValue = defaultValue
        self.key = key
        self.store = store ?? .standard
        _observedData = AppStorage(key, store: store)
    }

    public var wrappedValue: Value {
        get {
            // Reading the AppStorage value registers this dynamic property with SwiftUI. Codable
            // decoding remains owned by ForgePersistence rather than being duplicated here.
            _ = observedData
            return store.getCodable(key, defaultValue: defaultValue) ?? defaultValue
        }
        nonmutating set {
            store.storeCodable(newValue, forKey: key)
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}
