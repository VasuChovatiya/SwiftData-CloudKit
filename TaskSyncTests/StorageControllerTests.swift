import Foundation
import Testing
@testable import TaskSync

@MainActor
struct StorageControllerTests {
    private let defaults = TestStore.defaults()
    private let factory = ContainerFactory()

    private func makeController(signedIn: Bool = true) -> StorageController {
        StorageController(defaults: defaults, iCloudStatus: { signedIn }, makeContainer: factory.make)
    }

    @Test func startsLocalWhenSyncIsOff() {
        let storage = makeController()

        #expect(factory.requests == [.local])
        #expect(!storage.isSyncing)
        #expect(storage.statusMessage == nil)
    }

    @Test func turningSyncOnOpensTheCloudStoreAndRebuildsTheQueries() {
        let storage = makeController()

        storage.setSync(true)

        #expect(factory.requests == [.local, .cloud])
        #expect(storage.isSyncing)
        #expect(storage.generation == 1)
        #expect(defaults.bool(forKey: StorageController.syncKey))
    }

    @Test func turningSyncOffGoesBackToTheLocalStore() {
        let storage = makeController()
        storage.setSync(true)

        storage.setSync(false)

        #expect(factory.requests == [.local, .cloud, .local])
        #expect(!storage.isSyncing)
        #expect(storage.generation == 2)
        #expect(!defaults.bool(forKey: StorageController.syncKey))
    }

    @Test func remembersSyncAcrossLaunches() {
        defaults.set(true, forKey: StorageController.syncKey)

        let storage = makeController()

        #expect(factory.requests == [.local, .cloud])
        #expect(storage.isSyncing)
        #expect(storage.wantsSync)
    }

    @Test func staysLocalAndExplainsWhyWhenNotSignedIntoICloud() {
        let storage = makeController(signedIn: false)

        storage.setSync(true)

        #expect(factory.requests == [.local])
        #expect(!storage.isSyncing)
        #expect(storage.wantsSync)
        #expect(storage.statusMessage?.contains("Not signed into iCloud") == true)
    }

    @Test func signingOutOfICloudStopsSyncAtNextLaunch() {
        defaults.set(true, forKey: StorageController.syncKey)

        let storage = makeController(signedIn: false)

        #expect(factory.requests == [.local])
        #expect(!storage.isSyncing)
        #expect(storage.statusMessage != nil)
    }

    @Test func aCloudStoreThatFailsKeepsTheLocalData() {
        factory.failing = [.cloud]
        let storage = makeController()

        storage.setSync(true)

        #expect(factory.requests == [.local, .cloud])
        #expect(!storage.isSyncing)
        #expect(storage.generation == 0, "The local container must stay in place")
        #expect(storage.statusMessage == "iCloud sync could not start (Missing entitlement), so data stays on this device.")
    }

    @Test func aLocalStoreThatFailsFallsBackToMemoryAndSaysSo() {
        factory.failing = [.local]

        let storage = makeController()

        #expect(factory.requests == [.local, .inMemory])
        #expect(storage.statusMessage?.contains("Changes won't be kept") == true)
    }
}
