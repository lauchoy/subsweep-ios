import Foundation
import UserNotifications

enum ReminderScheduler {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Asks only the first time; afterwards returns the current answer without a prompt.
    static func ensureAuthorized() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        if status == .notDetermined { return await requestAuthorization() }
        return await isAuthorized()
    }

    static func isAuthorized() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    static func reschedule(_ subscriptions: [Subscription], now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for sub in subscriptions where sub.verdict != .cancel {
            guard let days = sub.remindDaysBefore, let fireDate = sub.nextReminder(from: now) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "\(sub.name) renews in \(days) day\(days == 1 ? "" : "s")"
            content.body = "\(Formatters.currency(sub.price)) will be charged. Still using it?"
            content.sound = .default
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: sub.id.uuidString, content: content, trigger: trigger))
        }
    }
}
