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
        XCTAssertEqual(label("monthlyTotal"), "$0.00")
        app.buttons["emptyAddButton"].tap()
        app.buttons["preset_Netflix"].tap()
        app.buttons["saveSubscription"].tap()

        XCTAssertTrue(app.buttons["row_Netflix"].waitForExistence(timeout: 5))
        XCTAssertEqual(label("monthlyTotal"), "$17.99")
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
        XCTAssertEqual(label("monthlyTotal"), "$30.00")

        row.tap()
        app.buttons["deleteSubscription"].tap()
        XCTAssertTrue(app.buttons["emptyAddButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(label("monthlyTotal"), "$0.00")
    }

    func testAuditShowsYearlySavings() {
        launch(["-seedSample"])
        app.tabBars.buttons["Audit"].tap()

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
        XCTAssertFalse(app.staticTexts["freeSlots"].exists)

        app.buttons["addSubscription"].tap()
        XCTAssertTrue(app.buttons["saveSubscription"].waitForExistence(timeout: 5))
    }
}
