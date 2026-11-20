import SwiftUI

struct SubscriptionsView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(ProStore.self) private var pro
    @State private var editing: Subscription?
    @State private var showingNew = false
    @State private var showingPaywall = false
    @State private var pendingDelete: Subscription?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TotalsCard()
                    if !pro.isPro && !store.subscriptions.isEmpty {
                        Text("\(store.subscriptions.count) of \(SubscriptionStore.freeLimit) free slots used")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .accessibilityIdentifier("freeSlots")
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if store.subscriptions.isEmpty {
                    ContentUnavailableView {
                        Label("No subscriptions yet", systemImage: "creditcard")
                    } description: {
                        Text("Add what you pay for to see the real monthly total.")
                    } actions: {
                        Button("Add your first subscription", action: add)
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("emptyAddButton")
                    }
                } else {
                    Section("Upcoming renewals") {
                        ForEach(store.sorted) { sub in
                            Button { editing = sub } label: { SubscriptionRow(sub: sub) }
                                .buttonStyle(.plain)
                                .accessibilityLabel(SubscriptionRow.accessibilityText(for: sub))
                                .accessibilityIdentifier("row_\(sub.name)")
                                .swipeActions(allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) { pendingDelete = sub }
                                }
                        }
                    }
                }
            }
            .navigationTitle("SubSweep")
            .toolbar {
                Button(action: add) { Image(systemName: "plus.circle.fill").font(.title2) }
                    .accessibilityLabel("Add subscription")
                    .accessibilityIdentifier("addSubscription")
            }
            .sheet(isPresented: $showingNew) {
                SubscriptionFormView(subscription: nil, existingNames: store.subscriptions.map(\.name)) { saved($0) }
            }
            .sheet(item: $editing) { sub in
                SubscriptionFormView(subscription: sub, existingNames: store.subscriptions.map(\.name), onSave: { saved($0) },
                                     onDelete: { store.delete(id: sub.id); reschedule() })
            }
            .sheet(isPresented: $showingPaywall, onDismiss: { if pro.isPro { showingNew = true } }) { PaywallView() }
            .confirmationDialog("Delete \(pendingDelete?.name ?? "")?",
                                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible,
                                presenting: pendingDelete) { sub in
                Button("Delete \(sub.name)", role: .destructive) { store.delete(id: sub.id); reschedule() }
            }
        }
    }

    private func add() {
        if store.canAdd(isPro: pro.isPro) { showingNew = true } else { showingPaywall = true }
    }

    private func saved(_ sub: Subscription) {
        store.upsert(sub)
        guard !LaunchSeed.isUITesting else { return }
        Task {
            if sub.remindDaysBefore != nil { _ = await ReminderScheduler.ensureAuthorized() }
            reschedule()
        }
    }

    private func reschedule() {
        guard !LaunchSeed.isUITesting else { return }
        ReminderScheduler.reschedule(store.subscriptions)
    }
}

struct TotalsCard: View {
    @Environment(SubscriptionStore.self) private var store

    var body: some View {
        let monthly = Formatters.currency(store.monthlyTotal)
        VStack(alignment: .leading, spacing: 6) {
            Text("You spend")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityHidden(true)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    amount(monthly)
                    perMonth
                }
                VStack(alignment: .leading, spacing: 0) {
                    amount(monthly)
                    perMonth
                }
            }
            Text("\(Formatters.currency(store.yearlyTotal)) a year on \(store.subscriptions.count) subscription\(store.subscriptions.count == 1 ? "" : "s")")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityIdentifier("yearlyTotal")
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.vertical, 8)
    }

    private func amount(_ monthly: String) -> some View {
        Text(monthly)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .accessibilityLabel("You spend \(monthly) a month")
            .accessibilityIdentifier("monthlyTotal")
    }

    private var perMonth: some View {
        Text("/ month")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.85))
            .accessibilityHidden(true)
    }
}

struct SubscriptionRow: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let sub: Subscription

    static func renewalText(for sub: Subscription, separator: String) -> String {
        let renewal = sub.upcomingRenewal()
        let days = Formatters.daysUntil(renewal)
        switch days {
        case 0: return "Renews today"
        case 1: return "Renews tomorrow"
        default: return "Renews \(Formatters.shortDate(renewal))\(separator)in \(days) days"
        }
    }

    static func accessibilityText(for sub: Subscription) -> String {
        "\(sub.name), \(Formatters.currency(sub.price)) \(sub.cycle.label), \(renewalText(for: sub, separator: ", "))"
    }

    var body: some View {
        let days = Formatters.daysUntil(sub.upcomingRenewal())
        let renewal = Text(Self.renewalText(for: sub, separator: " · "))
            .font(.caption)
            .foregroundStyle(days <= 3 ? .orange : .secondary)
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sub.name).font(.headline).foregroundStyle(.primary)
                    Text("\(Formatters.currency(sub.price)) \(sub.cycle.label.lowercased())")
                        .font(.subheadline).foregroundStyle(.primary)
                    renewal
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: ServiceCatalog.symbol(for: sub.name))
                        .font(.title3)
                        .frame(width: 40, height: 40)
                        .background(.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sub.name).font(.headline).foregroundStyle(.primary)
                        renewal
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Formatters.currency(sub.price)).font(.headline).foregroundStyle(.primary)
                        Text(sub.cycle.label).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
