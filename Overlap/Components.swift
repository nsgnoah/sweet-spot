import SwiftUI

enum Theme {
    static let circles: [Color] = [
        Color(red: 0.33, green: 0.55, blue: 0.93),   // lake blue
        Color(red: 0.92, green: 0.43, blue: 0.28),   // campfire orange
        Color(red: 0.60, green: 0.46, blue: 0.86),   // dusk purple
    ]
    static let green = Color(red: 0.38, green: 0.64, blue: 0.35)
    static let yellow = Color(red: 0.79, green: 0.70, blue: 0.33)
    static let gray = Color(red: 0.47, green: 0.49, blue: 0.50)
    /// Darker green and yellow for small marks drawn straight on the light background, so they stay legible.
    static let greenInk = adaptive(light: (0.30, 0.50, 0.28), dark: (0.38, 0.64, 0.35))
    static let yellowInk = adaptive(light: (0.50, 0.44, 0.18), dark: (0.79, 0.70, 0.33))
    static let chip = Color(uiColor: .secondarySystemGroupedBackground)
    static let ground = Color(uiColor: .systemGroupedBackground)

    static func color(_ mark: Mark) -> Color {
        switch mark {
        case .green: green
        case .yellow: yellow
        case .gray: gray
        }
    }

    static func ink(_ mark: Mark) -> Color {
        switch mark {
        case .green: greenInk
        case .yellow: yellowInk
        case .gray: gray
        }
    }

    /// Text drawn on a mark's fill: dark on yellow, white on the others.
    static func onColor(_ mark: Mark) -> Color {
        mark == .yellow ? Color.black.opacity(0.8) : .white
    }

    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}

extension Font {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .serif) }
}

struct WordChip: View {
    let text: String
    var mark: Mark? = nil
    var selected = false
    var locked = false
    var size: CGFloat = 15
    var maxWidth: CGFloat? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Shrink long words so every chip hugs its text instead of stretching to fill.
        let fitted = maxWidth.map { min(size, ($0 - size * 1.2) / (CGFloat(text.count) * 0.78)) } ?? size
        Text(text)
            .font(.system(size: fitted, weight: .heavy))
            .tracking(0.3)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, size * 0.6)
            .padding(.vertical, size * 0.45 + (size - fitted) / 2)
            .foregroundStyle(mark.map(Theme.onColor) ?? Color.primary)
            .background(
                RoundedRectangle(cornerRadius: size * 0.5, style: .continuous)
                    .fill(mark.map(Theme.color) ?? Theme.chip)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.5, style: .continuous)
                    .strokeBorder(selected ? Color.primary : Color.primary.opacity(mark == nil ? 0.15 : 0), lineWidth: selected ? 2.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                // A symbol as well as a color, so close and miss read the same way in grayscale
                if let mark, let symbol = badge(mark) {
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(Theme.onColor(mark))
                        .padding(3)
                        .background(Circle().fill(Theme.color(mark).opacity(0.95)))
                        .overlay(Circle().strokeBorder(Color(uiColor: .systemBackground), lineWidth: 1))
                        .offset(x: 5, y: -5)
                        .accessibilityHidden(true)
                }
            }
            .shadow(color: .black.opacity(selected ? 0.25 : 0.08), radius: selected ? 6 : 1.5, y: selected ? 3 : 1)
            .scaleEffect(selected && !reduceMotion ? 1.1 : 1)
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.25, dampingFraction: 0.7), value: selected)
    }

    private func badge(_ mark: Mark) -> String? {
        switch mark {
        case .green: locked ? "lock.fill" : nil
        case .yellow: "circle.lefthalf.filled"
        case .gray: "xmark"
        }
    }
}

/// Wraps children onto centered rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? .infinity, subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(bounds.width, subviews) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for (index, size) in row.items {
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var items: [(Int, CGSize)] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ maxWidth: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for (i, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            let needed = row.items.isEmpty ? size.width : row.width + spacing + size.width
            if needed > maxWidth, !row.items.isEmpty {
                rows.append(row)
                row = Row()
            }
            row.width = row.items.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.items.append((i, size))
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}

/// Three overlapping circles, used as the logo.
struct VennMark: View {
    var size: CGFloat = 44

    var body: some View {
        let r = size * 0.36
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let angle = [Double.pi * 5 / 6, .pi / 6, -.pi / 2][i]
                Circle()
                    .fill(Theme.circles[i].opacity(0.7))
                    .frame(width: r * 2, height: r * 2)
                    .offset(x: cos(angle) * r * 0.62, y: -sin(angle) * r * 0.62 + r * 0.05)
                    .blendMode(.multiply)
            }
        }
        .frame(width: size, height: size)
        .compositingGroup()
    }
}
