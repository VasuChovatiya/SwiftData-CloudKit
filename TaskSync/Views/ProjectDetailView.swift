import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    let project: Project

    @Environment(\.modelContext) private var context
    @State private var filter: TaskFilter = .all
    @State private var sort: TaskSort = .newest
    @State private var newTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            controls
            TaskListView(project: project, filter: filter, sort: sort)
            addBar
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Picker("Filter", selection: $filter) {
                ForEach(TaskFilter.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Sort", selection: $sort) {
                ForEach(TaskSort.allCases) { Text("Sort: \($0.rawValue)").tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var addBar: some View {
        HStack(spacing: 8) {
            TextField("Add a task", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)
                .accessibilityIdentifier("new-task-field")
            Button(action: add) { Image(systemName: "plus.circle.fill").font(.system(size: 26)) }
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add task")
        }
        .padding(12)
        .background(.bar)
    }

    private func add() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        context.insert(TaskItem(title: title, project: project))
        try? context.save()
        newTitle = ""
    }
}

/// Owns the `@Query`, which needs the filter and sort at init time.
struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskItem]

    init(project: Project, filter: TaskFilter, sort: TaskSort) {
        _tasks = Query(TaskQuery.descriptor(projectID: project.uid, filter: filter, sort: sort))
    }

    var body: some View {
        List {
            if tasks.isEmpty {
                Text("Nothing here.").font(.system(size: 13)).foregroundStyle(.secondary)
            }
            ForEach(tasks) { task in
                row(for: task)
            }
            .onDelete { offsets in
                offsets.map { tasks[$0] }.forEach(context.delete)
                try? context.save()
            }
        }
        .listStyle(.plain)
    }

    private func row(for task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                task.isDone.toggle()
                try? context.save()
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "Mark \(task.title) as open" : "Mark \(task.title) as done")

            Text(task.title)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)
            Spacer()
            priorityBadge(task.priority)
        }
        .contextMenu {
            ForEach(TaskPriority.allCases) { priority in
                Button(priority.label, systemImage: priority.symbol) {
                    task.priority = priority.rawValue
                    try? context.save()
                }
            }
        }
    }

    @ViewBuilder
    private func priorityBadge(_ value: Int) -> some View {
        if let priority = TaskPriority(rawValue: value), priority != .normal {
            HStack(spacing: 3) {
                Image(systemName: priority.symbol)
                Text(priority.label)
            }
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background((priority == .high ? Color.red : Color.gray).opacity(0.15), in: Capsule())
            .foregroundStyle(priority == .high ? .red : .secondary)
        }
    }
}
