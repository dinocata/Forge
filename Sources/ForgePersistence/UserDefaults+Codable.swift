//
//  UserDefaults+Codable.swift
//  AppCore
//
//  Created by Dino Catalinac on 10.07.2025..
//

import Foundation
import ForgeCore
import os

public extension UserDefaults {

    func getCodable<Value: Codable & Equatable>(
        _ key: String,
        defaultValue: Value? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> Value? {
        guard let object: Any = object(forKey: key) else {
            return defaultValue
        }

        guard let data: Data = object as? Data else {
            return object as? Value ?? defaultValue
        }

        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            os_log(
                "UserDefaults decode failed for key %{public}@ as %{public}@: %{public}@",
                type: .error,
                key,
                String(describing: Value.self),
                String(describing: error)
            )
            removeObject(forKey: key)
            return defaultValue
        }
    }

    @discardableResult
    func storeCodable<Value: Codable & Equatable>(
        _ value: Value,
        forKey key: String,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) -> Bool {
        let oldValue: Value? = getCodable(key, decoder: decoder)

        guard value != oldValue else {
            return false
        }

        if let optional = value as? AnyOptional, optional.isNone {
            removeObject(forKey: key)
            return true
        } else {
            do {
                let data: Data = try encoder.encode(value)
                set(data, forKey: key)
                return true
            } catch {
                os_log(
                    "UserDefaults encode failed for key %{public}@ as %{public}@: %{public}@",
                    type: .error,
                    key,
                    String(describing: Value.self),
                    String(describing: error)
                )
                return false
            }
        }
    }
}
