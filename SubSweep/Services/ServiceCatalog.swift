import Foundation

struct KnownService: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let price: Decimal
    let cycle: BillingCycle
    let category: String
    let cancelURL: URL?
    let symbol: String
}

enum ServiceCatalog {
    private static func d(_ value: String) -> Decimal { Decimal(string: value) ?? 0 }

    static let all: [KnownService] = [
        .init(name: "Netflix", price: d("17.99"), cycle: .monthly, category: "Streaming", cancelURL: URL(string: "https://www.netflix.com/cancelplan"), symbol: "play.tv"),
        .init(name: "Spotify", price: d("11.99"), cycle: .monthly, category: "Music", cancelURL: URL(string: "https://www.spotify.com/account/subscription/"), symbol: "music.note"),
        .init(name: "Amazon Prime", price: d("14.99"), cycle: .monthly, category: "Shopping", cancelURL: URL(string: "https://www.amazon.com/mc/pipelines/cancellation"), symbol: "shippingbox"),
        .init(name: "Disney+", price: d("15.99"), cycle: .monthly, category: "Streaming", cancelURL: URL(string: "https://www.disneyplus.com/account/subscription"), symbol: "sparkles.tv"),
        .init(name: "HBO Max", price: d("16.99"), cycle: .monthly, category: "Streaming", cancelURL: URL(string: "https://auth.max.com/subscription"), symbol: "tv"),
        .init(name: "YouTube Premium", price: d("13.99"), cycle: .monthly, category: "Streaming", cancelURL: URL(string: "https://www.youtube.com/paid_memberships"), symbol: "play.rectangle"),
        .init(name: "Apple One", price: d("19.95"), cycle: .monthly, category: "Apple", cancelURL: URL(string: "https://apps.apple.com/account/subscriptions"), symbol: "apple.logo"),
        .init(name: "iCloud+", price: d("2.99"), cycle: .monthly, category: "Apple", cancelURL: URL(string: "https://apps.apple.com/account/subscriptions"), symbol: "icloud"),
        .init(name: "Audible", price: d("14.95"), cycle: .monthly, category: "Books", cancelURL: URL(string: "https://www.audible.com/account/overview"), symbol: "headphones"),
        .init(name: "Adobe Creative Cloud", price: d("59.99"), cycle: .monthly, category: "Software", cancelURL: URL(string: "https://account.adobe.com/plans"), symbol: "paintbrush"),
        .init(name: "ChatGPT Plus", price: d("20.00"), cycle: .monthly, category: "Software", cancelURL: URL(string: "https://chatgpt.com/#settings/Subscription"), symbol: "bubble.left.and.text.bubble.right"),
        .init(name: "Planet Fitness", price: d("15.00"), cycle: .monthly, category: "Fitness", cancelURL: URL(string: "https://www.planetfitness.com/my-account"), symbol: "figure.run"),
    ]

    static func match(_ name: String) -> KnownService? {
        let key = name.trimmingCharacters(in: .whitespaces).lowercased()
        return all.first { $0.name.lowercased() == key }
    }

    /// Where to cancel: the service's own page, else Apple's subscriptions page (covers anything billed through the App Store).
    static func cancelURL(for name: String) -> URL {
        if let url = match(name)?.cancelURL { return url }
        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: "how to cancel \(name) subscription")]
        return components.url!
    }

    static func symbol(for name: String) -> String {
        match(name)?.symbol ?? "creditcard"
    }
}
