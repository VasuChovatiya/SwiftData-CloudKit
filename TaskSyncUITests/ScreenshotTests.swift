import XCTest

/// Captures the README screenshots from the sample data. Skipped unless `TASKSYNC_CAPTURE=1`:
///
///     TEST_RUNNER_TASKSYNC_CAPTURE=1 TEST_RUNNER_TASKSYNC_CAPTURE_DIR=$PWD/Screenshots \
///       xcodebuild test -only-testing:TaskSyncUITests/ScreenshotTests ...
@MainActor
final class ScreenshotTests: XCTestCase {
    /// Attaches the screenshot to the result bundle and, when `TASKSYNC_CAPTURE_DIR` is set, also writes it
    /// there as `<name>.png` (the simulator can write to the Mac's file system).
    private func capture(_ name: String) {
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        if let directory = ProcessInfo.processInfo.environment["TASKSYNC_CAPTURE_DIR"] {
            let url = URL(fileURLWithPath: directory).appending(path: "\(name).png")
            XCTAssertNoThrow(try screenshot.pngRepresentation.write(to: url))
        }
    }

    func testCaptureScreens() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["TASKSYNC_CAPTURE"] == "1", "Set TASKSYNC_CAPTURE=1 to capture screenshots.")
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing"]
        app.launch()

        let sample = app.buttons["Load sample data"]
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        sample.tap()
        XCTAssertTrue(app.staticTexts["Website redesign"].waitForExistence(timeout: 5))
        capture("projects")

        app.staticTexts["Website redesign"].tap()
        XCTAssertTrue(app.textFields["new-task-field"].waitForExistence(timeout: 5))
        capture("tasks")

        app.buttons["Open"].tap()
        app.buttons["Sort: Priority"].tap()
        capture("open-by-priority")

        app.navigationBars.buttons.firstMatch.tap()
        let toggle = app.switches["sync-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.switches.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["sync-status"].waitForExistence(timeout: 5))
        capture("sync-without-icloud")
    }
}
