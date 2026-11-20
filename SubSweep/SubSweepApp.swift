import SwiftUI

@main
struct SubSweepApp: App {
    @State private var store: SubscriptionStore
    @State private var pro: ProStore

    init() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-uiTesting") {
            UserDefaults.standard.removeObject(forKey: "subsweep.pro.unlocked")
            _store = State(initialValue: SubscriptionStore(fileURL: nil, seed: LaunchSeed.subscriptions(for: args)))
            _pro = State(initialValue: ProStore(forcePro: args.contains("-pro")))
        } else {
            _store = State(initialValue: SubscriptionStore())
            _pro = State(initialValue: ProStore())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(pro)
                .task {
                    await pro.load()
                    if !LaunchSeed.isUITesting, await ReminderScheduler.isAuthorized() {
                        ReminderScheduler.reschedule(store.subscriptions)
                    }
                }
        }
    }
}

enum LaunchSeed {
    static var isUITesting: Bool { ProcessInfo.processInfo.arguments.contains("-uiTesting") }
    static var bypassesStore: Bool { isUITesting && !ProcessInfo.processInfo.arguments.contains("-realStore") }

    static func subscriptions(for args: [String]) -> [Subscription] {
        let now = Date.now
        func inDays(_ days: Int) -> Date { Calendar.current.date(byAdding: .day, value: days, to: now)! }
        if args.contains("-seedFull") {
            return ["Netflix", "Spotify", "Disney+", "iCloud+", "Audible"].enumerated().map { index, name in
                let known = ServiceCatalog.match(name)!
                return Subscription(name: name, price: known.price, cycle: known.cycle, nextRenewal: inDays(index + 1), category: known.category)
            }
        }
        if args.contains("-seedSample") {
            return [
                Subscription(name: "Netflix", price: Decimal(string: "17.99")!, cycle: .monthly, nextRenewal: inDays(3), category: "Streaming"),
                Subscription(name: "Spotify", price: Decimal(string: "11.99")!, cycle: .monthly, nextRenewal: inDays(10), category: "Music"),
            ]
        }
        return []
    }
}
