import SwiftUI

/// Tracks a word being dragged across the game screen.
/// Locations are in the "game" coordinate space, which GameView defines.
@Observable
final class WordDrag {
    static let space = "game"

    var word: Int?
    var location: CGPoint = .zero
    /// Each on-screen board's frame, keyed by board, so a board torn down in a layout change
    /// (rotating an iPad, say) can't overwrite the frame of the one that replaced it.
    var boards: [UUID: CGRect] = [:]

    /// The board region under a point, or 0 when it's off the circles.
    func region(at p: CGPoint) -> Int {
        guard let frame = boards.values.first(where: { $0.width > 0 && $0.contains(p) }) else { return 0 }
        let s = frame.width / VennBoard.design.width
        return VennBoard.region(at: CGPoint(x: (p.x - frame.minX) / s, y: (p.y - frame.minY) / s))
    }

    var hoverRegion: Int? {
        guard word != nil else { return nil }
        let r = region(at: location)
        return r == 0 ? nil : r
    }
}

private struct Draggable: ViewModifier {
    let word: Int
    let game: Game
    let drag: WordDrag

    @GestureState private var dragging = false

    private var enabled: Bool { !game.state.finished && !game.locked.contains(word) }

    func body(content: Content) -> some View {
        content
            .opacity(drag.word == word ? 0.25 : 1)
            .gesture(
                DragGesture(minimumDistance: 6, coordinateSpace: .named(WordDrag.space))
                    .updating($dragging) { _, state, _ in state = true }
                    .onChanged { value in
                        if drag.word == nil {
                            game.selected = nil
                            Haptics.select()
                        }
                        drag.word = word
                        drag.location = value.location
                    }
                    .onEnded { value in
                        let region = drag.region(at: value.location)
                        if region > 0 { game.drop(word, on: region) } else { game.unplace(word) }
                        drag.word = nil
                    },
                including: enabled ? .all : .subviews
            )
            // A cancelled drag (the app going to the background, say) never calls onEnded,
            // but gesture state still resets, so let go of the word here.
            .onChange(of: dragging) { _, isDragging in
                if !isDragging && drag.word == word { drag.word = nil }
            }
    }
}

extension View {
    func draggableWord(_ word: Int, game: Game, drag: WordDrag) -> some View {
        modifier(Draggable(word: word, game: game, drag: drag))
    }
}
