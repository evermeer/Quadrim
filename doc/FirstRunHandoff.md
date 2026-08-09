# Handoff Spec: Quadrim First-Run Experience

Reconciled handoff for the first-run flow. Supersedes [DesignHandoff.md](DesignHandoff.md) where the two disagree.

Sources: the design in [design.md](design.md) and `design_reference/`, the Nocturne system in `design_system/`, and the product truth in [Idea-final.md](Idea-final.md), [Idea-final-spec.md](Idea-final-spec.md) and [tickets/](tickets/). Decisions in [idea-decisions.md](idea-decisions.md) Step 11 (D122–D128).

Date: 2026-08-07
Status: reviewed against spec. Ready to implement, with three blockers named in §9.

---

## 1. Overview

The path a new player takes from first launch to a finished game: a guided tutorial, a home screen carrying their record and rating, an opponent picker across twenty computer opponents, a match, and a result.

Everything here is offline and free. No account, no network call, no subscription — release 0.1 has none of those. The player's opponent is always a computer opponent at this stage; human play arrives at 0.3b.

**Read [design.md](design.md) for the visual construction** — board geometry, pebble rendering, token usage. This document covers what changes, what was missing, and what a developer needs that the design does not state.

### 1.1 Corrections to the delivered design

Four things in the delivered design contradict the specification. Implement the right-hand column.

| Delivered design | Implement instead | Why |
|---|---|---|
| Opponents named Pip, Dott, Cubby … Meridian, rated 620–2400 | The roster in [Idea-final.md](Idea-final.md) §6.4 — Pebble … Quadrim Prime, 600–2400 | The roster drives eight tickets and the calibration about to measure it (D122) |
| Three categories: Easy / Medium / Hard | Five tiers: Novice, Casual, Club, Expert, Master | Twenty in three groups is ~7 per accordion; five averages four and reads as a ladder (D123) |
| Rating tag reads "Unrated" | A live computer rating, seeded 1200 | "Unrated practice" is the pre-D92 model, superseded when ratings split (D128) |
| "Step N / 5" with six progress segments | Step count and segment count must match | The design contradicts itself; the tutorial has four parts (tickets 018–020) plus a welcome |

**The prototype runs. Use `First-Run Experience (standalone).html`** — 1.3 MB, zero external references, opens in any browser. That is the reference of record.

The `.dc.html` variant also works now: it was missing only `support.js` (69 KB), the runtime that evaluates its inline `type="text/x-dc"` block. That file and the `_ds/nocturne-6bb5054c-.../` assets are restored at the paths it expects. The 300-byte `_ds_bundle.js` is **correct, not a stub** — this design uses raw Nocturne tokens and inline logic rather than registered components, so its bundle is genuinely empty.

**Every contradiction in the table above was confirmed in the running prototype**, not just read from source. Still read strings from the source rather than retyping them — but check every opponent name against §6.4, because the source carries the wrong roster (D122).

---

## 2. Layout

Phone canvas 390×844. Content padding `28px 22px 22px`. Portrait locked — 0.1 ships phones only; the large-screen landscape layout (ticket 017) is a separate design pass.

**Left-text / right-board convention** when a board is present: left column for title, copy, status and controls; right column for the board; `display:flex; gap:14px; align-items:flex-start`. Screens without a board (main, picker, result) use full width in a column.

Primary action pinned to the bottom as a full-width button. Secondary actions sit above it, or top-left as a ghost icon button.

**The fixed 128px left column is a defect.** At the largest system font scale it cannot hold the tutorial's body copy, and acceptance criterion U8 requires the app to work there. Make it flexible with a minimum, and let the board take the remainder.

---

## 3. Design tokens

Source of truth is `design_system/styles.css`. Port these into a platform theme; never hardcode the values.

| Token | Value | Usage |
|---|---|---|
| `--color-bg` | `#161826` | Screen ground |
| `--color-surface` | `#232532` | Cards, raised surfaces |
| `--color-text` | `#e9e9ed` | Body and headings |
| `--color-accent` | `#9184d9` | Lines, tags, focus rings, selected states — **never a fill** |
| `--color-neutral-600` | `#75798c` | Board tile fill |
| `--color-neutral-500` | `#9397ab` | Board tile border |
| `--color-neutral-700` | — | Unfilled progress segment |
| `--radius-sm` / `md` / `lg` | 4 / 8 / 14 px | Board cells use `sm` |
| `--font-body` | Inter | Headings and body; weight never above 500 |
| `--shadow-sm` / `md` / `lg` | tuned for dark ground | Do not add shadows beyond the piece bevels |

