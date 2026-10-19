# Next puzzle countdown

## Choice

When you finish today's puzzle, the result card shows "🕒 Next puzzle in 5:12:03", counting down live to local midnight. At midnight it changes to "A new puzzle is ready".

## Why

The daily streak (the previous garden change) gives players a reason to come back tomorrow. The moment they finish today's puzzle is when to tell them when tomorrow's arrives. Right now the result card stops at Share / Copy. A countdown is the usual way daily puzzle games answer "when's the next one?". It's small, fits in one run, needs no network or new data, and the date maths can be tested on Linux.

Other candidates I considered:
- A guess-distribution chart. Useful, but the home screen already shows solved / missed / average, so it adds less.
- A "Next puzzle" button on the result card. The home screen already offers the next unfinished puzzle, and Back gets you there.
- New puzzles before the cycle repeats (February 3, 2027). These need Noah's editorial judgement, and adding them changes the puzzle order.

## Pieces

- `Puzzles.swift`: `Puzzles.start(ofDay:)`, the inverse of `day(of:)` (local midnight, Gregorian calendar, the same launch date), and `Puzzles.nextPuzzleDate(after:)`.
- `GameView.swift`: `ResultCard.nextPuzzle`, shown only when the puzzle on screen is `Puzzles.today`. It uses `Text(timerInterval:countsDown:)` inside a `TimelineView(.explicit([next]))` so the text changes at midnight without a per-second timer.
- `tests/main.swift`: round-trip checks for `start(ofDay:)`, and for the next-puzzle date at midnight, an hour before midnight, and across a clock change.
- No new files, so the committed `.xcodeproj` doesn't need `xcodegen generate`.
