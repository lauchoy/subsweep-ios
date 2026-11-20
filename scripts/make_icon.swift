import AppKit

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let rect = NSRect(x: 0, y: 0, width: size, height: size)
NSGradient(colors: [NSColor(red: 0.19, green: 0.78, blue: 0.75, alpha: 1), NSColor(red: 0.12, green: 0.35, blue: 0.85, alpha: 1)])!
    .draw(in: rect, angle: -45)
let config = NSImage.SymbolConfiguration(pointSize: 560, weight: .semibold)
    .applying(.init(paletteColors: [.white]))
if let symbol = NSImage(systemSymbolName: "creditcard.and.123", accessibilityDescription: nil)?.withSymbolConfiguration(config)
    ?? NSImage(systemSymbolName: "creditcard", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
    let s = symbol.size
    symbol.draw(in: NSRect(x: (CGFloat(size) - s.width) / 2, y: (CGFloat(size) - s.height) / 2 + 40, width: s.width, height: s.height))
}
let check = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)!
    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 300, weight: .bold).applying(.init(paletteColors: [.white, NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1)])))!
check.draw(in: NSRect(x: 600, y: 120, width: check.size.width, height: check.size.height))
NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
