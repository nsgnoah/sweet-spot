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
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
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
            Text("Sweet Spot")
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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60, maximum: 90), spacing: 8)], spacing: 8) {
                ForEach(Array(Puzzles.all.enumerated()), id: \.element.key) { i, puzzle in
                    Button { path.append(puzzle) } label: {
                        PuzzleTile(number: puzzle.id, state: states[i], isToday: puzzle == Puzzles.today)
                    }
                    .hoverEffect(.lift)
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
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    VennMark(size: 56)
                    Text("How to play")
                        .font(.display(34))
                    Text("Seven words. Three mystery circles.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 28)

                card("The idea") {
                    Text("Each puzzle hides three categories, drawn as overlapping circles. Every word belongs in exactly one of the seven spaces, and every space gets one word.")
                    ExampleVenn()
                        .padding(.top, 4)
                    Text("APPLE is red, a fruit, and round, so it sits in the middle. STRAWBERRY is red and a fruit but not round. BANANA is only a fruit.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                card("Playing") {
                    step("hand.draw", "Drag each word to a spot on the diagram. You can also tap a word, then tap a spot.")
                    step("checkmark.circle", "Submit once all seven are placed. You get six tries.")
                    step("lightbulb", "Stuck? Tap a mystery category to reveal it. Hints show as 💡 when you share.")
                }

                card("After each try") {
                    step("circle.fill", "**Right spot.** The word locks in place.")
                    step("circle.lefthalf.filled", "**Close.** It shares at least one circle with the right spot.")
                    step("circle", "**Miss.** No circles in common with the right spot.")
                    Text("When you share, your guesses show as ● ◐ ○ in the same way.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("When you pick up a word, empty spots remember how it did there before.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("A new puzzle unlocks every day, and you can play any of them from the grid.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                Button("Let\u{2019}s play") { dismiss() }
                    .buttonStyle(PillStyle(filled: true))
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
        .background(Theme.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.display(22))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.chip))
    }

    private func step(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 22)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A small, static Venn diagram with the how-to-play example filled in.
struct ExampleVenn: View {
    private let words: [(String, Int)] = [
        ("FIRE TRUCK", 1), ("BANANA", 2), ("BASEBALL", 4),
        ("STRAWBERRY", 3), ("CLOWN NOSE", 5), ("ORANGE", 6), ("APPLE", 7),
    ]
    private let names = ["Red", "Fruit", "Round"]

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let s = geo.size.width / VennBoard.design.width
                ZStack {
                    VennBoard.backdrop(s)
                    ForEach(words, id: \.0) { word, region in
                        WordChip(text: word, size: 13 * s, maxWidth: 92 * s)
                            .position(x: VennBoard.slots[region]!.x * s, y: VennBoard.slots[region]!.y * s)
                    }
                }
            }
            .aspectRatio(VennBoard.design.width / VennBoard.design.height, contentMode: .fit)

            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 6) {
                        Text(["A", "B", "C"][i])
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Theme.circles[i]))
                        Text(names[i])
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example with circles Red, Fruit, and Round: FIRE TRUCK is red only, BANANA fruit only, BASEBALL round only, STRAWBERRY red and fruit, CLOWN NOSE red and round, ORANGE fruit and round, APPLE all three")
    }
}
