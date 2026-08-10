# 013 — Main screen

**What to build:** The app gets a home. On launch the player sees how many games they have won, lost and drawn, which games are still in progress, and a list of finished games they can replay — plus an obvious button to start a new game and one to open the tutorial.

This is where the app stops being a board and becomes a product.

**Blocked by:** 005 — Local persistence behind a game repository; 007 — Result screen, rematch and resign

**Status:** ready-for-agent

- [ ] Overall statistics show wins, losses and draws
- [ ] Statistics are broken down by opponent, so a player can see which opponents they beat
- [ ] Games in progress are listed with their opponent, and tapping one resumes it
- [ ] Completed games are listed most recent first, and tapping one opens its replay
- [ ] A large, obviously primary button starts a new game
- [ ] A separate button opens the tutorial
- [ ] An entry point to the settings screen exists
- [ ] Statistics, the per-opponent breakdown, the computer rating and the milestones are derived from **one** load of the stored games, not four independent sweeps
- [ ] Statistics and lists update when a game finishes, without needing a restart
- [ ] The player's computer rating is shown prominently, labelled so it reads as a rating against the computer rather than a universal one
- [ ] There is room in the layout for the separate human rating arriving at 0.3b, without the two ever reading as one number
- [ ] Statistics are derived from stored games at read time and are never stored separately, so they cannot drift from the games they summarise
- [ ] The screen is navigable by screen reader, and readable at the largest system font scale
- [ ] All new strings are present in English and Dutch