Buttons are outlined, never filled. Use `.btn`, `.card`, `.tag`, `.seg` rather than bespoke equivalents.

**Light theme is not designed.** Nocturne is dark-only and §7.10 requires both. Either extend the ramp or record the gap against ticket 021 — do not ship a light theme improvised at implementation time.

---

## 4. The board

Full construction in [design.md](design.md) §The board. Four layers, absolutely positioned, `perspective(700px) rotateX(42deg) rotateZ(-3deg)`, `transform-origin: top left`, each offset `left: i*8px; top: i*130px`, `z-index: i+1`.

Pieces are circular pebbles at 58% of cell width with a radial gradient for relief — light for the player, near-black for the opponent.

### 4.1 Touch targets — resolve before building

**The specified geometry fails the minimum.** 170px across four columns is ~41px per cell before transformation; a 42° rotation compresses the vertical axis to roughly 70%, landing near **29px effective height**. That is below the platform minimum, on the smallest supported phone, for the most-used control in the game.

Treat the board's dimensions as **derived from the touch target**, not fixed (D127). Three levers, in preference order:

1. **Widen the board.** The left column is over-specified at 128px; taking width back is the cheapest fix.
2. **Soften the perspective angle.** Less rotation means less vertical compression, at some cost to the depth illusion.
3. **Let cells be non-square.** Compensate the vertical squash so the *rendered* target is square-ish rather than the pre-transform cell.

Verify by measuring the rendered hit area on the smallest supported device, not the CSS box. Acceptance criterion U4 and ticket 021 both require this.

### 4.2 Pieces and colour vision

Light against near-black is a lightness distinction, not a hue one, and it satisfies the accessibility requirement — better than shape would, because it survives full achromatopsia (D124). Keep the pebbles.

Still verify under simulation (ticket 021): the bevel gradients must not wash out the distinction at small sizes or high brightness.

---

## 5. Screens

### 5.1 Tutorial

Five steps: a welcome, then the four parts tickets 018–020 require — rules and the 76 winning lines, controls and reading the four layers, basic strategy, and an interactive practice game.

| Element | Spec |
|---|---|
| Header | Step label left, "Skip tutorial" (accent link) right |
| Progress | Thin segments, 4px tall, 2px radius. **Segment count must equal step count** |
| Step 1 | No board. 24px heading plus body |
| Steps 2–4 | 18px title, 12.5px body, board right with cells highlighted per step |
| Step 5 | Board pre-seeded; "Show hint" ghost button reveals a hint card |
| Footer | Back (ghost, hidden on step 1) + Next / "Start playing" (primary, `flex:1`) |

Highlighted cell: `rgba(145,132,217,0.20)` fill, `1px solid var(--color-accent)`, `box-shadow 0 0 0 3px rgba(145,132,217,0.14)`.

**Hints are computed, not scripted** (ticket 020). They come from the engine's real threat detection against the actual position, and name a concrete reason — an available win, a threat to block, or a strong developing move. A player who ignores a hint keeps playing; the hint is never a gate.

**The practice game is never stored** (§9.5). It lives in memory for the tutorial's duration. It must not reach the repository, appear in history, or move the rating.

Completion persists to the settings document (ticket 018) so the tutorial is not re-offered. Exitable at any step; restartable from the main screen.

### 5.2 Main screen

| Element | Spec |
|---|---|
| Title | "Quadrim", 24px heading |
| Stats card | Wins / Losses / Draws as three blocks (17px value, 10px label) |
| Rating | A **live computer rating**, seeded 1200 — a value, not "Unrated" |
| Active games | Uppercase 11px section label; clickable card per game with opponent name and a "Resume" accent tag; else "No active games" |
| Previous games | Same label style; rows of opponent name left, result right as `.card-meta`; else "No games yet" |
| Footer | "New game" (primary) and "Tutorial" (secondary), both full width |

