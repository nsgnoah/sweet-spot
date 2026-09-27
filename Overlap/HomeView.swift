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
        let state = Store.load(today.id)
        return VStack(spacing: 14) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Puzzle #\(today.id)")
                .font(.display(26))
            Button(buttonTitle(state)) { path.append(today) }
                .buttonStyle(PillStyle(filled: true))
        }
        .id(refresh)
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.chip))
    }

    private var archive: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALL PUZZLES")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(Puzzles.all) { puzzle in
                    let state = Store.load(puzzle.id)
                    Button { path.append(puzzle) } label: {
                        HStack {
                            Text("#\(puzzle.id)")
                                .font(.system(.body, design: .serif).weight(.bold))
                                .frame(width: 40, alignment: .leading)
                            status(state)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if puzzle.id != Puzzles.all.last?.id { Divider().padding(.leading, 16) }
                }
            }
            .id(refresh)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.chip))
        }
    }

    @ViewBuilder
    private func status(_ state: GameState) -> some View {
        if state.finished && state.won {
            Label("Solved in \(state.guesses.count)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Theme.green)
        } else if state.finished {
            Label("Missed", systemImage: "xmark.circle.fill")
                .foregroundStyle(Theme.gray)
        } else if state.started {
            Label("In progress", systemImage: "circle.lefthalf.filled")
                .foregroundStyle(Theme.yellow)
        } else {
            Text("Not started").foregroundStyle(.secondary)
        }
    }

    private func buttonTitle(_ state: GameState) -> String {
        state.finished ? "See result" : state.started ? "Continue" : "Play"
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
