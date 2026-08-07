# Handoff: Quadrim First-Run Experience

## Overview
Onboarding + core game loop for Quadrim (4-in-a-row in a 4×4×4 cube): a guided tutorial, then a main screen with stats and game lists, an opponent picker, and a match screen.

## About the design files
Everything in `design_reference/` is an **HTML/React design prototype** — built to show intended look, layout and behavior, not production code to copy line-for-line. Recreate these screens in your app's actual stack (React Native, SwiftUI, Compose, web, etc.) using its existing patterns, navigation, and state management. Treat the prototype as the spec for structure, spacing, copy and interaction, not as source to paste in.

`design_reference/android-frame.jsx` is only a device-bezel mockup for previewing in-browser — skip it entirely on the real app.

## Fidelity
**High-fidelity.** Colors, spacing, typography and the board's 3D-pebble rendering are final; recreate pixel-close using your platform's equivalents of the tokens in `design_system/styles.css`.

## Read this first
`design.md` is the actual design spec: layout rules, the board's construction, per-screen breakdown, copy/i18n handling, and the token cheat-sheet. Read it before opening the HTML.

## Design system
Nocturne — dark, low-chroma, Inter type, single blurple accent used only as line/glow/tag, 8px-based radii. Source files are in `design_system/`:
- `styles.css` — all color/type/spacing/radius/shadow tokens + component CSS (source of truth for exact values).
- `readme.md` — the system's design guide (voice, do/don't rules).
- `_ds_bundle.js` — the component bundle the prototype loads at runtime (reference only; not for reuse outside this HTML tooling).

Do not hardcode hex/px values in the real app — port these tokens into your platform's theme (e.g. a Colors/Typography/Spacing constants file or design-token JSON) and reference them everywhere.

## Files
- `design.md` — the spec (start here).
- `design_reference/First-Run Experience.dc.html` — open directly in a browser; the full interactive flow (tutorial → main → opponent picker → match), EN/NL toggle top-right.
- `design_reference/android-frame.jsx` — device bezel used only for in-browser preview; not needed for implementation.
- `design_system/` — Nocturne tokens and guide, as described above.

## Notes for implementation
- Bot move logic in the prototype is a placeholder (random empty cell after ~550ms) — replace with the real engine/matchmaking.
- Stats (wins/losses/draws), rating, and game history are static/mocked in the prototype — wire to real user data.
- All copy exists in English and Dutch already (see design.md → Copy/i18n); pull strings from the prototype's source rather than retranslating.