**The rating needs a label, not just a number.** It must read as *your rating against the computer, on this device* — the human rating arriving at 0.3b is a separate number and the two must never be mistaken for each other (§12.2).

**"New game" is always available.** The design hides it when a game is active; the spec caps human games at 20 and leaves computer games uncapped, so hiding it is wrong.

Statistics are derived by folding stored games at read time (§9.5) — never stored separately, and the same in-memory list serves the totals, the per-opponent breakdown and the rating (ticket 005).

### 5.3 Opponent picker

Header: back arrow ghost button, "Choose your opponent" title, subtitle below.

**Five tier accordions** — Novice, Casual, Club, Expert, Master (D123). Each is a `.card`:

- Header row: tier name and description left; rating-range tag and chevron right. Header border turns accent when open.
- Body: opponent rows, rating right at 11px muted. Selected row gets accent tint, accent border, accent name.
- Row click must not toggle the accordion.
- Expand/collapse animates `max-height`, 0.32s ease.

Footer: "Start match" (primary), appending "· <opponent name>" once chosen.

Additional requirements from ticket 011:

- The player's **own computer rating is visible on this screen**, so the choice can be made against it.
- Opponents far above or below the player are visually distinguishable from a fair match.
- **Quadrim Prime is described as unbeatable when it moves first, not as perfect** — it ships with the strategy book, which proves a first-player win and nothing more (D181).
- Tier and rating render independently, so an opponent whose number is not yet trustworthy can show its tier alone.
- The list is driven by the catalogue: a rating change is data, not a code change.

### 5.4 Match

| Element | Spec |
|---|---|
| Left column | Opponent name as `.tag.tag-outline`; turn indicator below at 18px heading weight |
| Right column | Live board, cells clickable when empty and it is the player's turn |
| Footer | "Exit" (ghost, full width), "Resign" (muted text link) below |

Exit preserves the game as Active and returns to the main screen. Resign ends it and files it under Previous games.

**There are no draw offers** anywhere in the product — removed entirely. A game ends by four in a row, a full board, or resignation.

One tap places a piece. No confirmation step.

**Replace the placeholder opponent.** The prototype plays a random empty cell after ~550ms. The real engine runs on-device with a per-opponent time budget, and the interface must stay responsive while an opponent thinks (tickets 010, 025, 026).

### 5.5 Result — added, not in the delivered design

A match with no end state is not a finishable first run (D125). Required by ticket 007 and §7.8:

- **The winning line highlighted on the board** — all four cells. Win detection returns *which* line completed, so no recomputation is needed.
- The outcome stated plainly: who won, or that it was drawn.
- **The change to the computer rating**, labelled so it is not mistaken for a universal one.
- **Rematch**, one tap, with the starting player swapped — the previous non-starter goes first.
- Resignation is confirmed before it takes effect, so it cannot be triggered by a mis-tap.

A pass-and-play result must make clear that no rating changed.

---

## 6. States

| Element | State | Behaviour |
|---|---|---|
| Board cell | Empty, player's turn | Pointer cursor; tap places |
| Board cell | Occupied | Inert; taps do nothing |
| Board cell | Any, opponent's turn | Inert; turn indicator reads "Opponent's turn" |
| Board cell | On the winning line | Highlighted at result |
| Opponent row | Selected | Accent tint, accent border, accent name |
| Accordion | Open | Header border accent; body expanded |
| Primary button | Disabled | Reduced opacity; no pointer cursor |
| Any focusable | Focused | Visible focus ring — never `outline: none` without a replacement |
| Active games | Empty | "No active games", muted |
| Previous games | Empty | "No games yet", muted |
| Opponent thinking | — | Board stays responsive; the wait is visible, not a freeze |

---

## 7. Content and i18n

English and Dutch both complete, from the first commit. No user-facing string is ever hardcoded; every string lives in resource files (§9.9).

**Do not translate opponent names.** Tier labels and personality descriptions are translated; the twenty names are not (§6.4).

**Read strings from the design source, but verify them.** The prototype carries the wrong roster, so any name lifted from it is wrong (D122). Copy has been written in both languages and is worth reusing — the names are not.

