import CoreData
import Foundation
import Observation
import SwiftData

/// Builds the `ModelContainer`, with CloudKit sync switched on or off at runtime, and reports sync events.
///
/// The local and the CloudKit configuration use the same store file, so data is always kept on the device
/// and turning sync on uploads what is already there.
@Observable
final class StorageController {
    nonisolated enum StoreKind: Hashable, Sendable {
        case local
        case cloud
        case inMemory
    }

    static let syncKey = "cloudSync"

    private(set) var container: ModelContainer
    private(set) var generation = 0
    private(set) var isSyncing = false
    private(set) var wantsSync: Bool
    private(set) var statusMessage: String?
    private(set) var lastEvent: String?

    /// True when the device is signed into iCloud. CloudKit sync cannot work without it.
    var iCloudAvailable: Bool { iCloudStatus() }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let iCloudStatus: () -> Bool
    @ObservationIgnored private let makeContainer: (StoreKind) throws -> ModelContainer
    @ObservationIgnored private var eventTask: Task<Void, Never>?

    init(
        defaults: UserDefaults = .standard,
        iCloudStatus: @escaping () -> Bool = { FileManager.default.ubiquityIdentityToken != nil },
        makeContainer: @escaping (StoreKind) throws -> ModelContainer = StorageController.makeContainer
    ) {
        self.defaults = defaults
        self.iCloudStatus = iCloudStatus
        self.makeContainer = makeContainer
        wantsSync = defaults.bool(forKey: Self.syncKey)
        let (container, message) = Self.openLocal(makeContainer)
        self.container = container
        statusMessage = message
        if wantsSync { applySyncPreference() }
        observeEvents()
    }

    deinit { eventTask?.cancel() }

    func setSync(_ enabled: Bool) {
        wantsSync = enabled
        defaults.set(enabled, forKey: Self.syncKey)
        applySyncPreference()
    }

    // MARK: - Container

    private func applySyncPreference() {
        statusMessage = nil
        guard wantsSync else {
            useLocal()
            return
        }
        guard iCloudStatus() else {
            useLocal()
            statusMessage = "Not signed into iCloud on this device, so data stays local. Sign in under Settings, then turn sync on again."
            return
        }
        guard !isSyncing else { return }
        do {
            container = try makeContainer(.cloud)
            generation += 1
            isSyncing = true
        } catch {
            statusMessage = "iCloud sync could not start (\(error.localizedDescription)), so data stays on this device."
        }
    }

    /// Switches back to the on-device store if sync was running.
    private func useLocal() {
        guard isSyncing else { return }
        let (container, message) = Self.openLocal(makeContainer)
        self.container = container
        generation += 1
        isSyncing = false
        if let message { statusMessage = message }
    }

    /// Opens the on-device store. If even that fails, falls back to memory and says that changes won't be
    /// kept, rather than losing them silently.
    private static func openLocal(_ make: (StoreKind) throws -> ModelContainer) -> (ModelContainer, String?) {
        do {
            return (try make(.local), nil)
        } catch {
            do {
                return (try make(.inMemory), "Saved data could not be opened (\(error.localizedDescription)). Changes won't be kept.")
            } catch {
                fatalError("Could not create a ModelContainer: \(error)")
            }
        }
    }

    nonisolated static func makeContainer(_ kind: StoreKind) throws -> ModelContainer {
        let schema = Schema([Project.self, TaskItem.self])
        let configuration = switch kind {
        case .local:
            ModelConfiguration("TaskSync", schema: schema, cloudKitDatabase: .none)
        case .cloud:
            ModelConfiguration("TaskSync", schema: schema, cloudKitDatabase: .private(cloudContainerID))
        case .inMemory:
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Set per build in Config/TaskSync.xcconfig (`CLOUDKIT_CONTAINER`) and read from the Info.plist.
    nonisolated static var cloudContainerID: String {
        Bundle.main.object(forInfoDictionaryKey: "CloudKitContainer") as? String ?? "iCloud.com.vasuchovatiya.TaskSync"
    }

    // MARK: - Sync events

    private func observeEvents() {
        eventTask = Task { [weak self] in
            let events = NotificationCenter.default.notifications(named: NSPersistentCloudKitContainer.eventChangedNotification)
            for await notification in events {
                let key = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                guard let event = notification.userInfo?[key] as? NSPersistentCloudKitContainer.Event else { continue }
                self?.lastEvent = Self.summary(of: event)
            }
        }
    }

    private static func summary(of event: NSPersistentCloudKitContainer.Event) -> String {
        let kind = switch event.type {
        case .setup: "Setup"
        case .import: "Import"
        case .export: "Export"
        @unknown default: "Event"
        }
        if let error = event.error { return "\(kind) failed: \(error.localizedDescription)" }
        return event.endDate == nil ? "\(kind) in progress…" : "\(kind) finished"
    }
}
