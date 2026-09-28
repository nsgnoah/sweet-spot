# Submitting Sweet Spot to the App Store

Status as of September 28, 2026. An audit against Apple's current requirements (App Review Guidelines of June 8, 2026, App Store Connect help, iOS 27 SDK notes) found 25 gaps. Every one that can be fixed in code is fixed in build 4. What remains is App Store Connect setup.

## What build 4 satisfies

| Requirement | Where |
|---|---|
| Privacy manifest: no tracking, no collected data, UserDefaults reason CA92.1 (App Store Connect rejects builds that use UserDefaults without it) | `Overlap/PrivacyInfo.xcprivacy` |
| Privacy policy reachable inside the app (5.1.1(i)) and a way to contact the developer (1.5) | `Overlap/AboutView.swift`, the (i) button on the home screen |
| New build number: builds 2 and 3 are already uploaded without the fixes | `project.yml` `CURRENT_PROJECT_VERSION: "4"` |
| No alcohol references, so the age rating can be 4+ | `puzzles/*.json`, rebuilt into `Overlap/Puzzles.json` |
| Drag and drop works in iPad landscape (it always failed when a puzzle was opened in landscape) | `WordDrag.swift`, `VennBoard.swift`, `GameView.swift`; `OverlapUITests/LandscapeTests.swift` covers it |
| A drag cut short by an interruption no longer leaves a dimmed word and a page that won't scroll | `WordDrag.swift` |
| Same daily puzzle for everyone, whatever calendar their region uses | `Puzzles.swift` |
| Home picks up the new day's puzzle when the app returns after midnight | `HomeView.swift` |
| No crash if the puzzle file ever fails to load | `Puzzles.swift` |
| How to play no longer says puzzles "unlock" (all 129 are playable from the start) | `HomeView.swift` |
| VoiceOver can play: board spots and words are labelled buttons, bank words have "Place in ..." actions, results are announced | `VennBoard.swift`, `GameView.swift`, `Game.swift` |
| Close and miss are shown by a symbol as well as color; better contrast; Reduce Motion respected; paired buttons stack at the largest text sizes | `Components.swift`, `GameView.swift`, `HomeView.swift` |
| Export compliance, arm64, launch screen, 1024 opaque icon, iPhone portrait / iPad all orientations | `project.yml`, asset catalog (unchanged, already correct) |

## Upload build 4

Build 4 is committed but not yet uploaded. Archiving after a restart stops at a macOS keychain prompt ("codesign wants to access key..."). Enter your login password and choose **Always Allow**. Then either use Xcode (Product > Archive, then Distribute App > App Store Connect > Upload), or run:

```bash
xcodebuild archive -project Overlap.xcodeproj -scheme Overlap -configuration Release -destination 'generic/platform=iOS' -archivePath build/Overlap-4.xcarchive -allowProvisioningUpdates
```

```bash
xcodebuild -exportArchive -archivePath build/Overlap-4.xcarchive -exportOptionsPlist build/ExportOptions.plist -exportPath build/export -allowProvisioningUpdates
```

`build/ExportOptions.plist` (not in git) uploads straight to App Store Connect, and has `manageAppVersionAndBuildNumber` set to false, so the uploaded build is 4, matching the source. After processing, check email for any ITMS warning. There shouldn't be one now that the privacy manifest is in.

## Privacy and support pages

These pages are live. The app links to both, and App Store Connect needs both URLs. The source is `site/` in this repo; it's published by GitHub Pages from the public `nsgnoah/sweetspot` repo, the same setup as Ola.

| App Store Connect field | URL |
|---|---|
| Privacy Policy URL | `https://nsgnoah.github.io/sweetspot/privacy.html` |
| Support URL | `https://nsgnoah.github.io/sweetspot/` |

To change either page, edit it in `site/`, copy both files into a clone of `nsgnoah/sweetspot`, and push. Keep `site/privacy.html` and the text in `AboutView.swift` saying the same thing.

## App Store Connect checklist

The app record already exists: **Sweet Spot: Word Venn**, Apple ID 6816802521, bundle ID `co.nsgsolutions.overlap`. The bare name "Sweet Spot" belongs to another app (Weetech, Food & Drink), so keep the longer store name. The home-screen name stays "Sweet Spot".

