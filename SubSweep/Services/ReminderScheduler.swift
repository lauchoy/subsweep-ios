import Foundation
import UserNotifications

enum ReminderScheduler {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func reschedule(_ subscriptions: [Subscription], now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for sub in subscriptions where sub.verdict != .cancel {
            guard let days = sub.remindDaysBefore,
                  let fireDate = Calendar.current.date(byAdding: .day, value: -days, to: sub.upcomingRenewal(from: now)),
                  fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "\(sub.name) renews in \(days) day\(days == 1 ? "" : "s")"
            content.body = "\(Formatters.currency(sub.price)) will be charged. Still using it?"
            content.sound = .default
            var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
            components.hour = 10
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: sub.id.uuidString, content: content, trigger: trigger))
        }
    }
}
