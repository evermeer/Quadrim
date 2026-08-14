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

## Cancelled — not built

Cancelled by idea-v3.md §8.1 and spec §5.2 (D253). **Nothing in this ticket was
implemented.** It is filed here rather than deleted because the reasoning is
worth keeping.

A large-screen layout is a second set of screens to design, build, test at every
font scale and keep correct, in service of a form factor nobody has yet asked
for. The first release targets phones. It can come back when there is a reason,
and coming back is cheaper than carrying it unused.

Two consequences. The app is now portrait-only on **every** device, not only on
phones — locked in ticket 035, and asserted by spec criterion U10. And ticket
021 no longer blocks on this one; its blockers moved to 030–035 (D269).
