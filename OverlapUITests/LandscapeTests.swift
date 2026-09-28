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

        openFreshPuzzle(app)
        XCTAssertTrue(app.buttons["Submit"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Mystery category'")).firstMatch.exists)

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["Submit"].waitForExistence(timeout: 5))
    }

    /// Drags a word onto the center of the board, in landscape on iPad (the side-by-side layout)
    /// and in portrait on iPhone.
    func testDragWordOntoBoard() throws {
        let app = XCUIApplication()
        app.launch()
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        if pad { XCUIDevice.shared.orientation = .landscapeLeft }
        defer { XCUIDevice.shared.orientation = .portrait }

        if app.staticTexts["The idea"].waitForExistence(timeout: 3) {
            app.swipeDown(velocity: .fast)
        }
        openFreshPuzzle(app)

        let center = app.buttons["Empty spot, all three circles"]
        XCTAssertTrue(center.waitForExistence(timeout: 5))
        let word = app.buttons.matching(NSPredicate(format: "label MATCHES %@", "^[A-Z][A-Z '-]+$")).firstMatch
        XCTAssertTrue(word.exists)
        let label = word.label

        word.press(forDuration: 0.1, thenDragTo: center, withVelocity: .slow, thenHoldForDuration: 0.3)

        let placed = app.buttons.matching(NSPredicate(format: "label == %@ AND value BEGINSWITH 'all three circles'", label)).firstMatch
        XCTAssertTrue(placed.waitForExistence(timeout: 3), "\(label) should be on the center spot")
        XCTAssertFalse(center.exists)
    }

    /// Opens today's puzzle and starts it over, so earlier runs don't leave words on the board.
    private func openFreshPuzzle(_ app: XCUIApplication) {
        let open = app.buttons.matching(NSPredicate(format: "label IN %@", ["Play", "Continue", "See result"])).firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()
        let more = app.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        more.tap()
        app.buttons["Start over"].firstMatch.tap()
        // Confirm in the dialog
        let confirm = app.buttons.matching(NSPredicate(format: "label == 'Start over'"))
        if confirm.count > 0 { confirm.element(boundBy: confirm.count - 1).tap() }
    }
}
