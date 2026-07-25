//
//  IdentifiedArray+Sendable.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

extension IdentifiedArray: @unchecked Sendable
where ID: Sendable, Element: Sendable {}
