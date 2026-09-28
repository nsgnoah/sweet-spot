import SwiftUI

struct GameView: View {
    @State private var game: Game
    @State private var hintTarget: Int?
    @State private var confirmRestart = false
    @State private var showHelp = false

    init(puzzle: Puzzle) {
        _game = State(initialValue: Game(puzzle: puzzle))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                legend
                VennBoard(game: game)
                    .padding(.horizontal, -4)
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
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: game.state.placements)
            .animation(.easeInOut, value: game.state.finished)
        }
        .background(Theme.ground)
        .navigationTitle("Overlap #\(game.puzzle.id)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }
                Menu {
                    Button("Start over", systemImage: "arrow.counterclockwise", role: .destructive) { confirmRestart = true }
                } label: { Image(systemName: "ellipsis.circle") }
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
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: game.toast)
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
                        if revealed {
                            Text(game.puzzle.categories[i])
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        } else {
                            Text("Mystery category")
                                .font(.system(size: 16))
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
            }
        }
        .padding(.top, 8)
    }

    private var bank: some View {
        VStack(spacing: 10) {
            Text(game.bank.isEmpty ? (game.selected != nil ? "Tap here to take a word off the board" : "All placed — submit when ready")
                 : game.selected == nil ? "Tap a word, then tap where it belongs" : "Now tap a spot on the diagram")
                .font(.footnote)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(game.bank, id: \.self) { w in
                    WordChip(text: game.puzzle.words[w], selected: game.selected == w)
                        .onTapGesture { game.tapWord(w) }
                        .transition(.scale.combined(with: .opacity))
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
            HStack(spacing: 12) {
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
            ForEach(Array(game.state.guesses.enumerated()), id: \.offset) { _, guess in
                HStack(spacing: 4) {
                    ForEach(Array(game.marks(guess).enumerated()), id: \.offset) { _, m in
                        RoundedRectangle(cornerRadius: 3).fill(Theme.color(m)).frame(width: 18, height: 18)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}

struct PillStyle: ButtonStyle {
    var filled: Bool
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
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
            HStack(spacing: 12) {
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
                            .font(.system(size: 15, weight: .heavy))
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
