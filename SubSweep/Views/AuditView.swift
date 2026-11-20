import SwiftUI

struct AuditView: View {
    @Environment(SubscriptionStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.subscriptions.isEmpty {
                    ContentUnavailableView("Nothing to audit", systemImage: "checkmark.seal",
                                           description: Text("Add your subscriptions first, then come back to decide what stays."))
                } else if let current = store.sorted.first(where: { $0.verdict == .undecided }) {
                    AuditCard(sub: current, remaining: store.undecided.count)
                        .id(current.id)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                } else {
                    AuditSummary()
                }
            }
            .animation(.snappy, value: store.undecided.count)
            .navigationTitle("Audit")
        }
    }
}

private struct AuditCard: View {
    @Environment(SubscriptionStore.self) private var store
    let sub: Subscription
    let remaining: Int

    var body: some View {
        VStack(spacing: 24) {
            Text("\(remaining) left to review")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("auditRemaining")
            VStack(spacing: 12) {
                Image(systemName: ServiceCatalog.symbol(for: sub.name))
                    .font(.system(size: 44))
                    .foregroundStyle(.teal)
                Text(sub.name)
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("auditName")
                Text("\(Formatters.currency(sub.price)) · \(sub.cycle.label)")
                    .font(.title3)
                Text("That's \(Formatters.currency(sub.yearlyCost)) a year")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("Did you use it in the last 30 days?")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            HStack(spacing: 16) {
                Button { store.setVerdict(.cancel, for: sub.id) } label: {
                    Label("Cancel it", systemImage: "xmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .accessibilityIdentifier("cancelButton")

                Button { store.setVerdict(.keep, for: sub.id) } label: {
                    Label("Keep", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .accessibilityIdentifier("keepButton")
            }
            .controlSize(.large)
            Spacer()
        }
        .padding()
    }
}

private struct AuditSummary: View {
    @Environment(SubscriptionStore.self) private var store

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.markedForCancel.isEmpty ? "Everything stays" : "You could save")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Formatters.currency(store.yearlySavings)) a year")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("savingsAmount")
                }
                .padding(.vertical, 8)
            }
            if !store.markedForCancel.isEmpty {
                Section("Cancel these") {
                    ForEach(store.markedForCancel) { sub in
                        HStack {
                            Text(sub.name)
                            Spacer()
                            Link("Cancel page", destination: ServiceCatalog.cancelURL(for: sub.name))
                                .accessibilityIdentifier("cancelLink_\(sub.name)")
                        }
                    }
                }
                Section {
                    Text("Once you've cancelled, delete it from your list so your total stays accurate.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Button("Start a new audit") { store.resetAudit() }
                    .accessibilityIdentifier("resetAudit")
            }
        }
    }
}
