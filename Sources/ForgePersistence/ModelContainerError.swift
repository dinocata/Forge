//
//  ModelContainerError.swift
//  AppCore
//
//  Created by Dino Catalinac on 21.11.2025..
//

import Foundation

public enum ModelContainerError: Error {
    case configurationFailed(Error)
    case deleteDataFailed(Error)
}
