import SwiftData
import SwiftUI

@main
struct TaskSyncApp: App {
    @State private var storage = Self.makeStorage()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProjectListView(storage: storage)
            }
            // Attached above the NavigationStack so pushed screens get the same container.
            .modelContainer(storage.container)
            // A new container means every @Query must be rebuilt.
            .id(storage.generation)
        }
    }

    /// `--ui-testing` gives UI tests an empty in-memory store, no saved sync setting and no iCloud.
    private static func makeStorage(arguments: [String] = CommandLine.arguments) -> StorageController {
        guard arguments.contains("--ui-testing"), let defaults = UserDefaults(suiteName: "ui-testing") else {
            return StorageController()
        }
        defaults.removePersistentDomain(forName: "ui-testing")
        return StorageController(defaults: defaults, iCloudStatus: { false }) { _ in
            try StorageController.makeContainer(.inMemory)
        }
    }
}
