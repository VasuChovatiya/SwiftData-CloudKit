import Foundation
import SwiftData
import Testing
@testable import TaskSync

@MainActor
struct TaskQueryTests {
    private let container: ModelContainer
    private let website: Project
    private let trip: Project

    init() throws {
        container = try TestStore.container()
        let context = container.mainContext
        website = Project(name: "Website")
        trip = Project(name: "Trip")
        context.insert(website)
        context.insert(trip)
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let tasks: [(String, Int, Bool, Project)] = [
            ("Audit pages", 1, true, website),
            ("Draft navigation", 2, false, website),
            ("Pick a type scale", 0, false, website),
            ("Review with client", 2, false, website),
            ("Book flights", 2, false, trip),
        ]
        for (offset, (title, priority, done, project)) in tasks.enumerated() {
            let task = TaskItem(title: title, priority: priority, project: project)
            task.isDone = done
            task.createdAt = start.addingTimeInterval(Double(offset) * 60)
            context.insert(task)
        }
        try context.save()
    }

    private func titles(_ filter: TaskFilter, _ sort: TaskSort = .newest, in project: Project? = nil) throws -> [String] {
        let descriptor = TaskQuery.descriptor(projectID: (project ?? website).uid, filter: filter, sort: sort)
        return try container.mainContext.fetch(descriptor).map(\.title)
    }

    @Test func allIsNewestFirstAndOnlyThisProject() throws {
        #expect(try titles(.all) == ["Review with client", "Pick a type scale", "Draft navigation", "Audit pages"])
        #expect(try titles(.all, in: trip) == ["Book flights"])
    }

    @Test func openAndDoneSplitTheTasks() throws {
        #expect(try titles(.open) == ["Review with client", "Pick a type scale", "Draft navigation"])
        #expect(try titles(.done) == ["Audit pages"])
    }

    @Test func prioritySortPutsHighFirstThenOldestFirst() throws {
        #expect(try titles(.all, .priority) == ["Draft navigation", "Review with client", "Audit pages", "Pick a type scale"])
    }

    @Test func completingATaskMovesItFromOpenToDone() throws {
        let task = try #require(website.tasks?.first { $0.title == "Draft navigation" })
        task.isDone = true
        try container.mainContext.save()

        #expect(try !titles(.open).contains("Draft navigation"))
        #expect(try titles(.done).contains("Draft navigation"))
    }
}
