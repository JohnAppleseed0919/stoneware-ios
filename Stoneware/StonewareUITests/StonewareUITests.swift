import XCTest

final class StonewareUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func testSnapshots() throws {
        // 1. Dashboard
        sleep(2)
        snapshot("01-dashboard")

        // 2. Tap first piece card → detail view
        let firstCard = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'mug' OR label CONTAINS[c] 'bowl' OR label CONTAINS[c] 'tile'")).firstMatch
        if firstCard.waitForExistence(timeout: 3) {
            firstCard.tap()
            sleep(2)
            snapshot("02-detail")

            // Scroll down for glazes + firings
            app.swipeUp()
            sleep(1)
            snapshot("03-glazes")

            app.swipeUp()
            sleep(1)
            snapshot("04-timeline")

            // Back to dashboard
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // 3. New piece sheet
        let newPieceButton = app.buttons["New piece"].firstMatch
        if newPieceButton.waitForExistence(timeout: 3) {
            newPieceButton.tap()
            sleep(2)
            snapshot("05-new-piece")
        }
    }
}
