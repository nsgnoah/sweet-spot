import XCTest

/// Opens a puzzle in landscape and rotates back to portrait mid-game.
final class LandscapeTests: XCTestCase {
    func testGameWorksInLandscape() throws {
        let app = XCUIApplication()
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        // First launch shows How to play; close it.
        if app.staticTexts["The idea"].waitForExistence(timeout: 3) {
            app.swipeDown(velocity: .fast)
        }

        app.buttons["Play"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Submit"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Mystery category"].firstMatch.exists)

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["Submit"].waitForExistence(timeout: 5))
    }
}
