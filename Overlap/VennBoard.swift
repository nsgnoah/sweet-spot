import SwiftUI

struct VennBoard: View {
    let game: Game

    // Layout in a 360 × 320 design space, scaled to fit.
    static let design = CGSize(width: 360, height: 320)
    static let radius: CGFloat = 96
    static let centers = [CGPoint(x: 130, y: 120), CGPoint(x: 230, y: 120), CGPoint(x: 180, y: 205)]
    static let slots: [Int: CGPoint] = [
        1: CGPoint(x: 90, y: 98), 2: CGPoint(x: 270, y: 98), 4: CGPoint(x: 180, y: 262),
        3: CGPoint(x: 180, y: 80), 5: CGPoint(x: 124, y: 180), 6: CGPoint(x: 236, y: 180),
        7: CGPoint(x: 180, y: 146),
    ]

    static func region(at p: CGPoint) -> Int {
        centers.enumerated().reduce(0) { mask, item in
            hypot(p.x - item.element.x, p.y - item.element.y) <= radius ? mask | (1 << item.offset) : mask
        }
    }

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / Self.design.width
            ZStack {
                circles(s)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { loc in
                        let region = Self.region(at: CGPoint(x: loc.x / s, y: loc.y / s))
                        if region == 0 { game.selected = nil } else { game.tapRegion(region) }
                    }

                ForEach(Array(Self.slots.keys), id: \.self) { region in
                    slot(region, s)
                        .position(x: Self.slots[region]!.x * s, y: Self.slots[region]!.y * s)
                }
            }
        }
        .aspectRatio(Self.design.width / Self.design.height, contentMode: .fit)
    }

    private func circles(_ s: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let c = Self.centers[i]
                Circle()
                    .fill(Theme.circles[i].opacity(0.16))
                    .overlay(Circle().strokeBorder(Theme.circles[i].opacity(0.9), lineWidth: 2.5))
                    .frame(width: Self.radius * 2 * s, height: Self.radius * 2 * s)
                    .position(x: c.x * s, y: c.y * s)
            }
            // Circle badges, so the legend's colors map to the board
            ForEach(0..<3, id: \.self) { i in
                let spots = [CGPoint(x: 44, y: 40), CGPoint(x: 316, y: 40), CGPoint(x: 272, y: 290)]
                Text(["A", "B", "C"][i])
                    .font(.system(size: 13 * s, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 24 * s, height: 24 * s)
                    .background(Circle().fill(Theme.circles[i]))
                    .position(x: spots[i].x * s, y: spots[i].y * s)
            }
        }
    }

    @ViewBuilder
    private func slot(_ region: Int, _ s: CGFloat) -> some View {
        if let w = game.word(in: region) {
            WordChip(
                text: game.puzzle.words[w],
                mark: game.mark(for: w),
                selected: game.selected == w,
                locked: game.locked.contains(w) && !game.state.finished,
                size: 13 * s,
                maxWidth: 92 * s
            )
            .animation(.easeOut(duration: 0.3).delay(Double(w) * 0.07), value: game.state.guesses.count)
            .onTapGesture { game.tapWord(w) }
            .transition(.scale.combined(with: .opacity))
        } else {
            let past = game.selected.flatMap { game.history(word: $0, region: region) }
            RoundedRectangle(cornerRadius: 7 * s, style: .continuous)
                .strokeBorder(Color.primary.opacity(game.selected == nil ? 0.18 : 0.4),
                              style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .background(RoundedRectangle(cornerRadius: 7 * s).fill(Color.primary.opacity(0.03)))
                .frame(width: 44 * s, height: 26 * s)
                .overlay {
                    switch past {
                    case .gray: Image(systemName: "xmark").font(.system(size: 11 * s, weight: .bold)).foregroundStyle(Theme.gray)
                    case .yellow: Circle().fill(Theme.yellow).frame(width: 10 * s)
                    default: EmptyView()
                    }
                }
                .onTapGesture { game.tapRegion(region) }
        }
    }
}
