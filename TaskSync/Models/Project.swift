import Foundation
import SwiftData

// CloudKit sync rules honoured here: every property has a default, relationships are optional
// with an inverse, and there are no unique constraints.

@Model
final class Project {
    var name: String = ""
    var colorName: String = "indigo"
    var createdAt: Date = Date.now
    /// Stable id used to fetch a project's tasks with a predicate (not a unique constraint, which CloudKit forbids).
    var uid: UUID = UUID()

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.project)
    var tasks: [TaskItem]? = []

    init(name: String, colorName: String = "indigo") {
        self.name = name
        self.colorName = colorName
    }

    var openCount: Int { (tasks ?? []).filter { !$0.isDone }.count }
    var totalCount: Int { (tasks ?? []).count }
}

@Model
final class TaskItem {
    var title: String = ""
    var notes: String = ""
    var isDone: Bool = false
    var priority: Int = 1
    var createdAt: Date = Date.now
    var project: Project?

    init(title: String, priority: Int = 1, project: Project? = nil) {
        self.title = title
        self.priority = priority
        self.project = project
    }
}

enum TaskPriority: Int, CaseIterable, Identifiable {
    case low = 0, normal = 1, high = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }

    var symbol: String {
        switch self {
        case .low: "arrow.down"
        case .normal: "minus"
        case .high: "exclamationmark"
        }
    }
}
