import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProStore.self) private var pro
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(.teal)
                    .padding(.top, 24)
                Text("SubSweep Pro")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("paywallTitle")
                Text("The free version tracks \(SubscriptionStore.freeLimit) subscriptions. Most people have more than that.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Label("Unlimited subscriptions", systemImage: "infinity")
                    Label("Renewal reminders for every one", systemImage: "bell.badge")
                    Label("Pay once. No subscription, ever.", systemImage: "checkmark.seal")
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                if let error = pro.purchaseError {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
                Spacer()
                Button {
                    Task {
                        purchasing = true
                        if LaunchSeed.isUITesting { pro.unlockForTesting() } else { await pro.purchase() }
                        purchasing = false
                        if pro.isPro { dismiss() }
                    }
                } label: {
                    Text(purchasing ? "Unlocking…" : "Unlock for \(pro.displayPrice)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.teal)
                .disabled(purchasing)
                .accessibilityIdentifier("unlockPro")

                Button("Restore purchase") { Task { await pro.restore(); if pro.isPro { dismiss() } } }
                    .font(.footnote)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }.accessibilityIdentifier("paywallClose")
                }
            }
        }
    }
}
