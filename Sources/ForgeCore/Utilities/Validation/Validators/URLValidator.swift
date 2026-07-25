//
//  URLValidator.swift
//  AppCore
//
//  Created by Ivan Matkovic on 20.11.2025..
//

import Foundation

public struct URLValidator: Validator {
    public let inputName: String
    public let requireScheme: Bool
    public let requireHost: Bool

    public init(inputName: String, requireScheme: Bool = true, requireHost: Bool = true) {
        self.inputName = inputName
        self.requireScheme = requireScheme
        self.requireHost = requireHost
    }

    public func validate(_ input: String) throws(ValidationError) {
        try RequiredValidator(inputName: inputName).validate(input)

        guard let url = URL(string: input) else {
            throw .invalidFormat("\(inputName) must be a valid URL (e.g., http://localhost:7176)")
        }

        if requireScheme && url.scheme == nil {
            throw .invalidFormat("\(inputName) must include a scheme (e.g., http:// or https://)")
        }

        if requireHost && url.host == nil {
            throw .invalidFormat("\(inputName) must include a host")
        }
    }
}
