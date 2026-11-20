import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(ProStore.self) private var pro
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingPaywall = false
    @State private var remindersOn = false
    @State private var remindersDenied = false
    @State private var restoring = false

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
                        Button(restoring ? "Restoring…" : "Restore purchase") {
                            Task { restoring = true; await pro.restore(); restoring = false }
                        }
                        .disabled(restoring)
                        .accessibilityIdentifier("settingsRestore")
                        if let message = pro.purchaseError {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("settingsStoreMessage")
                        }
                    }
                }
                Section {
                    if remindersOn {
                        Label("Renewal reminders are on", systemImage: "bell.badge.fill")
                            .foregroundStyle(.teal)
                            .accessibilityIdentifier("remindersOn")
                    } else if remindersDenied {
                        Text("Notifications are off for SubSweep.")
                        Link("Open Settings to allow them", destination: URL(string: UIApplication.openSettingsURLString)!)
                    } else {
                        Button("Turn on renewal reminders") {
                            Task {
                                remindersOn = await ReminderScheduler.requestAuthorization()
                                remindersDenied = !remindersOn
                                if remindersOn { ReminderScheduler.reschedule(store.subscriptions) }
                            }
                        }
                        .accessibilityIdentifier("turnOnReminders")
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Reminders arrive at 10:00 AM, as many days before each charge as you pick for that subscription.")
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
            .task(id: scenePhase) { await refreshReminderStatus() }
        }
    }

    private func refreshReminderStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        remindersOn = await ReminderScheduler.isAuthorized()
        remindersDenied = settings.authorizationStatus == .denied
        if remindersOn && !LaunchSeed.isUITesting { ReminderScheduler.reschedule(store.subscriptions) }
    }
}
