//
//  ModelContainerManager.swift
//  AppCore
//
//  Created by Dino Catalinac on 15.09.2025..
//

import Foundation
import ForgeCore
import SwiftData

public protocol ModelContainerManagerProtocol: Sendable {
    var modelContainer: ModelContainer { get }

    @MainActor
    func deleteAllData()
}

public final class ModelContainerManager: @unchecked Sendable, ModelContainerManagerProtocol {

    private let models: [any PersistentModel.Type]
    private let isStoredInMemoryOnly: Bool
    private let logger: ForgeLogger?
    private var _modelContainer: ModelContainer?
    private let lock: NSLock = .init()

    public init(
        models: [any PersistentModel.Type],
        isStoredInMemoryOnly: Bool = false,
        logger: ForgeLogger? = nil
    ) {
        self.models = models
        self.logger = logger
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
    }

    public var modelContainer: ModelContainer {
        lock.lock()
        defer { lock.unlock() }

        if let _modelContainer {
            return _modelContainer
        }

        let modelContainer = configure()
        _modelContainer = modelContainer
        return modelContainer
    }

    public func deleteAllData() {
        lock.lock()
        defer { lock.unlock() }

        guard let container = _modelContainer else {
            return
        }

        do {
            for model in models {
                try container.mainContext.delete(model: model)
            }

            try container.mainContext.save()
        } catch {
            logger?.capture(
                error: ModelContainerError.deleteDataFailed(error),
                message: "Could not delete data from the model container: \(error.localizedDescription)"
            )
        }
    }

    private func configure() -> ModelContainer {
        do {
            return try makeContainer(isStoredInMemoryOnly: isStoredInMemoryOnly)
        } catch {
            logger?.capture(
                error: ModelContainerError.configurationFailed(error),
                message: "Failed to load model container: \(error.localizedDescription)."
            )
            fatalError("Cannot configure model container: \(error)")
        }
    }

    private func makeContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logger?.capture(
                error: ModelContainerError.configurationFailed(error),
                message: """
                Failed to load model container: \(error.localizedDescription). \
                Attempting to remove db file and reload...
                """
            )

            try? FileManager.default.removeItem(at: configuration.url)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
    }
}
