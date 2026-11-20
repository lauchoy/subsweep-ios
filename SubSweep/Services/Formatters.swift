import Foundation

enum Formatters {
    static func currency(_ value: Decimal) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    static func daysUntil(_ date: Date, from now: Date = .now) -> Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: date)).day ?? 0
    }
}
