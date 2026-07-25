//
//  Router.swift
//  AppUI
//
//  Created by Dino Čatalinac on 20.05.2026..
//

import ForgeCore
import SwiftUI
import os

@MainActor
public protocol RouterType {
    associatedtype Destination: DestinationType
    func push(_ destination: Destination)
    func presentSheet(_ destination: Destination)
    #if os(iOS)
    func presentFullscreenCover(_ destination: Destination)
    #endif
    func pop()
    func popToRoot()
    func dismiss()
    func reset()
}

private enum NavigationLog {
    static let logger = os.Logger(subsystem: "io.robinhealth.AppUI", category: "Navigation")
}

@Observable
public final class Router<Destination: DestinationType>: RouterType {

    public var navigationStack: [Destination] {
        @ArrayBuilder<Destination>
        get {
            root
            path
        }
        set {
            guard let rootDestination = newValue.first else {
                assertionFailure("Navigation stack cannot be empty.")
                return
            }

            self.root = rootDestination

            if newValue.count > 1 {
                self.path = newValue.dropFirst().asArray
            } else {
                self.path = []
            }
        }
    }

    public var root: Destination
    public var path: [Destination]

    public var presentedSheet: Destination?
    #if os(iOS)
    public var presentedFullscreenCover: Destination?
    #endif
    public var shouldDismiss: Bool = false

    public var currentDestination: Destination {
        if let presentedSheet {
            return presentedSheet
        }

        #if os(iOS)
        if let presentedFullscreenCover {
            return presentedFullscreenCover
        }
        #endif

        return navigationStack.last.forceUnwrap
    }

    public var canGoBack: Bool {
        !path.isEmpty
    }

    public init(root: Destination, path: [Destination] = []) {
        self.root = root
        self.path = path
    }

    public func push(_ destination: Destination) {
        guard destination != root else {
            NavigationLog.logger.fault("Cannot push root destination.")
            assertionFailure("Cannot push root destination.")
            return
        }

        guard destination != currentDestination else {
            return
        }

        path.append(destination)
    }

    public func presentSheet(_ destination: Destination) {
        guard checkPresentedSheet(destination) else {
            return
        }

        #if os(iOS)
        presentedFullscreenCover = nil
        #endif
        presentedSheet = destination
    }

    #if os(iOS)
    public func presentFullscreenCover(_ destination: Destination) {
        guard checkPresentedSheet(destination) else {
            return
        }

        presentedSheet = nil
        presentedFullscreenCover = destination
    }
    #endif

    public func pop() {
        guard !path.isEmpty else {
            return
        }

        path.removeLast()
    }

    public func popToRoot() {
        guard !path.isEmpty else {
            return
        }

        path.removeLast(path.count)
    }

    public func dismiss() {
        if presentedSheet.isSome {
            presentedSheet = nil
        } else {
            #if os(iOS)
            if presentedFullscreenCover.isSome {
                presentedFullscreenCover = nil
                return
            }
            #endif
            shouldDismiss = true
        }
    }

    public func reset() {
        shouldDismiss = false
        presentedSheet = nil
        #if os(iOS)
        presentedFullscreenCover = nil
        #endif
        popToRoot()
    }

    private func checkPresentedSheet(_ destination: Destination) -> Bool {
        guard destination != root else {
            NavigationLog.logger.fault("Cannot present root destination.")
            assertionFailure("Cannot present root destination.")
            return false
        }

        guard destination != currentDestination else {
            return false
        }

        return true
    }
}
