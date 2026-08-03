# 028 — Settings screen

**What to build:** A place to change the three things a player can change. Language, theme, and a way back into the tutorial.

Small, but it is a blocker of the first upload for a reason that is easy to miss: **half the closed testers are Dutch**, and without a language override a Dutch tester whose phone is set to English cannot see the Dutch build at all. The settings document already exists (ticket 005) and currently has no writer.

**Blocked by:** 013 — Main screen

**Status:** ready-for-agent

- [ ] Reachable from the main screen
- [ ] Language: system, English, or Dutch — applied immediately, without a restart
- [ ] Theme: system, light, or dark — applied immediately
- [ ] Restart the tutorial from here, as well as from the main screen
- [ ] Choices persist in the settings document and survive a restart
- [ ] The screen is navigable by screen reader, readable at the largest system font scale, and correct in both themes
- [ ] All new strings are present in English and Dutch