| Item | Value |
|---|---|
| Build | Attach **build 4** to version 1.0, not 2 or 3 |
| Subtitle | `Seven words, three circles` (26 of 30) |
| Category | Games > Word; secondary Games > Puzzle |
| Privacy Policy URL / Support URL | see above |
| App Privacy | "No, we do not collect data from this app", then **Publish** |
| Age rating | Answer **None** to every content question and **No** to every capability (web access, user-generated content, messaging, social media, ads, parental controls, age assurance). Result: 4+. See the note below |
| Copyright | `2026 Noah Greensweig` (the seller name on an Individual account), or `2026 NSG LLC` if the LLC owns the app |
| Content rights | Does not contain third-party content |
| Price / availability | Free. Consider leaving out China mainland and Vietnam, which require a game licence |
| Mac and Apple Vision Pro | Uncheck both under Pricing and Availability for 1.0, or test "Designed for iPad" on a Mac first. The build settings don't control this |
| EU trader status | Ola was declared non-trader; use the same unless that has changed |
| Screenshots | `build/shots-store/iphone` (1284x2778, the 6.5" slot) and `build/shots-store/ipad` (2752x2064 landscape, the 13" slot), taken from build 4 in light mode with a clean status bar. Not in git. Suggested order: 02-feedback, 01-placing, 03-solved, 06-howto, 05-home |

**Age rating note.** The puzzles still include ordinary compound words and idioms such as swordfish, gunboat, slingshot, arrowhead, and "cross swords", plus a "Playful insults" category (nerd, dweeb, airhead, knucklehead). The audit's verifiers judged these don't count as weapons content or crude humor, the same as in other word games rated 4+. If you'd rather be strict, answering "Infrequent" to Guns or Other Weapons gives 9+ (A16 in Brazil).

**Accessibility Nutrition Labels** (optional, per device). Claim **Dark Interface**, **Reduced Motion**, and **Differentiate Without Color Alone** now. Before claiming **VoiceOver** or **Voice Control**, play one full puzzle on a real iPhone with each turned on. Don't claim **Larger Text** (the board is fixed-size) or **Sufficient Contrast** (the circle badges and green chips meet 3:1 for bold text, not 4.5:1).

### Description (draft)

> Seven words. Three mystery circles. Figure out where each one belongs.
>
> Every Sweet Spot puzzle hides three categories, drawn as overlapping circles. Each word fits exactly one of the seven spaces: inside one circle, where two overlap, or right in the sweet spot where all three meet.
>
> Drag the words onto the diagram and submit. Words in the right spot lock in place. Close ones share a circle with the right answer. Misses share none. You get six tries.
>
> • 129 puzzles, with a featured puzzle every day
> • Play any puzzle from the grid, at your own pace
> • Stuck? Reveal a category as a hint
> • Every answer explained when you finish
> • Share your result without spoilers
> • No ads, no accounts, no tracking. Works offline.

**Keywords** (93 of 100 bytes): `word game,puzzle,venn,diagram,categories,daily,brain teaser,logic,trivia,circles,sort,offline`

Don't mention Wordle, NYT, or Connections anywhere in the metadata (2.3.7, 4.1).

### App Review notes (draft)

> Sweet Spot is a free word puzzle that works fully offline. There is no account or sign-in, no network access, no ads, and no in-app purchase.
>
> To play: tap Play on the home screen, drag each word onto a spot in the diagram (or tap a word, then tap a spot), and tap Submit. Tapping a "Mystery category" reveals it as a hint. All 129 puzzles can be opened from the grid on the home screen. The privacy policy and support contact are under the (i) button on the home screen.

## Before the next update

- The daily puzzle cycles through all 129 puzzles; puzzle #1 comes back as "today" on February 3, 2027. Add puzzles before then, or accept the repeat.
- Don't change the categories of a puzzle after release: they are its save key, so players would lose that puzzle's progress.
- Bump `CURRENT_PROJECT_VERSION` for every upload, then run `xcodegen generate`.
