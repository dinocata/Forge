//
//  IdentifiedArray+Hashable.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

extension IdentifiedArray: Hashable where Element: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
    hasher.combine(self.count)
    for element in self {
      hasher.combine(element)
    }
  }
}
