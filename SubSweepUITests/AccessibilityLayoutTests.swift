import XCTest

/// Largest accessibility text size: every control must be reachable, and screenshots are kept for review.
final class AccessibilityLayoutTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(_ extra: [String] = []) {
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] + extra
        app.launch()
    }

    private func scrollTo(_ element: XCUIElement, in container: XCUIElement? = nil, file: StaticString = #filePath, line: UInt = #line) {
        _ = element.waitForExistence(timeout: 3)
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < 12 {
            (container ?? app).swipeUp(velocity: .slow)
            swipes += 1
        }
        XCTAssertTrue(element.isHittable, "Can't reach \(element)", file: file, line: line)
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEmptyStateAndRows() {
        launch()
        snap("ax-empty")
        scrollTo(app.buttons["emptyAddButton"])
        app.terminate()
        launch(["-seedFull"])
        XCTAssertTrue(app.staticTexts["monthlyTotal"].waitForExistence(timeout: 5))
        snap("ax-home")
        scrollTo(app.buttons["row_Netflix"])
        XCTAssertTrue(app.buttons["row_Netflix"].label.hasPrefix("Netflix, $17.99 Monthly, Renews"))
        snap("ax-rows")
    }

    func testPaywallScrollsToRestore() {
        launch(["-seedFull"])
        app.buttons["addSubscription"].tap()
        XCTAssertTrue(app.staticTexts["paywallTitle"].waitForExistence(timeout: 5))
        snap("ax-paywall-top")
        scrollTo(app.buttons["paywallRestore"])
        XCTAssertTrue(app.buttons["unlockPro"].exists)
        snap("ax-paywall-bottom")
    }

    func testAuditButtonsReachableAndUndo() {
        launch(["-seedFull"])
        app.tabBars.buttons["Audit"].tap()
        XCTAssertTrue(app.staticTexts["auditName"].waitForExistence(timeout: 5))
        snap("ax-audit-card")
        scrollTo(app.buttons["keepButton"])
        snap("ax-audit-buttons")
        scrollTo(app.buttons["cancelButton"])
        app.buttons["cancelButton"].tap()
        XCTAssertTrue(app.buttons["undoVerdict"].waitForExistence(timeout: 5))
        app.buttons["undoVerdict"].tap()
        XCTAssertEqual(app.staticTexts["auditName"].label, "Netflix")
    }

    func testEveryPresetReachable() {
        launch()
        app.buttons["emptyAddButton"].firstMatch.waitForExistence(timeout: 5) ? app.buttons["emptyAddButton"].tap() : app.buttons["addSubscription"].tap()
        let preset = app.buttons["preset_Planet Fitness"]
        scrollTo(preset)
        snap("ax-add-form")
        preset.tap()
        scrollTo(app.textFields["nameField"])
        XCTAssertEqual(app.textFields["nameField"].value as? String, "Planet Fitness")
    }
}
