//
//  IdentifiedArray+CustomStringConvertible.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

extension IdentifiedArray: CustomStringConvertible {
  public var description: String {
    var result = "["
    var first = true
    for item in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(item, terminator: "", to: &result)
    }
    result += "]"
    return result
  }
}
