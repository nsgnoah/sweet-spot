import SwiftUI

struct GameView: View {
    @State private var game: Game
    @State private var hintTarget: Int?
    @State private var confirmRestart = false
    @State private var showHelp = false
    @State private var drag = WordDrag()

    init(puzzle: Puzzle) {
        _game = State(initialValue: Game(puzzle: puzzle))
    }

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            // Side by side only while the board still gets a comfortable width next to the panel
            let boardWidth = min(700, (geo.size.height - 32) * VennBoard.design.width / VennBoard.design.height, geo.size.width - 64 - 32 - 288)
            let wide = sizeClass == .regular && geo.size.width > geo.size.height && boardWidth >= 320
            // The first layout pass can report a zero size; wait for the real one so only one board is built.
            if geo.size.width > 0 {
                ScrollView {
                    Group {
                        if wide {
                            // iPad landscape: board on the left, everything else beside it
                            HStack(alignment: .top, spacing: 32) {
                                VennBoard(game: game, drag: drag)
                                    .frame(maxWidth: boardWidth)
                                VStack(spacing: 16) {
                                    legend
                                    panel
                                }
                                .frame(minWidth: 288, maxWidth: 360)
                            }
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                        } else {
                            VStack(spacing: 16) {
                                legend
                                VennBoard(game: game, drag: drag)
                                    .padding(.horizontal, -4)
                                panel
                            }
                            .frame(maxWidth: 640)
                            .padding(.horizontal, 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 32)
                    .coordinateSpace(name: WordDrag.space)
                    .overlay(alignment: .topLeading) {
                        // The word under your finger while dragging
                        if let w = drag.word {
                            WordChip(text: game.puzzle.words[w], selected: true)
                                .fixedSize()
                                .position(drag.location)
                                .allowsHitTesting(false)
                        }
                    }
                    .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.85), value: game.state.placements)
                    .animation(.easeInOut, value: game.state.finished)
                }
                .scrollDisabled(drag.word != nil)
            }
        }
        .background(Theme.ground)
        .navigationTitle("Sweet Spot #\(game.puzzle.id)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("How to play", systemImage: "questionmark.circle") { showHelp = true }
                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Start over", systemImage: "arrow.counterclockwise", role: .destructive) { confirmRestart = true }
                }
            }
        }
        .overlay(alignment: .top) {
            if let toast = game.toast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.primary))
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3), value: game.toast)
        .confirmationDialog("Reveal circle \(["A", "B", "C"][hintTarget ?? 0])?",
                            isPresented: Binding(get: { hintTarget != nil }, set: { if !$0 { hintTarget = nil } }),
                            titleVisibility: .visible) {
            Button("Reveal category") { if let c = hintTarget { game.reveal(c) } }
        } message: {
            Text("Hints show up as 💡 when you share your result.")
        }
        .confirmationDialog("Start this puzzle over?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Start over", role: .destructive) { game.restart() }
        }
        .sheet(isPresented: $showHelp) { HowToPlayView() }
    }

    @ViewBuilder
    private var panel: some View {
        if game.state.finished {
            ResultCard(game: game)
            history
            AnswerList(puzzle: game.puzzle)
        } else {
            bank
            controls
            if !game.state.guesses.isEmpty { history }
        }
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                let revealed = game.isRevealed(i)
                Button {
                    if !revealed { hintTarget = i }
                } label: {
                    HStack(spacing: 10) {
                        Text(["A", "B", "C"][i])
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Theme.circles[i]))
                            .accessibilityLabel("Circle \(["A", "B", "C"][i]):")
                        if revealed {
                            Text(game.puzzle.categories[i])
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.primary)
                        } else {
                            Text("Mystery category")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Label("Hint", systemImage: "lightbulb")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.circles[i].opacity(revealed ? 0.18 : 0.08)))
                }
                .buttonStyle(.plain)
                .accessibilityRemoveTraits(revealed ? .isButton : [])
                .accessibilityHint(revealed ? "" : "Reveals this category. Shows as a hint when you share.")
            }
        }
        .padding(.top, 8)
    }

    private var bank: some View {
        VStack(spacing: 10) {
            Text(game.bank.isEmpty ? (game.selected != nil ? "Tap here to take a word off the board" : "All placed — submit when ready")
                 : game.selected == nil ? "Drag each word to where it belongs" : "Now tap a spot on the diagram")
                .font(.footnote)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(game.bank, id: \.self) { w in
                    WordChip(text: game.puzzle.words[w], selected: game.selected == w)
                        .hoverEffect(.lift)
                        .onTapGesture { game.tapWord(w) }
                        .draggableWord(w, game: game, drag: drag)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(game.puzzle.words[w])
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAddTraits(game.selected == w ? .isSelected : [])
                        .accessibilityHint("Selects the word. Then choose an empty spot, or use actions to place it.")
                        .accessibilityAction { game.tapWord(w) }
                        .accessibilityActions {
                            ForEach(VennBoard.readingOrder, id: \.self) { region in
                                Button("Place in \(VennBoard.regionName(region))") { game.drop(w, on: region) }
                            }
                        }
                }
            }
            .frame(minHeight: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.primary.opacity(0.04)))
        .contentShape(Rectangle())
        .onTapGesture { game.tapBank() }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text("Guesses left")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(0..<Game.maxGuesses, id: \.self) { i in
                    Circle()
                        .fill(i < game.guessesLeft ? Color.primary.opacity(0.75) : Color.primary.opacity(0.12))
                        .frame(width: 10, height: 10)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(game.guessesLeft) of \(Game.maxGuesses) guesses left")
            PillRow {
                Button("Clear") { game.clearBoard() }
                    .buttonStyle(PillStyle(filled: false))
                    .disabled(game.state.placements.count == game.locked.count)
                Button("Submit") { game.submit() }
                    .buttonStyle(PillStyle(filled: true))
                    .disabled(!game.canSubmit)
            }
        }
    }

    private var history: some View {
        VStack(spacing: 6) {
            ForEach(Array(game.state.guesses.enumerated()), id: \.offset) { n, guess in
                HStack(spacing: 4) {
                    ForEach(Array(game.marks(guess).enumerated()), id: \.offset) { _, m in
                        MarkDot(mark: m)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Guess \(n + 1): " + zip(game.puzzle.words, game.marks(guess)).map { "\($0) \($1.spoken)" }.joined(separator: ", "))
            }
        }
        .padding(.top, 4)
    }
}

/// Buttons side by side, or stacked when large text won't fit them on one line.
struct PillRow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { content }
            VStack(spacing: 12) { content }
        }
    }
}

