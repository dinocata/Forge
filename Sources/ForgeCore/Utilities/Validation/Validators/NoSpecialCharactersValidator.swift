//
//  NoSpecialCharactersValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 16.09.2025..
//

import Foundation

/// Accepts letters and numbers, plus whichever punctuation ``allowedCharacters`` names.
public struct NoSpecialCharactersValidator: Validator {

    /// A character beyond letters and numbers that an input may contain.
    public enum AllowedCharacter: CaseIterable, Sendable {
        case space
        case hyphen
        case underscore

        /// The straight `'` and the typographic `’` the iOS keyboard types by default.
        case apostrophe

        /// Both `(` and `)`.
        case parenthesis

        var characters: String {
            switch self {
            case .space: " "
            case .hyphen: "-"
            case .underscore: "_"
            case .apostrophe: "'’"
            case .parenthesis: "()"
            }
        }

        var pluralName: String {
            switch self {
            case .space: "spaces"
            case .hyphen: "hyphens"
            case .underscore: "underscores"
            case .apostrophe: "apostrophes"
            case .parenthesis: "parentheses"
            }
        }
    }

    public let inputName: String
    public let allowedCharacters: Set<AllowedCharacter>

    public init(inputName: String, allowing allowedCharacters: Set<AllowedCharacter> = [.hyphen, .underscore]) {
        self.inputName = inputName
        self.allowedCharacters = allowedCharacters
    }

    public func validate(_ input: String) throws(ValidationError) {
        let allowed = AllowedCharacter.allCases.filter(allowedCharacters.contains)
        let permitted = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: allowed.map(\.characters).joined()))

        if input.rangeOfCharacter(from: permitted.inverted) != nil {
            throw .invalidFormat("\(inputName) can only contain \(Self.list(["letters", "numbers"] + allowed.map(\.pluralName)))")
        }
    }

    /// `letters and numbers`, or `letters, numbers, and spaces` — the wording the message always had.
    private static func list(_ names: [String]) -> String {
        guard names.count > 2, let last = names.last else { return names.joined(separator: " and ") }

        return names.dropLast().joined(separator: ", ") + ", and " + last
    }
}
