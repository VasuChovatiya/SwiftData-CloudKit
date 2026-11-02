import SwiftData
import SwiftUI

struct ProjectListView: View {
    let storage: StorageController
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.createdAt) private var projects: [Project]
    /// Navigation is keyed on the project's stable `uid`, not the model object, whose identity can change after a save.
    @State private var selectedID: UUID?
    @State private var newName = ""

    var body: some View {
        List {
            syncSection

            Section("Projects") {
                if projects.isEmpty {
                    Text("No projects yet. Add one below or load sample data.")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
                ForEach(projects) { project in
                    Button { selectedID = project.uid } label: { row(for: project) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    offsets.map { projects[$0] }.forEach(context.delete)
                    try? context.save()
                }

                HStack {
                    TextField("New project", text: $newName)
                        .onSubmit(addProject)
                        .accessibilityIdentifier("new-project-field")
                    Button("Add", action: addProject)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("add-project-button")
                }
            }

            Section {
                Button("Load sample data") { SampleData.seed(context) }
                    .disabled(!projects.isEmpty)
            }
        }
        .navigationTitle("Projects")
        .navigationDestination(item: $selectedID) { id in
            if let project = projects.first(where: { $0.uid == id }) {
                ProjectDetailView(project: project)
            }
        }
    }

    // MARK: - Sync

    private var syncSection: some View {
        Section {
            Toggle(isOn: Binding(get: { storage.wantsSync }, set: { storage.setSync($0) })) {
                Label("iCloud sync", systemImage: storage.isSyncing ? "icloud.fill" : "icloud.slash")
            }
            .accessibilityIdentifier("sync-toggle")
            HStack {
                Text("iCloud account").foregroundStyle(.secondary)
                Spacer()
                Text(storage.iCloudAvailable ? "Signed in" : "Not signed in")
                    .foregroundStyle(storage.iCloudAvailable ? .green : .orange)
            }
            .font(.system(size: 13))
            if let event = storage.lastEvent {
                Text("Last sync event: \(event)").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            if let message = storage.statusMessage {
                Label(message, systemImage: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("sync-status")
            }
        } header: {
            Text("Sync")
        } footer: {
            Text("Data is always saved on this device. With sync on and the same iCloud account on two devices, edits show up on both.")
        }
    }

    // MARK: - Rows

    private func row(for project: Project) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundStyle(Color.named(project.colorName))
                .frame(width: 34, height: 34)
                .background(Color.named(project.colorName).opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name).font(.system(size: 15, weight: .semibold))
                Text("\(project.openCount) open of \(project.totalCount)").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func addProject() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let colors = ["indigo", "teal", "orange", "pink", "green"]
        context.insert(Project(name: name, colorName: colors[projects.count % colors.count]))
        try? context.save()
        newName = ""
    }
}

extension Color {
    static func named(_ name: String) -> Color {
        switch name {
        case "teal": .teal
        case "orange": .orange
        case "pink": .pink
        case "green": .green
        default: .indigo
        }
    }
}

#Preview {
    let storage = StorageController(defaults: UserDefaults(suiteName: "preview") ?? .standard, iCloudStatus: { false }) { _ in
        try StorageController.makeContainer(.inMemory)
    }
    SampleData.seed(storage.container.mainContext)
    return NavigationStack { ProjectListView(storage: storage) }
        .modelContainer(storage.container)
}
