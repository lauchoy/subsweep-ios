import XCTest

/// Walks the main screens with sample data and keeps a screenshot of each (used for the README and App Store listing).
final class ScreenshotTests: XCTestCase {
    func testCaptureScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-seedFull", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.staticTexts["monthlyTotal"].waitForExistence(timeout: 5))
        snap("1-subscriptions")

        app.tabBars.buttons["Audit"].tap()
        XCTAssertTrue(app.staticTexts["auditName"].waitForExistence(timeout: 5))
        snap("2-audit")
        app.buttons["cancelButton"].tap()
        app.buttons["keepButton"].tap()
        app.buttons["cancelButton"].tap()
        app.buttons["keepButton"].tap()
        app.buttons["keepButton"].tap()
        XCTAssertTrue(app.staticTexts["savingsAmount"].waitForExistence(timeout: 5))
        snap("3-savings")

        app.tabBars.buttons["Subscriptions"].tap()
        app.buttons["addSubscription"].tap()
        XCTAssertTrue(app.staticTexts["paywallTitle"].waitForExistence(timeout: 5))
        snap("4-paywall")
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
