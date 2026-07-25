//
//  MinLengthValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 16.09.2025..
//

import Foundation

public struct MinLengthValidator: Validator {
    public let inputName: String
    public let minLength: Int

    public init(inputName: String, minLength: Int) {
        precondition(
            minLength >= 0,
            "MinLengthValidator: minLength for \(inputName) must be non-negative, got \(minLength)"
        )
        self.inputName = inputName
        self.minLength = minLength
    }

    public func validate(_ input: String) throws(ValidationError) {
        if input.count < minLength {
            throw .tooShort("\(inputName) must be at least \(minLength) characters")
        }
    }
}
