//
//  Validator.swift
//  AppCore
//
//  Created by Dino Catalinac on 14.04.2025..
//

import Foundation

public protocol Validator: Sendable {
    func validate(_ input: String) throws(ValidationError)
}
