# 017 — Large-screen landscape layout

**What to build:** On a tablet or a desktop-sized window the app uses the space properly: the board sits on the left, and player details sit alongside it on the right, in landscape. Phones remain portrait-only. A window that crosses the size threshold mid-game switches layout without losing the game.

**Blocked by:** 011 — Opponent selection; 013 — Main screen

**Status:** ready-for-agent

- [ ] The layout is chosen by the shortest side of the window: below 600 density-independent pixels is a phone, at or above is a large screen
- [ ] Phones are locked to portrait; large screens are locked to landscape
- [ ] On a large screen the board is on the left and player details on the right
- [ ] The right panel shows the local player's details and the opponent's, including the head-to-head record between them
- [ ] The same board component serves both layouts, differing in size and surrounding chrome rather than in structure
- [ ] Crossing the threshold by resizing a window mid-game preserves the game state completely
- [ ] All four layers and all 64 cells remain visible without scrolling in both layouts
- [ ] Both layouts are legible in light and dark themes and at the largest system font scale
- [ ] All new strings are present in English and Dutch
