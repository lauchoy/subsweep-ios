import SwiftUI

struct SubscriptionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize

    let original: Subscription?
    let existingNames: [String]
    let onSave: (Subscription) -> Void
    let onDelete: (() -> Void)?
    private let initialRenewal: Date

    @State private var name: String
    @State private var priceText: String
    @State private var cycle: BillingCycle
    @State private var nextRenewal: Date
    @State private var category: String
    @State private var remindDays: Int
    @State private var confirmingDelete = false
    @State private var confirmingDiscard = false

    init(subscription: Subscription?, existingNames: [String] = [], onSave: @escaping (Subscription) -> Void, onDelete: (() -> Void)? = nil) {
        original = subscription
        self.existingNames = existingNames
        let renewal = subscription?.upcomingRenewal() ?? Calendar.current.date(byAdding: .month, value: 1, to: .now)!
        initialRenewal = renewal
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: subscription?.name ?? "")
        _priceText = State(initialValue: subscription.map { "\($0.price)" } ?? "")
        _cycle = State(initialValue: subscription?.cycle ?? .monthly)
        _nextRenewal = State(initialValue: renewal)
        _category = State(initialValue: subscription?.category ?? "Other")
        _remindDays = State(initialValue: subscription.map { $0.remindDaysBefore ?? -1 } ?? Self.defaultRemindDays)
    }

    private var price: Decimal? { Subscription.parsePrice(priceText) }

    private static let defaultRemindDays = 2

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    private var isDuplicate: Bool {
        guard trimmedName.caseInsensitiveCompare(original?.name ?? "") != .orderedSame else { return false }
        return existingNames.contains { $0.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    private var canSave: Bool { !trimmedName.isEmpty && price != nil && !isDuplicate }

    private var isDirty: Bool {
        let dateChanged = !Calendar.current.isDate(nextRenewal, inSameDayAs: initialRenewal)
        guard let original else {
            return !trimmedName.isEmpty || !priceText.isEmpty || cycle != .monthly || remindDays != Self.defaultRemindDays || dateChanged
        }
        return trimmedName != original.name || price != original.price || cycle != original.cycle
            || dateChanged
            || (remindDays < 0 ? nil : remindDays) != original.remindDaysBefore
    }

    private var draft: Subscription {
        var sub = original ?? Subscription(name: "", price: 0, cycle: .monthly, nextRenewal: .now)
        sub.price = price ?? 0
        sub.cycle = cycle
        // Keep the original anchor (e.g. Jan 31) unless the date or the cycle changed; then anchor on the shown date.
        if original == nil || cycle != original?.cycle || !Calendar.current.isDate(nextRenewal, inSameDayAs: initialRenewal) {
            sub.nextRenewal = nextRenewal
        }
        sub.remindDaysBefore = remindDays < 0 ? nil : remindDays
        return sub
    }

    private var reminderNote: String? {
        guard remindDays >= 0, let fire = draft.nextReminder() else { return nil }
        let when = fire.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        return fire < draft.upcomingRenewal()
            ? "You'll get a reminder on \(when)."
            : "It's too late to remind you before this charge. The next reminder is \(when)."
    }

    var body: some View {
        NavigationStack {
            Form {
                if original == nil {
                    Section("Popular") {
                        FlowLayout(spacing: 8) {
                            ForEach(ServiceCatalog.all) { service in
                                Button { apply(service) } label: {
                                    Label(service.name, systemImage: service.symbol)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(.teal.opacity(name == service.name ? 0.3 : 0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(service.name)
                                .accessibilityAddTraits(name == service.name ? .isSelected : [])
                                .accessibilityIdentifier("preset_\(service.name)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Details") {
                    TextField("Name (e.g. Netflix)", text: $name)
                        .accessibilityLabel("Name")
                        .accessibilityIdentifier("nameField")
                    if isDuplicate {
                        Text("You already track \(trimmedName). Edit that one instead.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("duplicateError")
                    }
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Price")
                        .accessibilityIdentifier("priceField")
                    if !priceText.isEmpty && price == nil {
                        Text("Enter a price from 0 (free trial) to 99,999.99, like 9.99")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("priceError")
                    }
                    stacked("Billed") {
                        Picker("Billed", selection: $cycle) {
                            ForEach(BillingCycle.allCases) { Text($0.label).tag($0) }
                        }
                    }
                    DatePicker("Next charge", selection: $nextRenewal, displayedComponents: .date)
                }
                Section {
                    stacked("Remind me") {
                        Picker("Remind me", selection: $remindDays) {
                            Text("Off").tag(-1)
                            Text("1 day before").tag(1)
                            Text("2 days before").tag(2)
                            Text("3 days before").tag(3)
                            Text("1 week before").tag(7)
                        }
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reminders arrive at 10:00 AM.")
                        if let reminderNote {
                            Text(reminderNote).accessibilityIdentifier("reminderNote")
                        }
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
            .navigationTitle(original != nil ? "Edit" : typeSize.isAccessibilitySize ? "Add" : "New subscription")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isDirty)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { if isDirty { confirmingDiscard = true } else { dismiss() } }
                        .accessibilityIdentifier("closeForm")
                        .confirmationDialog("Discard your changes?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                            Button("Discard changes", role: .destructive) { dismiss() }
                            Button("Keep editing", role: .cancel) {}
                        }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .accessibilityIdentifier("saveSubscription")
                }
            }
        }
    }

    /// At accessibility sizes the label goes above the picker so neither gets truncated.
    @ViewBuilder
    private func stacked<Content: View>(_ title: String, @ViewBuilder _ picker: () -> Content) -> some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).accessibilityHidden(true)
                picker().labelsHidden().accessibilityLabel(title)
            }
        } else {
            picker()
        }
    }

    private func apply(_ service: KnownService) {
        name = service.name
        priceText = "\(service.price)"
        cycle = service.cycle
        category = service.category
    }

    private func save() {
        guard canSave else { return }
        var sub = draft
        sub.name = trimmedName
        sub.category = ServiceCatalog.match(sub.name)?.category ?? category
        onSave(sub)
        dismiss()
    }
}

/// Wraps its children onto as many rows as needed, so every item stays on screen and reachable.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
                x += min(size.width, bounds.width) + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let itemWidth = min(size.width, maxWidth)
            let needed = current.indices.isEmpty ? itemWidth : current.width + spacing + itemWidth
            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? itemWidth : current.width + spacing + itemWidth
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
