import XCTest

final class SubSweepUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(_ extra: [String] = []) {
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + extra
        app.launch()
    }

    private func label(_ id: String) -> String {
        let element = app.staticTexts[id]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(id)")
        return element.label
    }

    func testAddPopularServiceUpdatesTotals() {
        launch()
        XCTAssertEqual(label("monthlyTotal"), "You spend $0.00 a month")
        app.buttons["emptyAddButton"].tap()
        app.buttons["preset_Netflix"].tap()
        app.buttons["saveSubscription"].tap()

        XCTAssertTrue(app.buttons["row_Netflix"].waitForExistence(timeout: 5))
        XCTAssertEqual(label("monthlyTotal"), "You spend $17.99 a month")
        XCTAssertTrue(label("yearlyTotal").hasPrefix("$215.88 a year on 1 subscription"))
    }

    func testAddCustomSubscriptionThenDelete() {
        launch()
        app.buttons["addSubscription"].tap()
        let name = app.textFields["nameField"]
        name.tap()
        name.typeText("Gym")
        let price = app.textFields["priceField"]
        price.tap()
        price.typeText("30")
        app.buttons["saveSubscription"].tap()

        let row = app.buttons["row_Gym"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(label("monthlyTotal"), "You spend $30.00 a month")

        row.tap()
        app.buttons["deleteSubscription"].tap()
        let confirm = app.buttons["Delete Gym"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertTrue(row.exists, "Delete must wait for confirmation")
        confirm.tap()
        XCTAssertTrue(app.buttons["emptyAddButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(label("monthlyTotal"), "You spend $0.00 a month")
    }

    func testAuditShowsYearlySavings() {
        launch(["-seedSample"])
        app.tabBars.buttons["Audit"].tap()

        XCTAssertEqual(label("auditName"), "Netflix")
        app.buttons["cancelButton"].tap()
        XCTAssertEqual(label("auditName"), "Spotify")
        app.buttons["undoVerdict"].tap()
        XCTAssertEqual(label("auditName"), "Netflix")
        app.buttons["cancelButton"].tap()
        XCTAssertEqual(label("auditName"), "Spotify")
        app.buttons["keepButton"].tap()

        XCTAssertEqual(label("savingsAmount"), "$215.88 a year")
        XCTAssertTrue(app.buttons["cancelLink_Netflix"].exists || app.links["cancelLink_Netflix"].exists)

        app.buttons["resetAudit"].tap()
        XCTAssertEqual(label("auditName"), "Netflix")
    }

    func testFreeLimitShowsPaywallAndUnlockRemovesIt() {
        launch(["-seedFull"])
        XCTAssertTrue(app.staticTexts["freeSlots"].waitForExistence(timeout: 5))
        app.buttons["addSubscription"].tap()
        XCTAssertTrue(app.staticTexts["paywallTitle"].waitForExistence(timeout: 5))

        app.buttons["unlockPro"].tap()
        XCTAssertTrue(app.staticTexts["paywallTitle"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["saveSubscription"].waitForExistence(timeout: 5), "Unlocking should continue to the add form")
        XCTAssertFalse(app.staticTexts["freeSlots"].exists)
    }

    func testSimulatorUnlocksWhenStoreUnavailable() {
        launch(["-seedFull", "-realStore"])
        app.buttons["addSubscription"].tap()
        XCTAssertTrue(app.staticTexts["paywallTitle"].waitForExistence(timeout: 5))

        app.buttons["unlockPro"].tap()
        XCTAssertTrue(app.staticTexts["paywallTitle"].waitForNonExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["freeSlots"].exists)
    }

    func testInvalidPriceIsRejected() {
        launch()
        app.buttons["addSubscription"].tap()
        let name = app.textFields["nameField"]
        name.tap()
        name.typeText("Gym")
        let price = app.textFields["priceField"]
        price.tap()
        price.typeText("abc12.34xyz")
        XCTAssertTrue(app.staticTexts["priceError"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveSubscription"].isEnabled)
    }

    func testDuplicateIsBlocked() {
        launch(["-seedSample"])
        app.buttons["addSubscription"].tap()
        app.buttons["preset_Netflix"].tap()
        XCTAssertTrue(app.staticTexts["duplicateError"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveSubscription"].isEnabled)
    }

    func testFreeTrialAtZeroSaves() {
        launch()
        app.buttons["addSubscription"].tap()
        let name = app.textFields["nameField"]
        name.tap()
        name.typeText("Trial")
        let price = app.textFields["priceField"]
        price.tap()
        price.typeText("0")
        XCTAssertTrue(app.buttons["saveSubscription"].isEnabled)
        app.buttons["saveSubscription"].tap()
        XCTAssertTrue(app.buttons["row_Trial"].waitForExistence(timeout: 5))
    }

    func testCloseWithChangesAsksBeforeDiscarding() {
        launch()
        app.buttons["addSubscription"].tap()
        let name = app.textFields["nameField"]
        name.tap()
        name.typeText("Gym")
        app.buttons["closeForm"].tap()
        let discard = app.buttons["Discard changes"]
        XCTAssertTrue(discard.waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["nameField"].exists, "Close must not discard before confirming")
        discard.tap()
        XCTAssertTrue(app.buttons["emptyAddButton"].waitForExistence(timeout: 5))
    }
}
