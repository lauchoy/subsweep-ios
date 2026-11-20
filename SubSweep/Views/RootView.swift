import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            SubscriptionsView()
                .tabItem { Label("Subscriptions", systemImage: "list.bullet.rectangle") }
            AuditView()
                .tabItem { Label("Audit", systemImage: "checkmark.seal") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.teal)
    }
}
