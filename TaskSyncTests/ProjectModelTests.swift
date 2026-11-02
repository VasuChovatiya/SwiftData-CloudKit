import Foundation
import SwiftData
import Testing
@testable import TaskSync

@MainActor
struct ProjectModelTests {
    /// Held for the whole test: a `ModelContext` stops working once its container is released.
    private let container: ModelContainer

    init() throws {
        container = try TestStore.container()
    }

    @Test func countsOpenAndTotalTasks() throws {
        let context = container.mainContext
        let project = Project(name: "Home")
        context.insert(project)
        for (title, done) in [("Fix tap", false), ("Order shelves", true), ("Paint door", false)] {
            let task = TaskItem(title: title, project: project)
            task.isDone = done
            context.insert(task)
        }
        try context.save()

        #expect(project.totalCount == 3)
        #expect(project.openCount == 2)
    }

    @Test func deletingAProjectDeletesItsTasks() throws {
        let context = container.mainContext
        let keep = Project(name: "Keep")
        let remove = Project(name: "Remove")
        context.insert(keep)
        context.insert(remove)
        context.insert(TaskItem(title: "Stays", project: keep))
        context.insert(TaskItem(title: "Goes", project: remove))
        context.insert(TaskItem(title: "Goes too", project: remove))
        try context.save()

        context.delete(remove)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<TaskItem>()).map(\.title) == ["Stays"])
    }

    /// CloudKit rejects models with required values or unique constraints, so every model must build with
    /// nothing but defaults.
    @Test func modelsFollowTheCloudKitRules() throws {
        let project = Project(name: "")
        #expect(project.tasks?.isEmpty == true)
        #expect(TaskItem(title: "").project == nil)
        #expect(Project(name: "A").uid != Project(name: "A").uid)
    }

    @Test func sampleDataSeedsThreeProjects() throws {
        let context = container.mainContext

        SampleData.seed(context)

        let projects = try context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)]))
        #expect(projects.map(\.name) == ["Home projects", "Trip planning", "Website redesign"])
        #expect(projects.map(\.totalCount) == [2, 3, 4])
        #expect(projects.map(\.openCount) == [1, 2, 3])
    }

    @Test(arguments: [(0, "Low"), (1, "Normal"), (2, "High")])
    func priorityLabels(raw: Int, label: String) {
        #expect(TaskPriority(rawValue: raw)?.label == label)
    }
}