The prototype's EN/NL segmented control is a demo affordance. Production reads the platform locale, overridable from the settings screen (ticket 028).

Truncation: opponent names are short and controlled, but Dutch strings run longer than English. Verify the tier headers and button labels at Dutch length before calling a layout done.

---

## 8. Accessibility

Non-negotiable, and audited as a whole flow in ticket 021.

- **Every cell exposes a label** naming layer, row, column and contents — for example "layer 2, row 3, column 1, empty".
- **Turn changes, the result, and the winning line are announced.**
- The rating is announced as a labelled value, not a bare number.
- Focus order follows reading order on every screen; no unreachable or unlabelled control.
- Touch targets meet the platform minimum — see §4.1, which is currently unmet.
- Every screen works at the largest system font scale — see §2, which is currently unmet.
- Contrast meets guidelines against the dark ground; re-verify if a light theme is added.
- Pieces stay distinguishable under colour-vision simulation (§4.2).

A complete game must be playable start to finish using a screen reader alone, on a real device.

---

## 9. Blockers and deferrals

### Resolve before implementing

1. **Touch targets** (§4.1) — the specified board geometry fails the minimum. Structural, not a tweak.
2. **Flexible left column** (§2) — 128px fixed breaks at large font scale.
3. **Result screen** (§5.5) — needs designing; it is specified here but not drawn.

### Found only by running it

These were invisible in source review and are cheap to fix now.

- **Half the screen is empty on two of four screens.** The tutorial's welcome step is a title and two lines above ~500px of nothing; the picker is three collapsed cards above ~400px of nothing, both over a bottom-pinned button. Neither is broken, but the welcome step is the highest-curiosity moment in the app and currently spends it on blank space — it is also the one tutorial step with no board, in a tutorial whose whole job is teaching the player to read the board.
- **The tutorial hint is scripted static text** — "Try the center — it opens the most lines" appears regardless of position. Ticket 020 requires hints derived from real threat detection, naming a concrete reason. This is the single largest gap between prototype and specified behaviour.
- **"Start match" is enabled with no opponent selected.** Disable it, or select a sensible default.
- **Tier rating ranges must be derived from the roster, not written by hand.** The prototype shows ~600–900, ~1100–1600, ~1800–2400, leaving 900–1100 and 1600–1800 uncovered — and the roster has opponents at 1000, 1650 and 1700.
- **"Pick a difficulty to see its bots"** — "bots" is developer vocabulary. The product says opponents.
- **"Welcome to Quadrim"** is generic hero copy that repeats the app title. The line beneath it — four in a row, stacked in a cube — is the actual hook and is doing that work in smaller type.

### Keep from the design, against the spec's own vocabulary

The three categories carried descriptions — *makes mistakes on purpose*, *plays solid lines, punishes blunders*, *sees deep into the cube*. Those are better than the tier names they are being replaced by: "Novice" is internal vocabulary, "makes mistakes on purpose" tells a player what will actually happen. **Each of the five tiers gets a one-line description in that voice** (D129). Ten strings, two languages, owned by ticket 029.

### Designed elsewhere, deliberately absent from this flow

Named so nobody assumes they were forgotten:

| Missing | Ticket |
|---|---|
| Move-history scrubber, live and for completed games | 012 |
| Settings screen — language, theme, restart tutorial | 028 |
| Pass-and-play entry from "New game" | spec §4 |
| Per-opponent statistics breakdown | 013 |
| Per-opponent milestones | 023 |
| Large-screen landscape layout | 017 |
| Light theme | §7.10 |

### Not in the product at all

Draw offers were removed entirely. If any design artefact still shows one, it is stale.

---

## 10. Implementation notes

- The design is a **reference, not source**. Rebuild these screens in Flutter using the project's own patterns; port tokens into a theme file rather than copying CSS.
- `design_reference/android-frame.jsx` is a preview bezel. Ignore it.
- Bot moves, statistics, rating and history are mocked in the prototype. All four come from real local state in the app — none of them touch a network, ever, in any release (§9.3).
- The board component serves both layouts when ticket 017 lands, differing in size and surrounding chrome rather than structure. Build it so that stays true.
