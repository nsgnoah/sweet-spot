# Venn

A word puzzle for iPhone and iPad. Each puzzle hides three categories, drawn as three overlapping circles. Seven words each belong in exactly one of the diagram's seven spaces: inside one circle, where two overlap, or in the middle where all three meet. Place them all, submit, and use the feedback to work out where everything goes. Six tries.

No accounts, no ads, no network. Everything ships in the app.

## How it plays

- Two words start the game locked in their right spots. They're the same two for everyone and never the center word.
- Drag a word onto a spot, or tap a word and then tap a spot. Dropping onto an occupied spot swaps the two words; dropping off the board sends a word back to the bank.
- Submit once all seven are placed. Each word is marked:
  - **Right spot** (●, green): it locks in place.
  - **Close** (◐, yellow): it shares at least one circle with its right spot.
  - **Miss** (○, gray): no circles in common.
- Resubmitting an arrangement you've already tried is refused and doesn't cost a guess.
- Tap a mystery category to reveal it as a hint. Hints show as 💡 in the shared result.
- When you pick up a word, empty spots show how that word did there on earlier guesses.
- Solve it, or run out of guesses and the board fills in the answers. Either way you get every word's explanation.

## What it does

- **Home** — today's puzzle with Play / Continue / See result (once today's is done, a button for the next unfinished one), and a grid of all 129 puzzles showing solved (with score), missed, in progress, and today. Solved / missed / average-guesses totals above the grid.
- **Game** — the legend with the three circles (mystery until revealed), the board, the word bank, guesses left, Clear (keeps locked words), Submit, and a row of marks per guess. Start over is in the ⋯ menu.
- **Result** — a headline by guess count, Share and Copy, the guess history, and the answers list (center first, then pairs, then singles) with a one-line "why" for each word.
- **How to play** — shown on first launch and from the ? button, with a worked Red / Fruit / Round example.
- **Privacy & support** — the full privacy policy as text, the support email, links to the web pages, and the version and build.
- **iPad** — all orientations; in landscape the board sits beside the controls. Pointer hover on words and grid tiles. iPhone is portrait only.
- **Accessibility** — VoiceOver can play the whole game (spots and words are labelled buttons, bank words have "Place in …" actions, results are announced); close and miss carry a symbol as well as a color; Reduce Motion is respected; paired buttons stack at large text sizes.

The shared result is spoiler-free:

```
Venn #12  3/6
💡
◐○●◐○●●
●◐●●○●●
●●●●●●●
```

## Names

The project started as **Overlap** and was renamed **Sweet Spot** for build 2, then **Venn** in build 5. The Xcode project, targets, folders, bundle ID (`co.nsgsolutions.overlap`), and UserDefaults keys still say Overlap; the GitHub repo is `sweet-spot` and the support pages live under `nsgnoah.github.io/sweetspot/`. Everything a player sees says Venn.

## Layout

- `Overlap/` — the app. SwiftUI, no dependencies.
  - `Puzzles.swift` — loads `Puzzles.json`, picks the starting words, and chooses today's puzzle.
  - `Game.swift` — game state, marking, locking, moves, saving, share text.
  - `HomeView.swift` — app entry, home screen, puzzle grid, How to play.
  - `GameView.swift` — the game screen, result card, answers list.
  - `VennBoard.swift` — the diagram, slot positions, and point-to-region hit testing.
  - `WordDrag.swift` — drag and drop across the game screen.
  - `AboutView.swift` — privacy and support.
  - `Components.swift` — colors, word chips, the flow layout for the bank, the logo.
  - `Puzzles.json` — the bundled puzzles. Generated; don't edit by hand.
  - `PrivacyInfo.xcprivacy` — privacy manifest.
