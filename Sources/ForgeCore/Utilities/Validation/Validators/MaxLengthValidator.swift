//
//  MaxLengthValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 16.09.2025..
//

import Foundation

public struct MaxLengthValidator: Validator {
    public let inputName: String
    public let maxLength: Int

    public init(inputName: String, maxLength: Int) {
        precondition(maxLength >= 0, "MaxLengthValidator: maxLength must be non-negative")
        self.inputName = inputName
        self.maxLength = maxLength
    }

    public func validate(_ input: String) throws(ValidationError) {
        if input.count > maxLength {
            throw .tooLong("\(inputName) must be \(maxLength) characters or less")
        }
    }
}
