import XCTest

@MainActor
final class StonewareUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func testSnapshots() throws {
        sleep(2)
        snapshot("01-dashboard")

        // Tap the first piece card (seed data includes "Speckled morning mug")
        let mug = app.buttons["Speckled morning mug"]
        if mug.waitForExistence(timeout: 3) {
            mug.tap()
            sleep(2)
            snapshot("02-detail")

            // Scroll to glaze section
            app.swipeUp()
            sleep(1)
            snapshot("03-glaze-layers")

            // Scroll to timeline
            app.swipeUp()
            sleep(1)
            app.swipeUp()
            sleep(1)
            snapshot("04-timeline")

            // Back to dashboard
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // New piece sheet — tap the FAB (contains "New piece" label)
        let newPieceBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'New piece'")).firstMatch
        if newPieceBtn.waitForExistence(timeout: 3) {
            newPieceBtn.tap()
            sleep(2)
            snapshot("05-new-piece")
        }
    }
}
