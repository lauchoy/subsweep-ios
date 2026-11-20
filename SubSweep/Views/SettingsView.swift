import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(ProStore.self) private var pro
    @State private var showingPaywall = false
    @State private var remindersAllowed: Bool?

    var body: some View {
        NavigationStack {
            Form {
                Section("SubSweep Pro") {
                    if pro.isPro {
                        Label("Unlocked. Thanks for the support!", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.teal)
                            .accessibilityIdentifier("proUnlocked")
                    } else {
                        Button("Unlock unlimited subscriptions") { showingPaywall = true }
                            .accessibilityIdentifier("settingsUnlock")
                        Button("Restore purchase") { Task { await pro.restore() } }
                    }
                }
                Section("Reminders") {
                    Button("Turn on renewal reminders") {
                        Task {
                            remindersAllowed = await ReminderScheduler.requestAuthorization()
                            if remindersAllowed == true { ReminderScheduler.reschedule(store.subscriptions) }
                        }
                    }
                    if let remindersAllowed {
                        Text(remindersAllowed ? "Reminders are on." : "Allow notifications for SubSweep in the Settings app.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Cancel help") {
                    Link("Manage App Store subscriptions", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                }
                Section {
                    Text("Your list stays on this iPhone. SubSweep never asks for your bank login.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }
}
