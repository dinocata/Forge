//
//  IdentifiedArray+Equatable.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

extension IdentifiedArray: Equatable where Element: Equatable {
  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.elements == rhs.elements
  }
}
