import SwiftUI

enum Ink {
    static let bg = Color(red: 0.025, green: 0.045, blue: 0.09)
    static let panel = Color(red: 0.065, green: 0.085, blue: 0.14)
    static let gold = Color(red: 0.94, green: 0.77, blue: 0.44)
    static let cyan = Color(red: 0.42, green: 0.82, blue: 0.86)
    static let text = Color(red: 0.96, green: 0.95, blue: 0.90)
    static let muted = Color(red: 0.66, green: 0.71, blue: 0.78)
}

struct UniverseBackground: View {
    var body: some View {
        LinearGradient(colors: [Ink.bg, Color(red: 0.07, green: 0.08, blue: 0.16), Ink.bg], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text).font(.system(.caption2, design: .monospaced).weight(.medium)).tracking(2.2).foregroundStyle(Ink.gold) }
}

extension View {
    func readingCard() -> some View {
        padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Ink.panel.opacity(0.85), in: .rect(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.065)) }
    }
}

struct GlassAction: View {
    let title: String
    var symbol = "arrow.right"
    var prominent = false
    var id: String = ""
    let action: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var opaque
    var body: some View {
        if opaque {
            Button(action: action) { label }.buttonStyle(.borderedProminent).tint(Ink.gold).foregroundStyle(Ink.bg).accessibilityIdentifier(id)
        } else if prominent {
            Button(action: action) { label }.buttonStyle(.glassProminent).tint(Ink.gold).foregroundStyle(Ink.bg).accessibilityIdentifier(id)
        } else {
            Button(action: action) { label }.buttonStyle(.glass).tint(Ink.gold).accessibilityIdentifier(id)
        }
    }
    private var label: some View {
        HStack(spacing: 10) { Text(title).font(.subheadline.weight(.semibold)); Image(systemName: symbol).font(.caption.weight(.semibold)) }
            .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 8)
    }
}

func decimal(_ value: Double, digits: Int = 2) -> String { value.formatted(.number.precision(.fractionLength(0...digits))) }
