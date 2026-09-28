import SwiftUI
import UIKit

enum Mark: Int, Codable {
    case green, yellow, gray

    var emoji: String {
        switch self {
        case .green: "🟩"
        case .yellow: "🟨"
        case .gray: "⬜"
        }
    }
}

struct GameState: Codable {
    var placements: [Int: Int] = [:]   // word index -> region mask
    var guesses: [[Int]] = []          // region mask per word, in word order
    var hints: Set<Int> = []           // revealed category indices
    var finished = false
    var won = false

    var started: Bool { !placements.isEmpty || !guesses.isEmpty || !hints.isEmpty }
}

enum Store {
    private static func key(_ puzzle: Puzzle) -> String { "overlap.puzzle.\(puzzle.key)" }

    static func load(_ puzzle: Puzzle) -> GameState {
        guard let data = UserDefaults.standard.data(forKey: key(puzzle)),
              let state = try? JSONDecoder().decode(GameState.self, from: data) else { return GameState() }
        return state
    }

    static func save(_ state: GameState, _ puzzle: Puzzle) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key(puzzle))
        }
    }

    static func reset(_ puzzle: Puzzle) { UserDefaults.standard.removeObject(forKey: key(puzzle)) }
}

@Observable
final class Game {
    static let maxGuesses = 6

    let puzzle: Puzzle
    private(set) var state: GameState
    var selected: Int?
    var toast: String?

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.state = Store.load(puzzle)
    }

    var count: Int { puzzle.words.count }
    var guessesLeft: Int { Self.maxGuesses - state.guesses.count }

    func marks(_ guess: [Int]) -> [Mark] {
        guess.enumerated().map { i, region in
            let truth = puzzle.answers[i]
            if region == truth { return .green }
            return region & truth != 0 ? .yellow : .gray
        }
    }

    /// Words that were green on the latest guess can't move.
    var locked: Set<Int> {
        guard let last = state.guesses.last else { return [] }
        return Set(marks(last).enumerated().filter { $0.element == .green }.map(\.offset))
    }

    /// When a game is lost, the board shows the answers.
    var board: [Int: Int] {
        if state.finished && !state.won {
            return Dictionary(uniqueKeysWithValues: puzzle.answers.enumerated().map { ($0.offset, $0.element) })
        }
        return state.placements
    }

    var bank: [Int] { (0..<count).filter { board[$0] == nil } }

    func word(in region: Int) -> Int? { board.first { $0.value == region }?.key }

    /// Feedback color for a word, shown only while it sits where it was last judged.
    func mark(for word: Int) -> Mark? {
        if state.finished && !state.won { return .green }
        guard let last = state.guesses.last, let region = state.placements[word], last[word] == region else { return nil }
        return marks(last)[word]
    }

    /// The best result this word has ever had in this region, for the selected-word memory aid.
    func history(word: Int, region: Int) -> Mark? {
        var best: Mark?
        for guess in state.guesses where guess[word] == region {
            let m = marks(guess)[word]
            if best == nil || m.rawValue < best!.rawValue { best = m }
        }
        return best
    }

    // MARK: Moves

    func tapWord(_ w: Int) {
        guard !state.finished else { return }
        if locked.contains(w) { Haptics.tap(.rigid); return }
        if let sel = selected, sel != w, let region = state.placements[w] {
            place(sel, in: region)
            return
        }
        selected = selected == w ? nil : w
        Haptics.select()
    }

    func tapRegion(_ region: Int) {
        guard !state.finished else { return }
        if let sel = selected {
            place(sel, in: region)
        } else if let occupant = word(in: region), !locked.contains(occupant) {
            selected = occupant
            Haptics.select()
        }
    }

    /// Tapping the word bank sends a selected, placed word back.
    func tapBank() {
        guard let sel = selected, state.placements[sel] != nil else { selected = nil; return }
        state.placements[sel] = nil
        selected = nil
        Haptics.tap(.light)
        save()
    }

    private func place(_ w: Int, in region: Int) {
        defer { selected = nil }
        if let occupant = word(in: region) {
            if occupant == w { return }
            if locked.contains(occupant) { Haptics.tap(.rigid); return }
            state.placements[occupant] = state.placements[w]
        }
        state.placements[w] = region
        Haptics.tap(.soft)
        save()
    }

    func clearBoard() {
        let keep = locked
        state.placements = state.placements.filter { keep.contains($0.key) }
        selected = nil
        save()
    }

    var canSubmit: Bool { !state.finished && state.placements.count == count }

    func submit() {
        guard canSubmit else { return }
        let guess = (0..<count).map { state.placements[$0]! }
        if state.guesses.contains(guess) {
            flash("Already tried that arrangement")
            Haptics.notify(.warning)
            return
        }
        selected = nil
        state.guesses.append(guess)
        let result = marks(guess)
        if result.allSatisfy({ $0 == .green }) {
            state.finished = true
            state.won = true
            Haptics.notify(.success)
        } else if state.guesses.count >= Self.maxGuesses {
            state.finished = true
            Haptics.notify(.error)
        } else {
            let greens = result.filter { $0 == .green }.count
            flash(greens == count - 1 ? "So close!" : "\(greens) of \(count) in the right spot")
            Haptics.notify(.warning)
        }
        save()
    }

    func reveal(_ category: Int) {
        state.hints.insert(category)
        Haptics.tap(.medium)
        save()
    }

    func isRevealed(_ category: Int) -> Bool { state.finished || state.hints.contains(category) }

    func restart() {
        Store.reset(puzzle)
        state = GameState()
        selected = nil
    }

    private func save() { Store.save(state, puzzle) }

    private func flash(_ message: String) {
        toast = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            if toast == message { toast = nil }
        }
    }

    var shareText: String {
        let score = state.won ? "\(state.guesses.count)/\(Self.maxGuesses)" : "X/\(Self.maxGuesses)"
        var lines = ["Overlap #\(puzzle.id)  \(score)"]
        if !state.hints.isEmpty { lines.append(String(repeating: "💡", count: state.hints.count)) }
        lines += state.guesses.map { marks($0).map(\.emoji).joined() }
        return lines.joined(separator: "\n")
    }
}

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func select() { UISelectionFeedbackGenerator().selectionChanged() }
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