struct PillStyle: ButtonStyle {
    var filled: Bool
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(minWidth: 110)
            .padding(.vertical, 13)
            .foregroundStyle(filled ? Color(uiColor: .systemBackground) : .primary)
            .background(Capsule().fill(filled ? Color.primary : .clear))
            .overlay(Capsule().strokeBorder(Color.primary, lineWidth: filled ? 0 : 1.5))
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct ResultCard: View {
    let game: Game
    @State private var copied = false

    var body: some View {
        VStack(spacing: 14) {
            Text(game.state.won ? headline : "Next time!")
                .font(.display(28))
            Text(game.state.won
                 ? "Solved in \(game.state.guesses.count) of \(Game.maxGuesses)\(game.state.hints.isEmpty ? " with no hints" : "")."
                 : "The board now shows where every word belongs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PillRow {
                ShareLink(item: game.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PillStyle(filled: true))
                Button(copied ? "Copied" : "Copy") {
                    UIPasteboard.general.string = game.shareText
                    copied = true
                    Haptics.tap(.light)
                }
                .buttonStyle(PillStyle(filled: false))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.chip))
    }

    private var headline: String {
        switch game.state.guesses.count {
        case 1: "Unreal!"
        case 2: "Brilliant!"
        case 3: "Excellent!"
        case 4: "Nicely done!"
        case 5: "Got it!"
        default: "Phew!"
        }
    }
}

struct AnswerList: View {
    let puzzle: Puzzle

    var body: some View {
        // Center first, then pairs, then singles
        let order = [7, 3, 5, 6, 1, 2, 4].compactMap { region in puzzle.answers.firstIndex(of: region) }
        VStack(alignment: .leading, spacing: 0) {
            Text("THE ANSWERS")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)
            ForEach(order, id: \.self) { i in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    RegionDots(mask: puzzle.answers[i])
                    VStack(alignment: .leading, spacing: 2) {
                        Text(puzzle.words[i])
                            .font(.subheadline.weight(.heavy))
                        Text(puzzle.whys[i])
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                if i != order.last { Divider() }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.chip))
    }
}

/// Three dots showing which circles a region belongs to.
struct RegionDots: View {
    let mask: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { k in
                let on = mask & (1 << k) != 0
                Circle()
                    .fill(on ? Theme.circles[k] : .clear)
                    .overlay(Circle().strokeBorder(on ? .clear : Color.primary.opacity(0.2), lineWidth: 1.5))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityLabel(["A", "B", "C"].enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element).joined(separator: " and "))
    }
}

/// One guess result as a circle: full for right spot, half for close, empty for a miss.
/// Matches the ● ◐ ○ used in the shared result.
struct MarkDot: View {
    let mark: Mark

    var body: some View {
        Image(systemName: mark == .green ? "circle.fill" : mark == .yellow ? "circle.lefthalf.filled" : "circle")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.ink(mark))
            .frame(width: 20, height: 20)
            .accessibilityLabel(mark.spoken)
    }
}
