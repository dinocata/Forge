//
//  String+Extensions.swift
//  Forge
//
//  Created by Dino Catalinac on 08.09.2026..
//

import Foundation

public extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
