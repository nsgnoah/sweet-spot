// Checks for the Foundation-only logic in Overlap/Puzzles.swift. Runs anywhere Swift does,
// no simulator needed:
//
//   swiftc -o /tmp/venn-tests Overlap/Puzzles.swift tests/main.swift && /tmp/venn-tests

import Foundation

var failures = 0

func expect(_ actual: Int, _ expected: Int, _ name: String) {
    if actual == expected {
        print("ok    \(name)")
    } else {
        print("FAIL  \(name): got \(actual), expected \(expected)")
        failures += 1
    }
}

func days(_ solved: Set<Int>) -> (Int) -> Bool { { solved.contains($0) } }

// Current streak
expect(Streak.current(today: 5, solvedOn: days([])), 0, "nothing solved")
expect(Streak.current(today: 5, solvedOn: days([3, 4, 5])), 3, "solved today and the two days before")
expect(Streak.current(today: 5, solvedOn: days([3, 4])), 2, "today not played yet keeps yesterday's streak")
expect(Streak.current(today: 5, solvedOn: days([2, 3])), 0, "a skipped day ends the streak")
expect(Streak.current(today: 5, solvedOn: days([1, 2, 4, 5])), 2, "a gap splits runs")
expect(Streak.current(today: 2, solvedOn: days([0, 1, 2])), 3, "counts back to launch day")
expect(Streak.current(today: 0, solvedOn: days([])), 0, "launch day, unplayed")
expect(Streak.current(today: -3, solvedOn: { _ in true }), 0, "before launch day")

// Longest streak
expect(Streak.longest(through: 9, solvedOn: days([])), 0, "longest: nothing solved")
expect(Streak.longest(through: 9, solvedOn: days([0, 1, 2, 5, 6, 9])), 3, "longest: earliest run wins")
expect(Streak.longest(through: 9, solvedOn: days([1, 4, 5, 6, 7, 8, 9])), 6, "longest: run ending today")
expect(Streak.longest(through: 3, solvedOn: days([2, 3, 4, 5])), 2, "longest: ignores days after today")

// Days and the daily puzzle
let cal = Calendar(identifier: .gregorian)
func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}
expect(Puzzles.day(of: date(2026, 9, 27)), 0, "launch day is day 0")
expect(Puzzles.day(of: date(2026, 9, 27, hour: 23)), 0, "late on launch day is still day 0")
expect(Puzzles.day(of: date(2026, 9, 28, hour: 0)), 1, "just after midnight is the next day")
expect(Puzzles.day(of: date(2027, 2, 3)), 129, "puzzle #1 comes back on February 3, 2027")

if failures > 0 {
    print("\n\(failures) failed")
    exit(1)
}
print("\nAll passed")
