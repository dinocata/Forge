//
//  ValidationError.swift
//  AppCore
//
//  Created by Dino Catalinac on 14.04.2025..
//

import Foundation

public enum ValidationError: Error, Equatable, Sendable {
    case generic(_ message: String? = nil)
    case required(_ message: String? = nil)
    case tooShort(_ message: String? = nil)
    case tooLong(_ message: String? = nil)
    case mustStartWithLetter(_ message: String? = nil)
    case invalidFormat(_ message: String? = nil)
    case alreadyExists(_ message: String? = nil)

    public var message: String {
        switch self {
        case .generic(let message):
            return message ?? "Invalid input"
        case .required(let message):
            return message ?? "This field is required"
        case .tooShort(let message):
            return message ?? "Input is too short"
        case .tooLong(let message):
            return message ?? "Input is too long"
        case .mustStartWithLetter(let message):
            return message ?? "Input must start with a letter"
        case .invalidFormat(let message):
            return message ?? "Invalid format"
        case .alreadyExists(let message):
            return message ?? "This value is already taken"
        }
    }
}
