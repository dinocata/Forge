//
//  RequiredValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 16.09.2025..
//

import Foundation

public struct RequiredValidator: Validator {
    public let inputName: String

    public init(inputName: String) {
        self.inputName = inputName
    }

    public func validate(_ input: String) throws(ValidationError) {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw .required("\(inputName) is required")
        }
    }
}
