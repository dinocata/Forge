//
//  IdentifiedArray+ExpressibleByArrayLiteral.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension IdentifiedArray: ExpressibleByArrayLiteral where Element: Identifiable, ID == Element.ID {
  @inlinable
  public init(arrayLiteral elements: Element...) {
    self.init(uniqueElements: elements)
  }
}
