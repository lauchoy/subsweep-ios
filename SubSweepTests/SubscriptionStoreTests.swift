import XCTest
@testable import SubSweep

final class SubscriptionStoreTests: XCTestCase {
    private func sub(_ name: String, _ price: String, _ cycle: BillingCycle = .monthly, verdict: AuditVerdict = .undecided) -> Subscription {
        Subscription(name: name, price: Decimal(string: price)!, cycle: cycle, nextRenewal: .now, verdict: verdict)
    }

    func testTotalsNormalizeCycles() {
        let store = SubscriptionStore(fileURL: nil, seed: [sub("A", "10"), sub("B", "120", .yearly), sub("C", "30", .quarterly)])
        XCTAssertEqual(store.monthlyTotal, 30)
        XCTAssertEqual(store.yearlyTotal, 360)
    }

    func testSavingsCountOnlyCancelled() {
        let store = SubscriptionStore(fileURL: nil, seed: [sub("A", "10", verdict: .cancel), sub("B", "5", verdict: .keep)])
        XCTAssertEqual(store.yearlySavings, 120)
        store.resetAudit()
        XCTAssertEqual(store.yearlySavings, 0)
        XCTAssertEqual(store.undecided.count, 2)
    }

    func testFreeLimit() {
        let store = SubscriptionStore(fileURL: nil, seed: (1...5).map { sub("S\($0)", "1") })
        XCTAssertFalse(store.canAdd(isPro: false))
        XCTAssertTrue(store.canAdd(isPro: true))
    }

    func testPersistsToDisk() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SubscriptionStore(fileURL: url)
        store.upsert(sub("Netflix", "17.99"))
        let reloaded = SubscriptionStore(fileURL: url)
        XCTAssertEqual(reloaded.subscriptions.map(\.name), ["Netflix"])
        XCTAssertEqual(reloaded.subscriptions.first?.price, Decimal(string: "17.99"))
    }

    func testUpcomingRenewalRollsForward() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        let s = Subscription(name: "X", price: 1, cycle: .monthly, nextRenewal: start)
        XCTAssertEqual(s.upcomingRenewal(from: now, calendar: calendar), calendar.date(from: DateComponents(year: 2026, month: 4, day: 15)))
    }

    func testCancelURLFallsBackToAppStore() {
        XCTAssertEqual(ServiceCatalog.cancelURL(for: "netflix").host, "www.netflix.com")
        XCTAssertEqual(ServiceCatalog.cancelURL(for: "Some Random App").host, "apps.apple.com")
    }
}
