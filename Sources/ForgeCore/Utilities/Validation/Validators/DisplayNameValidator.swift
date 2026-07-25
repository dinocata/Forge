//
//  DisplayNameValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 15.09.2025..
//

import Foundation

public struct DisplayNameValidator: Validator {

    @ArrayBuilder<Validator>
    private func validators(_ inputName: String) -> [Validator] {
        RequiredValidator(inputName: inputName)
        NoSpecialCharactersValidator(inputName: inputName, allowSpaces: true)
        MaxLengthValidator(inputName: inputName, maxLength: 30)
    }

    public let inputName: String

    public init(inputName: String = "Name") {
        self.inputName = inputName
    }

    public func validate(_ input: String) throws(ValidationError) {
        for validator in validators(inputName) {
            try validator.validate(input)
        }
    }
}
