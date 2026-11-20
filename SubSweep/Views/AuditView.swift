import SwiftUI

struct AuditView: View {
    @Environment(SubscriptionStore.self) private var store
    @State private var lastDecided: Subscription?

    var body: some View {
        NavigationStack {
            Group {
                if store.subscriptions.isEmpty {
                    ContentUnavailableView("Nothing to audit", systemImage: "checkmark.seal",
                                           description: Text("Add your subscriptions first, then come back to decide what stays."))
                } else if let current = store.sorted.first(where: { $0.verdict == .undecided }) {
                    AuditCard(sub: current, remaining: store.undecided.count) { decide($0, for: current) }
                        .id(current.id)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                } else {
                    AuditSummary { lastDecided = nil }
                }
            }
            .animation(.snappy, value: store.undecided.count)
            .navigationTitle("Audit")
            .toolbar {
                if let lastDecided, store.subscriptions.contains(where: { $0.id == lastDecided.id }) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Undo") { undo(lastDecided) }
                            .accessibilityLabel("Undo \(lastDecided.name)")
                            .accessibilityIdentifier("undoVerdict")
                    }
                }
            }
        }
    }

    private func decide(_ verdict: AuditVerdict, for sub: Subscription) {
        store.setVerdict(verdict, for: sub.id)
        lastDecided = sub
        let message = verdict == .cancel ? "\(sub.name) marked to cancel" : "Keeping \(sub.name)"
        AccessibilityNotification.Announcement(message).post()
    }

    private func undo(_ sub: Subscription) {
        store.setVerdict(.undecided, for: sub.id)
        lastDecided = nil
    }
}

private struct AuditCard: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let sub: Subscription
    let remaining: Int
    let onDecide: (AuditVerdict) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("\(remaining) left to review")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("auditRemaining")
                VStack(spacing: 12) {
                    Image(systemName: ServiceCatalog.symbol(for: sub.name))
                        .font(.system(size: 44))
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    Text(sub.name)
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("auditName")
                    Text("\(Formatters.currency(sub.price)) · \(sub.cycle.label)")
                        .font(.title3)
                        .accessibilityLabel("\(Formatters.currency(sub.price)) \(sub.cycle.label)")
                    Text("That's \(Formatters.currency(sub.yearlyCost)) a year")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("Did you use it in the last 30 days?")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .padding(.horizontal)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 16))
                layout {
                    Button { onDecide(.cancel) } label: {
                        Label("Cancel it", systemImage: "xmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityHint("Adds it to your cancel list. You can undo.")
                    .accessibilityIdentifier("cancelButton")

                    Button { onDecide(.keep) } label: {
                        Label("Keep", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .accessibilityIdentifier("keepButton")
                }
                .controlSize(.large)
            }
            .padding()
        }
    }
}

private struct AuditSummary: View {
    @Environment(SubscriptionStore.self) private var store
    let onReset: () -> Void

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.markedForCancel.isEmpty ? "Everything stays" : "You could save")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Formatters.currency(store.yearlySavings)) a year")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("savingsAmount")
                }
                .padding(.vertical, 8)
                Button("Start a new audit") { store.resetAudit(); onReset() }
                    .accessibilityIdentifier("resetAudit")
            }
            if !store.markedForCancel.isEmpty {
                Section("Cancel these") {
                    ForEach(store.markedForCancel) { sub in
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                Text(sub.name)
                                Spacer()
                                cancelLink(sub)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sub.name)
                                cancelLink(sub)
                            }
                        }
                    }
                }
                Section {
                    Text("Once you've cancelled, delete it from your list so your total stays accurate.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cancelLink(_ sub: Subscription) -> some View {
        Link("Cancel page", destination: ServiceCatalog.cancelURL(for: sub.name))
            .accessibilityLabel("Cancel page for \(sub.name)")
            .accessibilityIdentifier("cancelLink_\(sub.name)")
    }
}
