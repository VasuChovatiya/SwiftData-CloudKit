import Foundation
import SwiftData

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All", open = "Open", done = "Done"
    var id: String { rawValue }
}

enum TaskSort: String, CaseIterable, Identifiable {
    case newest = "Newest", priority = "Priority"
    var id: String { rawValue }
}

/// The task list's filter and sort, kept out of the view so they can be tested against a real store.
enum TaskQuery {
    /// Matches on the project's `uid` attribute: a predicate can't compare model references directly.
    static func predicate(projectID: UUID, filter: TaskFilter) -> Predicate<TaskItem> {
        switch filter {
        case .all:
            return #Predicate<TaskItem> { $0.project?.uid == projectID }
        case .open:
            return #Predicate<TaskItem> { $0.project?.uid == projectID && $0.isDone == false }
        case .done:
            return #Predicate<TaskItem> { $0.project?.uid == projectID && $0.isDone == true }
        }
    }

    static func sortDescriptors(_ sort: TaskSort) -> [SortDescriptor<TaskItem>] {
        switch sort {
        case .newest: [SortDescriptor(\.createdAt, order: .reverse)]
        case .priority: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.createdAt)]
        }
    }

    static func descriptor(projectID: UUID, filter: TaskFilter, sort: TaskSort) -> FetchDescriptor<TaskItem> {
        FetchDescriptor(predicate: predicate(projectID: projectID, filter: filter), sortBy: sortDescriptors(sort))
    }
}
