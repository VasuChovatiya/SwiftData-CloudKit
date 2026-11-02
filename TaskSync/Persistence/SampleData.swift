import SwiftData

enum SampleData {
    static func seed(_ context: ModelContext) {
        let website = Project(name: "Website redesign", colorName: "indigo")
        let trip = Project(name: "Trip planning", colorName: "teal")
        let home = Project(name: "Home projects", colorName: "orange")
        [website, trip, home].forEach(context.insert)

        let items: [(String, Int, Bool, Project)] = [
            ("Audit current pages", 2, true, website),
            ("Draft new navigation", 2, false, website),
            ("Pick a type scale", 1, false, website),
            ("Review with the client", 0, false, website),
            ("Book flights", 2, true, trip),
            ("Reserve the hotel", 1, false, trip),
            ("Plan day trips", 0, false, trip),
            ("Fix the leaking tap", 2, false, home),
            ("Order shelves", 1, true, home)
        ]
        for (title, priority, done, project) in items {
            let task = TaskItem(title: title, priority: priority, project: project)
            task.isDone = done
            context.insert(task)
        }
        try? context.save()
    }
}
