# Quadrim First-Run Experience — Design Spec

Design system: **Nocturne** (dark, near-neutral blue-grey ground, Inter, 8px radii, single blurple accent used sparingly as line/glow, never a flood). Full tokens in `design_system/styles.css`; guide in `design_system/readme.md`. Reference prototype: `design_reference/First-Run Experience.dc.html` (open directly in a browser).

## Flow

`Tutorial (5 steps) → Main screen → New game → Opponent picker → Match screen`

Exit from Match returns to Main with the game preserved as "Active"; Resign ends it and files it under "Previous games". Main → Tutorial is also reachable any time via a secondary button.

## Global layout pattern

Every screen (tutorial + main + opponent + match) uses the same **left-text / right-board** convention when a board is present, established in the tutorial and carried through to the match screen for consistency:

- Left column: fixed `128px` width — title, body copy, status tags, controls.
- Right column: the board, `170px × 500px`, absolutely positioned 4-layer stack (see below).
- Row: `display:flex; gap:14px; align-items:flex-start`.
- Screens with no board (Main, Opponent picker) drop the right column and use the full width, `flex-direction:column`.
- Primary action always pinned to the bottom of the screen as a full-width button (`btn btn-primary btn-block`); secondary/back actions sit above it or top-left as a ghost icon button.

Phone canvas: 390×844, content padding `28px 22px 22px`, `background: var(--color-bg)`, `color: var(--color-text)`, `font-family: var(--font-body)`.

## The board (used in tutorial + match)

4 stacked layers representing a 4×4×4 cube, drawn as 4 offset/rotated 4×4 grids to read as depth:

- Each layer: `position:absolute; width:140px`, offset `left: i*8px; top: i*130px` (i = layer index 0–3), `transform: perspective(700px) rotateX(42deg) rotateZ(-3deg); transform-origin: top left`, `z-index: i+1`.
- Grid: `display:grid; grid-template-columns:repeat(4,1fr); gap:5px`.
- Cell: square (`aspect-ratio:1`), `border-radius: var(--radius-sm)`, `background: var(--color-neutral-600)` (mid-tone grey — chosen for contrast against black pebbles), `border: 1px solid var(--color-neutral-500)`.
- Highlighted cell (tutorial callouts): `background: rgba(145,132,217,0.20)`, `border: 1px solid var(--color-accent)`, `box-shadow: 0 0 0 3px rgba(145,132,217,0.14)`.
- Piece ("pebble"), 58% of cell, circular, radial-gradient for 3D relief:
  - **Light/user piece**: `radial-gradient(circle at 32% 28%, #ffffff, #e4e4e6 55%, #c3c3c8 100%)`, shadow `0 2px 3px rgba(0,0,0,0.4), inset 0 1px 1px rgba(255,255,255,0.7), inset 0 -2px 3px rgba(0,0,0,0.12)`.
  - **Dark/bot piece**: `radial-gradient(circle at 32% 28%, #4a4a52, #1c1c22 55%, #050507 100%)`, shadow `0 2px 3px rgba(0,0,0,0.5), inset 0 1px 1px rgba(255,255,255,0.18), inset 0 -2px 3px rgba(0,0,0,0.4)`.
- Match-screen cells are clickable when empty and it's the user's turn (`cursor:pointer`); tutorial cells are static illustration only.

## Screens

### 1. Tutorial (5 steps + implicit exit to Main)
- Header row: step label ("Step N / 5") left, "Skip tutorial" link (accent) right.
- Progress: 6 thin segments (`4px` tall, `2px` radius), filled segment = `var(--color-accent)`, unfilled = `var(--color-neutral-700)`.
- Step 1 (welcome): no board — big heading (24px) + body only.
- Steps 2–4 (rule/strategy explainers): left column title (18px) + body (12.5px) with the board on the right, specific cells/layers highlighted per step to illustrate the rule.
- Step 5 (practice): board pre-seeded with a couple of pieces; optional "Show hint" ghost button reveals a hint card (`.card`, accent text).
- Footer: Back (ghost, hidden on step 1) + Next/"Start playing" (primary, flex:1).

### 2. Main screen
- Title "Quadrim" (24px heading), no subtitle copy needed once stats are visible.
- Stats card (`.card`): Wins / Losses / Draws as three stat blocks (17px value / 10px label) + a rating tag (`.tag.tag-outline`) right-aligned, e.g. "Unrated".
- **Active games** section: uppercase 11px label; if a game is in progress, a clickable `.card` with opponent name + "Resume" (`.tag.tag-accent`) tag; otherwise "No active games" muted text.
- **Previous games** section: same label style; list of `.card` rows (opponent name left, result e.g. "Resigned" right as `.card-meta`); otherwise "No games yet".
- No board on this screen by design — it only appears once a match starts.
- Footer: "New game" (primary, full-width) only shown when there's no active game; "Tutorial" (secondary, full-width) always available to replay.

### 3. Opponent picker
- Header: back arrow icon button + "Choose your opponent" title; subtitle below.
- Accordion of 3 difficulty categories (Easy / Medium / Hard), each a `.card`:
  - Header row: name + description left, difficulty-range tag (`.tag.tag-outline`) + chevron (`+`/`−`) right. Header border turns accent-colored when open.
  - Body: list of named bots (rating shown right, 11px muted), each row selectable; selected row gets accent tint background + accent border + accent-colored name text. Row click doesn't toggle the accordion (stopPropagation).
  - Panel expand/collapse animates via `max-height` transition (0.32s ease).
- Footer: "Start match" (primary, full-width), label appends "· <bot name>" once a bot is picked.

### 4. Match screen
- Left column: opponent name as `.tag.tag-outline`, turn indicator below ("Your turn" / "Opponent's turn", 18px heading weight).
- Right column: the live board, clickable on user's turn.
- Bot moves after a ~550ms delay (simple random-empty-cell placement in this reference — replace with real engine).
- Footer: "Exit" (ghost, full-width) — pauses and returns to Main with the game marked Active/resumable; "Resign" (text link, muted) below it — ends the game and files it into Previous games as "Resigned".

## Copy / i18n

All strings ship in English and Dutch (`_en`/`_nl` suffixes in the data model), switched via a segmented control (EN/NL) at the top of the reference doc — production should read from the platform's active locale instead. Full string list is in the component's `renderVals()`/`buildDirVals()` — copy verbatim per locale from `design_reference/First-Run Experience.dc.html`.

## Design tokens (from Nocturne, values as shipped — see design_system/styles.css for the source of truth)

- Ground: `--color-bg #161826`, surfaces `--color-surface #232532`, text `--color-text #e9e9ed`.
- Accent: `--color-accent #9184d9` (ramp 100–900 in styles.css); use sparingly (lines, tags, focus rings, selected states) — never a fill.
- Neutral ramp: 100 `#f3f5fe` → 900 `#292b31`; board tiles use 600 `#75798c` for the tile fill, 500 `#9397ab` for tile borders.
- Type: Inter for heading and body; heading weight 500. Never bold past 500.
- Radius: sm 4px, md 8px, lg 14px. Board cells use sm.
- Shadows: `--shadow-sm/md/lg`, already tuned for the dark ground — don't add extra box-shadows beyond the piece bevel shadows above.
- Buttons are outlined, never solid-filled (`.btn-primary` = accent outline). Use `.btn`, `.card`, `.tag`, `.seg` classes from the bundle rather than custom equivalents.
