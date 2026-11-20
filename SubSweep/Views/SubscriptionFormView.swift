import SwiftUI

struct SubscriptionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let original: Subscription?
    let onSave: (Subscription) -> Void
    let onDelete: (() -> Void)?

    @State private var name: String
    @State private var priceText: String
    @State private var cycle: BillingCycle
    @State private var nextRenewal: Date
    @State private var category: String
    @State private var remindDays: Int
    @State private var confirmingDelete = false

    init(subscription: Subscription?, onSave: @escaping (Subscription) -> Void, onDelete: (() -> Void)? = nil) {
        original = subscription
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: subscription?.name ?? "")
        _priceText = State(initialValue: subscription.map { "\($0.price)" } ?? "")
        _cycle = State(initialValue: subscription?.cycle ?? .monthly)
        _nextRenewal = State(initialValue: subscription?.nextRenewal ?? Calendar.current.date(byAdding: .month, value: 1, to: .now)!)
        _category = State(initialValue: subscription?.category ?? "Other")
        _remindDays = State(initialValue: subscription.map { $0.remindDaysBefore ?? -1 } ?? 2)
    }

    private var price: Decimal? { Subscription.parsePrice(priceText) }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && price != nil }

    var body: some View {
        NavigationStack {
            Form {
                if original == nil {
                    Section("Popular") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(ServiceCatalog.all) { service in
                                    Button { apply(service) } label: {
                                        Label(service.name, systemImage: service.symbol)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(.teal.opacity(name == service.name ? 0.3 : 0.12), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("preset_\(service.name)")
                                }
                            }
                        }
                    }
                }
                Section("Details") {
                    TextField("Name (e.g. Netflix)", text: $name)
                        .accessibilityIdentifier("nameField")
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("priceField")
                    if !priceText.isEmpty && price == nil {
                        Text("Enter a price like 9.99")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("priceError")
                    }
                    Picker("Billed", selection: $cycle) {
                        ForEach(BillingCycle.allCases) { Text($0.label).tag($0) }
                    }
                    DatePicker("Next charge", selection: $nextRenewal, displayedComponents: .date)
                }
                Section("Reminder") {
                    Picker("Remind me", selection: $remindDays) {
                        Text("Off").tag(-1)
                        Text("1 day before").tag(1)
                        Text("2 days before").tag(2)
                        Text("3 days before").tag(3)
                        Text("1 week before").tag(7)
                    }
                }
                if let original {
                    Section {
                        Button("Open cancel page") { openURL(ServiceCatalog.cancelURL(for: original.name)) }
                            .accessibilityIdentifier("openCancelPage")
                        if let onDelete {
                            Button("Delete subscription", role: .destructive) { confirmingDelete = true }
                                .accessibilityIdentifier("deleteSubscription")
                                .confirmationDialog("Delete \(original.name)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                                    Button("Delete \(original.name)", role: .destructive) { onDelete(); dismiss() }
                                }
                        }
                    }
                }
            }
            .navigationTitle(original == nil ? "New subscription" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .accessibilityIdentifier("saveSubscription")
                }
            }
        }
    }

    private func apply(_ service: KnownService) {
        name = service.name
        priceText = "\(service.price)"
        cycle = service.cycle
        category = service.category
    }

    private func save() {
        guard let price else { return }
        var sub = original ?? Subscription(name: "", price: 0, cycle: .monthly, nextRenewal: .now)
        sub.name = name.trimmingCharacters(in: .whitespaces)
        sub.price = price
        sub.cycle = cycle
        sub.nextRenewal = nextRenewal
        sub.category = ServiceCatalog.match(sub.name)?.category ?? category
        sub.remindDaysBefore = remindDays < 0 ? nil : remindDays
        onSave(sub)
        dismiss()
    }
}
