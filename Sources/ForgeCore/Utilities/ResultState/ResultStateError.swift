//
//  ResultStateError.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation

public enum ResultStateError: LocalizedError {
    case noValue
    case loading

    public var errorDescription: String? {
        switch self {
        case .noValue: return "No value available"
        case .loading: return "Value is currently loading"
        }
    }
}