- `puzzles/` — puzzle source files and `validate.py`, which checks them and builds `Overlap/Puzzles.json`.
- `OverlapUITests/` — UI tests.
- `site/` — the support and privacy pages.
- `docs/APP-STORE.md` — submission status and the App Store Connect checklist.
- `project.yml` — [xcodegen](https://github.com/yonaskolb/XcodeGen) spec. The generated `Overlap.xcodeproj` is committed.

## Build

```bash
xcodegen generate
open Overlap.xcodeproj
```

Pick the `Overlap` scheme and run on any iPhone or iPad running iOS 17 or later. Automatic signing, team in `project.yml`. No capabilities or entitlements. Run `xcodegen generate` after changing `project.yml` or adding files.

Tests: `xcodebuild test -project Overlap.xcodeproj -scheme Overlap -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`. There are two UI tests in `OverlapUITests/LandscapeTests.swift`: one opens a puzzle in landscape and rotates mid-game, the other checks the two locked starting words and drags a word onto the center spot (in landscape on an iPad simulator, portrait on iPhone). Both start today's puzzle over on the simulator.

## Puzzles

Puzzles are written in `puzzles/*.json`, one JSON array per file, grouped by style:

| File | Style | Count |
|---|---|---|
| `core.json` | the first puzzles players see | 8 |
| `letters.json` | topics mixed with letter rules ("Six letters", "Has a double letter") | 25 |
| `prefix.json` | `UP___`, `HOME___` | 22 |
| `suffix.json` | `___BALL`, `___STORM` | 25 |
| `properties_has.json` | "Has legs", "Has a seat" | 12 |
| `properties_verbs.json` | "You can cast it", "You can drop it" | 12 |
| `trivia.json` | general knowledge ("Greek gods", "NASA programs"), usually with a letter rule | 25 |

Each puzzle:

```json
{
  "categories": ["Has keys", "Has pedals", "Has strings"],
  "answers": [
    {"word": "FLORIDA",     "region": "A",   "why": "The Florida Keys"},
    {"word": "BICYCLE",     "region": "B",   "why": "Pedals, but no keys or strings"},
    {"word": "PUPPET",      "region": "C",   "why": "A marionette hangs on strings"},
    {"word": "CAR",         "region": "AB",  "why": "Car keys, gas and brake pedals"},
    {"word": "HARPSICHORD", "region": "AC",  "why": "A keyboard that plucks strings, with no pedals"},
    {"word": "HARP",        "region": "BC",  "why": "A concert harp has strings and seven pedals"},
    {"word": "PIANO",       "region": "ABC", "why": "Keys, pedals, and strings"}
  ],
  "obscure": ["..."]
}
```

`A`, `B`, `C` are the three categories in order; every region from `A` to `ABC` is used exactly once. `obscure` is optional (see below) and isn't shipped.

### Validating and building

```bash
python3 puzzles/validate.py puzzles/suffix.json   # check one or more files
python3 puzzles/validate.py                       # check everything
python3 puzzles/validate.py --build               # check everything, write Overlap/Puzzles.json
```

`validate.py` checks:

- **Structure** — 3 categories, 7 answers, each region once, uppercase words of at most 12 characters, a `why` for every word, no duplicate words.
- **Letter rules** — categories like "Five letters", "Has a double letter", "No repeated letters", "Starts with a vowel", "Starts with B", "Ends with …", "Contains a …" are checked exactly against every word, inside and outside the circle.
- **Compound rules** — for `___X` and `X___` categories, a word outside the circle must not form a dictionary word with it (`/usr/share/dict/web2` and `web2a`). If it does but nobody would think of it, list the compound in `obscure`. A word inside the circle that doesn't form a dictionary word is only a warning, since many are common phrases.
- **Across puzzles** — no two puzzles share the same three categories; words used in three or more puzzles are listed as a warning.

`--build` refuses to write if there are errors. It puts `core.json` first, then takes one puzzle from each other file in turn so styles alternate day to day. Files with `draft` in the name are skipped.

### Loading

`Puzzles.swift` reads `Puzzles.json` at launch. For each puzzle:

- Its **key** is the three categories joined with `|`. Saved progress is stored under this key, so a puzzle's categories must not change after release, or players lose its progress. Reordering puzzles is safe.
- Words are written in region order, so they're **shuffled** with a generator seeded from the key: the same order for everyone, every launch.
- Two **starting words** are chosen the same way, from anything but the center.
- Regions become bitmasks (A = 1, B = 2, C = 4, so the center is 7). A word is close when its guessed mask and its answer share a bit.

If the file fails to load, a single built-in placeholder puzzle is used instead of crashing.

## The daily puzzle

`Puzzles.today` counts days since September 27, 2026 on the Gregorian calendar in the local time zone, and cycles through the list, so everyone gets the same puzzle whatever calendar their region uses. The home screen picks up a new day when the app returns to the foreground or the day changes. With 129 puzzles, puzzle #1 comes back on February 3, 2027.

Every puzzle is playable at any time from the grid; nothing is locked.

## Saving

Each puzzle's state (placements, guesses, revealed hints, finished, won) is JSON in `UserDefaults` under `overlap.puzzle.<key>`, saved after every move. The home screen's stats and tiles are read from those. Start over deletes that puzzle's entry. Nothing leaves the device.

## Store and privacy

Version 1.0, build 5. Build 5, the first named Venn, was uploaded to App Store Connect on October 2, 2026. The app record (bundle ID `co.nsgsolutions.overlap`) is still named "Sweet Spot: Word Venn" and is due to be renamed "Venn: Word Puzzle". `docs/APP-STORE.md` has the full checklist, upload commands, screenshot locations, and draft description and review notes.

Category Games > Word, aiming for a 4+ age rating, export compliance declared (no non-exempt encryption).

Privacy: no tracking, no collected data. The privacy manifest declares UserDefaults use (reason `CA92.1`). The policy is in the app under Privacy & support and on the web at `https://nsgnoah.github.io/sweetspot/privacy.html`; support is `https://nsgnoah.github.io/sweetspot/`. Those pages are published from `site/` via a separate `nsgnoah/sweetspot` repo; keep `site/privacy.html` and the text in `AboutView.swift` saying the same thing.
