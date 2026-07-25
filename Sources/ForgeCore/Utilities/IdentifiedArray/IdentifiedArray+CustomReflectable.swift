//
//  IdentifiedArray+CustomReflectable.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

extension IdentifiedArray: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(self, unlabeledChildren: Array(self), displayStyle: .collection)
  }
}
