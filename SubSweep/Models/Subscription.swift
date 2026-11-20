import Foundation

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case weekly, monthly, quarterly, yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .quarterly: "Every 3 months"
        case .yearly: "Yearly"
        }
    }

    var periodsPerYear: Decimal {
        switch self {
        case .weekly: 52
        case .monthly: 12
        case .quarterly: 4
        case .yearly: 1
        }
    }

    var calendarStep: DateComponents {
        switch self {
        case .weekly: DateComponents(day: 7)
        case .monthly: DateComponents(month: 1)
        case .quarterly: DateComponents(month: 3)
        case .yearly: DateComponents(year: 1)
        }
    }
}

enum AuditVerdict: String, Codable {
    case undecided, keep, cancel
}

struct Subscription: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var price: Decimal
    var cycle: BillingCycle
    var nextRenewal: Date
    var category: String = "Other"
    var verdict: AuditVerdict = .undecided
    var remindDaysBefore: Int? = 2

    var yearlyCost: Decimal { price * cycle.periodsPerYear }
    var monthlyCost: Decimal { yearlyCost / 12 }

    /// Rolls `nextRenewal` forward past `now` so the list never shows a renewal in the past.
    func upcomingRenewal(from now: Date = .now, calendar: Calendar = .current) -> Date {
        var date = nextRenewal
        var guardCount = 0
        while date < calendar.startOfDay(for: now), guardCount < 1000 {
            guard let next = calendar.date(byAdding: cycle.calendarStep, to: date) else { break }
            date = next
            guardCount += 1
        }
        return date
    }
}
