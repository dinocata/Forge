//
//  AsyncValidator.swift
//  AppCore
//
//  Created by Dino Catalinac on 16.09.2025..
//

import Foundation

public protocol AsyncValidator: Validator {
    func validateAsync(_ input: String) async throws(ValidationError)
}
