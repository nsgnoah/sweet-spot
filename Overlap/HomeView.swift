import SwiftUI

@main
struct OverlapApp: App {
    var body: some Scene {
        WindowGroup { HomeView() }
    }
}

struct HomeView: View {
    @AppStorage("seenHowTo") private var seenHowTo = false
    @State private var showHelp = false
    @State private var path: [Puzzle] = []
    @State private var refresh = 0

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    todayCard
                    archive
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Theme.ground)
            .navigationDestination(for: Puzzle.self) { GameView(puzzle: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }
                }
            }
            .onAppear { refresh += 1 }
        }
        .sheet(isPresented: $showHelp) { HowToPlayView() }
        .onAppear { if !seenHowTo { showHelp = true; seenHowTo = true } }
    }

    private var header: some View {
        VStack(spacing: 10) {
            VennMark(size: 76)
            Text("Overlap")
                .font(.display(44))
            Text("Seven words. Three mystery circles.\nFigure out where each one belongs.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var todayCard: some View {
        let today = Puzzles.today
        let state = Store.load(today)
        let next = Puzzles.all.first { $0 != today && !Store.load($0).finished }
        return VStack(spacing: 14) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Puzzle #\(today.id)")
                .font(.display(26))
            if state.finished, let next {
                HStack(spacing: 12) {
                    Button("See result") { path.append(today) }
                        .buttonStyle(PillStyle(filled: false))
                    Button("Play #\(next.id)") { path.append(next) }
                        .buttonStyle(PillStyle(filled: true))
                }
            } else {
                Button(buttonTitle(state)) { path.append(today) }
                    .buttonStyle(PillStyle(filled: true))
            }
        }
        .id(refresh)
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.chip))
    }

    private var archive: some View {
        let states = Puzzles.all.map(Store.load)
        let won = states.filter(\.won)
        let missed = states.filter { $0.finished && !$0.won }.count
        let average = won.isEmpty ? 0 : Double(won.map(\.guesses.count).reduce(0, +)) / Double(won.count)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("ALL \(Puzzles.all.count) PUZZLES")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Spacer()
                if !won.isEmpty || missed > 0 {
                    Text("\(won.count) solved · \(missed) missed\(won.isEmpty ? "" : " · avg " + average.formatted(.number.precision(.fractionLength(1))))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(Array(Puzzles.all.enumerated()), id: \.element.key) { i, puzzle in
                    Button { path.append(puzzle) } label: {
                        PuzzleTile(number: puzzle.id, state: states[i], isToday: puzzle == Puzzles.today)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .id(refresh)
    }

    private func buttonTitle(_ state: GameState) -> String {
        state.finished ? "See result" : state.started ? "Continue" : "Play"
    }
}

struct PuzzleTile: View {
    let number: Int
    let state: GameState
    let isToday: Bool

    var body: some View {
        let fill: Color = state.won ? Theme.green : state.finished ? Theme.gray : Theme.chip
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(fill)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: 1) {
                    Text("\(number)")
                        .font(.system(size: 19, weight: .bold, design: .serif))
                    Text(caption)
                        .font(.system(size: 10, weight: .semibold))
                        .opacity(0.85)
                }
                .monospacedDigit()
                .foregroundStyle(state.finished ? Color.white : Color.primary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(state.started && !state.finished ? Theme.yellow : .clear, lineWidth: 2.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isToday ? Color.primary : .clear, lineWidth: 2)
                    .padding(-3)
            )
        .accessibilityLabel("Puzzle \(number), \(caption.isEmpty ? "not started" : caption)")
    }

    private var caption: String {
        if state.won { return "\(state.guesses.count)/\(Game.maxGuesses)" }
        if state.finished { return "missed" }
        if state.started { return "playing" }
        return isToday ? "today" : " "
    }
}


struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Every puzzle has three hidden categories, drawn as overlapping circles. Each of the seven words belongs in exactly one of the seven spaces, so every space gets one word.")
                    example
                    Text("Tap a word, then tap a spot to place it. When all seven are placed, submit. You get six tries.")
                    VStack(alignment: .leading, spacing: 10) {
                        row(.green, "Right spot. It locks in place.")
                        row(.yellow, "Wrong spot, but it shares at least one circle with the right one.")
                        row(.gray, "No circles in common with the right spot.")
                    }
                    Text("While a word is selected, empty spots show how it did there before: ✕ for gray, a dot for yellow.")
                    Text("Stuck? Tap a mystery category to reveal it. Hints show as 💡 when you share.")
                    Text("A new puzzle unlocks each day, and you can play any of them from the list.")
                        .foregroundStyle(.secondary)
                }
                .font(.body)
                .padding(20)
            }
            .navigationTitle("How to play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Got it") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }

    private var example: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EXAMPLE").font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(.secondary)
            Text("If the circles were **Red**, **Fruit**, and **Round**, then APPLE goes in the very middle (all three), STRAWBERRY goes where red and fruit overlap, and BASEBALL sits alone in round.")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.05)))
    }

    private func row(_ mark: Mark, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 5).fill(Theme.color(mark)).frame(width: 24, height: 24)
            Text(text)
        }
    }
}
