# Daily streak

## Choice

Show a daily streak on the home screen: "🔥 Streak N · Best M" under today's button.

## Why

Venn is built around a featured puzzle every day ("a featured puzzle every day" in the App Store description, the today card, midnight refresh). The home screen already shows solved / missed / average totals, but nothing rewards coming back each day. A streak is the usual habit loop for daily word games. It fits in one run, it's visible, and it needs no network, accounts, or new data collection, so the privacy policy and manifest don't change.

Other candidates I considered:
- Adding puzzles before the cycle repeats on February 3, 2027 (in `docs/APP-STORE.md`). Good puzzles need Noah's editorial judgement. Adding them also reorders the round-robin build, which changes puzzle numbers and today's puzzle.
- Streak logic in a new file. That would need `xcodegen generate` to update the committed `.xcodeproj`, and xcodegen doesn't run on Linux, so the logic goes in the existing `Puzzles.swift`.

## Rules

- A day counts when that day's featured puzzle (`Puzzles.puzzle(forDay:)`) was **won on that day** (`GameState.finishedOn == day`).
- A miss or a skipped day ends the streak. An unplayed today doesn't end it yet.
- Catching up on older puzzles from the grid doesn't count.
- The best streak is also kept in `UserDefaults` (`overlap.bestStreak`), so it survives Start over and the 129-day cycle reusing a puzzle's save.
- Saves from before this change have no `finishedOn`, so earlier wins don't count.

## Pieces

- `Puzzles.swift`: `Puzzles.day(of:)` and `Puzzles.puzzle(forDay:)`, split out of `today`; the pure `Streak.current` / `Streak.longest`.
- `Game.swift`: `GameState.finishedOn` (optional, so old saves still decode), set on finish; `Store.currentStreak()`, `bestStreak()`, `recordStreak()`.
- `HomeView.swift`: `streakLine` in the today card, hidden until the first daily solve, with a VoiceOver label.
- `tests/main.swift`: command-line checks for `Streak` and day counting, compiled with `swiftc` against `Puzzles.swift`.
