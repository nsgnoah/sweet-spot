import Foundation

/// Region masks: A = 1, B = 2, C = 4. So A∩B = 3, A∩C = 5, B∩C = 6, all three = 7.
struct Puzzle: Identifiable, Hashable {
    let id: Int              // 1-based puzzle number
    let key: String          // stable storage key, independent of puzzle order
    let categories: [String]
    let words: [String]
    let answers: [Int]
    let whys: [String]
    let givens: [Int]        // words that start the game already in their right spot

    static func == (l: Puzzle, r: Puzzle) -> Bool { l.key == r.key }

    /// Shown only if the bundled puzzles fail to load, so the app never crashes on launch.
    static let placeholder = Puzzle(
        id: 1, key: "placeholder", categories: ["Red", "Fruit", "Round"],
        words: ["FIRE TRUCK", "BANANA", "BASEBALL", "STRAWBERRY", "CLOWN NOSE", "ORANGE", "APPLE"],
        answers: [1, 2, 4, 3, 5, 6, 7],
        whys: ["Red only", "Fruit only", "Round only", "Red and a fruit", "Red and round", "A round fruit", "Red, a fruit, and round"],
        givens: [1, 4]
    )
    func hash(into h: inout Hasher) { h.combine(key) }
}

enum Puzzles {
    private struct Raw: Decodable {
        struct Answer: Decodable { let word: String; let region: String; let why: String }
        let categories: [String]
        let answers: [Answer]
    }

    static let all: [Puzzle] = {
        guard let url = Bundle.main.url(forResource: "Puzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([Raw].self, from: data) else {
            assertionFailure("Puzzles.json is missing or corrupt")
            return []
        }
        return raw.enumerated().map { index, r in
            let key = r.categories.joined(separator: "|")
            // Authored in region order, so shuffle (the same way every time) to hide the answer.
            var rng = SeededRandom(seed: fnv1a(key))
            let order = r.answers.indices.shuffled(using: &rng)
            let answers = order.map { r.answers[$0] }
            let masks = answers.map { a in a.region.reduce(0) { $0 | (["A": 1, "B": 2, "C": 4][String($1)] ?? 0) } }
            // Two words start in place to get you going: the same two for everyone, and never the
            // center word, so the sweet spot is still yours to find.
            var givenRNG = SeededRandom(seed: fnv1a(key + "#givens"))
            let givens = masks.indices.filter { masks[$0] != 7 }.shuffled(using: &givenRNG).prefix(2)
            return Puzzle(
                id: index + 1,
                key: key,
                categories: r.categories,
                words: answers.map(\.word),
                answers: masks,
                whys: answers.map(\.why),
                givens: givens.sorted()
            )
        }
    }()

    /// One puzzle per day, cycling, starting on launch day.
    /// Always counted on the Gregorian calendar (in the local time zone), so everyone gets the same puzzle.
    static var today: Puzzle {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(from: DateComponents(year: 2026, month: 9, day: 27))!
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: .now)).day ?? 0
        let n = max(all.count, 1)
        return all.isEmpty ? .placeholder : all[((days % n) + n) % n]
    }

    private static func fnv1a(_ s: String) -> UInt64 {
        s.utf8.reduce(14695981039346656037) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }
}

struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {   // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
