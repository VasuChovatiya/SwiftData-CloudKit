import Foundation
import SwiftData
@testable import TaskSync

enum TestStore {
    static func container() throws -> ModelContainer {
        try StorageController.makeContainer(.inMemory)
    }

    /// A fresh, empty `UserDefaults` suite per test.
    static func defaults() -> UserDefaults {
        let name = "TaskSyncTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

/// Records which stores `StorageController` asks for and can be told to fail some of them.
final class ContainerFactory {
    private(set) var requests: [StorageController.StoreKind] = []
    var failing: Set<StorageController.StoreKind> = []

    struct Failure: LocalizedError {
        var errorDescription: String? { "Missing entitlement" }
    }

    func make(_ kind: StorageController.StoreKind) throws -> ModelContainer {
        requests.append(kind)
        if failing.contains(kind) { throw Failure() }
        return try TestStore.container()
    }
}
