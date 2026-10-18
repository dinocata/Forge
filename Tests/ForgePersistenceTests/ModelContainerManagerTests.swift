// Created by Dino Catalinac on 18.10.2026.

import SwiftData
import Testing
@testable import ForgePersistence

struct ModelContainerManagerTests {
    @Test func preservesTheDeclaredSchemaVersion() {
        let manager = ModelContainerManager(schema: ContainerTestSchema.self, isStoredInMemoryOnly: true)

        #expect(manager.modelContainer.schema.version == ContainerTestSchema.versionIdentifier)
        #expect(manager.modelContainer === manager.modelContainer)
    }

    @Test func passesTheMigrationPlanToTheContainer() throws {
        let manager = ModelContainerManager(
            schema: ContainerTestSchema.self,
            migrationPlan: ContainerTestMigrationPlan.self,
            isStoredInMemoryOnly: true
        )

        let plan = try #require(manager.modelContainer.migrationPlan)
        #expect(ObjectIdentifier(plan) == ObjectIdentifier(ContainerTestMigrationPlan.self))
    }

    @MainActor
    @Test func deletesRecordsFromTheVersionedSchema() throws {
        let manager = ModelContainerManager(schema: ContainerTestSchema.self, isStoredInMemoryOnly: true)
        let context = manager.modelContainer.mainContext
        context.insert(ContainerTestRecord(value: "Saved value"))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<ContainerTestRecord>()) == 1)

        manager.deleteAllData()

        #expect(try context.fetchCount(FetchDescriptor<ContainerTestRecord>()) == 0)
        context.insert(ContainerTestRecord(value: "After deletion"))
        try context.save()
        #expect(try context.fetch(FetchDescriptor<ContainerTestRecord>()).map(\.value) == ["After deletion"])
    }
}

private enum ContainerTestSchema: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 3, 4)
    static var models: [any PersistentModel.Type] { [ContainerTestRecord.self] }
}

private enum ContainerTestMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ContainerTestSchema.self] }
    static var stages: [MigrationStage] { [] }
}

@Model
private final class ContainerTestRecord {
    var value: String

    init(value: String) {
        self.value = value
    }
}
