//
//  NoSpecialCharactersValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 16.09.2025..
//

import Foundation

public struct NoSpecialCharactersValidator: Validator {
    public let inputName: String
    public let allowSpaces: Bool

    public init(inputName: String, allowSpaces: Bool = false) {
        self.inputName = inputName
        self.allowSpaces = allowSpaces
    }

    public func validate(_ input: String) throws(ValidationError) {
        let specialCharacters = allowSpaces ? " -_" : "-_"
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: specialCharacters))

        if input.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            let message = allowSpaces
                ? "\(inputName) can only contain letters, numbers, spaces, hyphens, and underscores"
                : "\(inputName) can only contain letters, numbers, hyphens, and underscores"
            throw .invalidFormat(message)
        }
    }
}
