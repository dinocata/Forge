//
//  StartWithLetterValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 16.09.2025..
//

import Foundation

public struct StartWithLetterValidator: Validator {
    public let inputName: String

    public init(inputName: String) {
        self.inputName = inputName
    }

    public func validate(_ input: String) throws(ValidationError) {
        if input.first?.isLetter != true {
            throw .mustStartWithLetter("\(inputName) must start with a letter!")
        }
    }
}
