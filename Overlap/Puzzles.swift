import Foundation

/// Region masks: A = 1, B = 2, C = 4. So A∩B = 3, A∩C = 5, B∩C = 6, all three = 7.
struct Puzzle: Identifiable, Hashable {
    let id: Int
    let categories: [String]
    let words: [String]
    let answers: [Int]

    init(_ id: Int, _ categories: [String], _ entries: [(String, Int)]) {
        self.id = id
        self.categories = categories
        self.words = entries.map(\.0)
        self.answers = entries.map(\.1)
    }

    static func == (l: Puzzle, r: Puzzle) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

enum Puzzles {
    static let all: [Puzzle] = [
        Puzzle(1, ["Has keys", "Has pedals", "Has strings"], [
            ("HARP", 6), ("FLORIDA", 1), ("PUPPET", 4), ("CAR", 3),
            ("PIANO", 7), ("BICYCLE", 2), ("HARPSICHORD", 5),
        ]),
        Puzzle(2, ["___BALL", "___STORM", "___FALL"], [
            ("RAIN", 6), ("BASKET", 1), ("NIGHT", 4), ("SNOW", 7),
            ("BRAIN", 2), ("FOOT", 5), ("FIRE", 3),
        ]),
        Puzzle(3, ["Trees", "Colors", "Six letters"], [
            ("BEIGE", 2), ("WILLOW", 5), ("PADDLE", 4), ("CHERRY", 7),
            ("BIRCH", 1), ("YELLOW", 6), ("OLIVE", 3),
        ]),
        Puzzle(4, ["___LINE", "___LOCK", "___BAND"], [
            ("PAD", 2), ("WAIST", 5), ("SKY", 1), ("HEAD", 7),
            ("BROAD", 4), ("ARM", 6), ("HEM", 3),
        ]),
        Puzzle(5, ["Has wings", "Has a tail", "Has scales"], [
            ("COMET", 2), ("BUTTERFLY", 5), ("MAP", 4), ("ANGEL", 1),
            ("CROCODILE", 6), ("DRAGON", 7), ("AIRPLANE", 3),
        ]),
        Puzzle(6, ["___LIGHT", "___TIME", "___BREAK"], [
            ("HEART", 4), ("CANDLE", 1), ("LUNCH", 6), ("NIGHT", 3),
            ("BED", 2), ("DAY", 7), ("FIRE", 5),
        ]),
        Puzzle(7, ["Minnesota team names", "Animals", "Five letters"], [
            ("MOOSE", 6), ("SAUNA", 4), ("TWINS", 5), ("WALLEYE", 2),
            ("LOONS", 7), ("VIKINGS", 1), ("LYNX", 3),
        ]),
        Puzzle(8, ["___BALL", "___MAN", "___WORK"], [
            ("IRON", 6), ("MEAT", 1), ("HOME", 4), ("NET", 5),
            ("MAIL", 2), ("FOOT", 7), ("SNOW", 3),
        ]),
    ]

    /// One puzzle per day, cycling, starting today.
    static var today: Puzzle {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2026, month: 9, day: 27))!
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: .now)).day ?? 0
        let n = all.count
        return all[((days % n) + n) % n]
    }
}
