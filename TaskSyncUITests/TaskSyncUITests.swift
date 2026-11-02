import XCTest

/// End-to-end flow on an empty in-memory store, so runs never see each other's data.
@MainActor
final class TaskSyncUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing"]
        app.launch()
        return app
    }

    func testAddAProjectAndTasksThenFilterOpenTasks() {
        let app = launch()

        let projectField = app.textFields["new-project-field"]
        XCTAssertTrue(projectField.waitForExistence(timeout: 5))
        projectField.tap()
        projectField.typeText("Groceries")
        app.buttons["add-project-button"].tap()

        let project = app.staticTexts["Groceries"]
        XCTAssertTrue(project.waitForExistence(timeout: 5))
        project.tap()

        let taskField = app.textFields["new-task-field"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 5))
        for title in ["Milk", "Bread"] {
            taskField.tap()
            taskField.typeText(title + "\n")
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
        }

        app.buttons["Mark Milk as done"].tap()
        app.buttons["Open"].tap()
        XCTAssertTrue(app.staticTexts["Bread"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Milk"].exists)

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["1 open of 2"].waitForExistence(timeout: 5))
    }

    func testSyncStaysOffWithoutICloud() {
        let app = launch()

        let toggle = app.switches["sync-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.switches.firstMatch.tap()

        let status = app.staticTexts["sync-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Not signed into iCloud"))
    }
}
