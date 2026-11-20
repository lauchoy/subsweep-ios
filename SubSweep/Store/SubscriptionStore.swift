import Foundation
import Observation

@Observable
final class SubscriptionStore {
    static let freeLimit = 5

    private(set) var subscriptions: [Subscription] = []
    private let fileURL: URL?

    init(fileURL: URL? = SubscriptionStore.defaultFileURL, seed: [Subscription] = []) {
        self.fileURL = fileURL
        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Subscription].self, from: data) {
            subscriptions = decoded
        } else {
            subscriptions = seed
        }
    }

    static var defaultFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("subscriptions.json")
    }

    var sorted: [Subscription] {
        subscriptions.sorted { $0.upcomingRenewal() < $1.upcomingRenewal() }
    }

    var yearlyTotal: Decimal { subscriptions.reduce(0) { $0 + $1.yearlyCost } }
    var monthlyTotal: Decimal { yearlyTotal / 12 }

    var markedForCancel: [Subscription] { subscriptions.filter { $0.verdict == .cancel } }
    var yearlySavings: Decimal { markedForCancel.reduce(0) { $0 + $1.yearlyCost } }
    var undecided: [Subscription] { subscriptions.filter { $0.verdict == .undecided } }

    func canAdd(isPro: Bool) -> Bool { isPro || subscriptions.count < Self.freeLimit }

    func upsert(_ sub: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[index] = sub
        } else {
            subscriptions.append(sub)
        }
        save()
    }

    func delete(id: UUID) {
        subscriptions.removeAll { $0.id == id }
        save()
    }

    func setVerdict(_ verdict: AuditVerdict, for id: UUID) {
        guard let index = subscriptions.firstIndex(where: { $0.id == id }) else { return }
        subscriptions[index].verdict = verdict
        save()
    }

    func resetAudit() {
        for index in subscriptions.indices { subscriptions[index].verdict = .undecided }
        save()
    }

    private func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(subscriptions).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save subscriptions: \(error)")
        }
    }
}
