import SwiftUI

struct SubscriptionsView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(ProStore.self) private var pro
    @State private var editing: Subscription?
    @State private var showingNew = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section { TotalsCard() }
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
                                .accessibilityIdentifier("row_\(sub.name)")
                                .swipeActions {
                                    Button("Delete", role: .destructive) { store.delete(id: sub.id); reschedule() }
                                }
                        }
                    }
                    if !pro.isPro {
                        Section {
                            Text("\(store.subscriptions.count) of \(SubscriptionStore.freeLimit) free slots used")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("freeSlots")
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
                SubscriptionFormView(subscription: nil) { store.upsert($0); reschedule() }
            }
            .sheet(item: $editing) { sub in
                SubscriptionFormView(subscription: sub, onSave: { store.upsert($0); reschedule() },
                                     onDelete: { store.delete(id: sub.id); reschedule() })
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private func add() {
        if store.canAdd(isPro: pro.isPro) { showingNew = true } else { showingPaywall = true }
    }

    private func reschedule() {
        guard !LaunchSeed.isUITesting else { return }
        ReminderScheduler.reschedule(store.subscriptions)
    }
}

struct TotalsCard: View {
    @Environment(SubscriptionStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("You spend")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Formatters.currency(store.monthlyTotal))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .accessibilityIdentifier("monthlyTotal")
                Text("/ month").foregroundStyle(.white.opacity(0.85))
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
}

struct SubscriptionRow: View {
    let sub: Subscription

    var body: some View {
        let renewal = sub.upcomingRenewal()
        let days = Formatters.daysUntil(renewal)
        HStack(spacing: 12) {
            Image(systemName: ServiceCatalog.symbol(for: sub.name))
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name).font(.headline).foregroundStyle(.primary)
                Text(days == 0 ? "Renews today" : days == 1 ? "Renews tomorrow" : "Renews \(Formatters.shortDate(renewal)) · in \(days) days")
                    .font(.caption)
                    .foregroundStyle(days <= 3 ? .orange : .secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.currency(sub.price)).font(.headline).foregroundStyle(.primary)
                Text(sub.cycle.label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
