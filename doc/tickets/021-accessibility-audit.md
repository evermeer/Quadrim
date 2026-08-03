# 021 — Accessibility audit

**What to build:** A sweep across the finished app confirming that everything earlier tickets promised individually actually holds together. A player using a screen reader can complete a whole game from launch to result. A colourblind player can tell the pieces apart on every screen. Nothing breaks at the largest system font scale.

Every previous ticket carried its own accessibility criteria, so this is a verification pass rather than a build — but it is kept as a separate ticket because cross-screen flows are exactly what per-ticket checks miss.

**Blocked by:** 017 — Large-screen landscape layout; 020 — Tutorial: interactive practice game; 023 — Per-opponent milestones; 027 — Rating against the computer; 028 — Settings screen

**Status:** ready-for-agent

- [ ] A complete game can be played start to finish using only a screen reader, on a real device
- [ ] Every cell announces its layer, row, column and contents
- [ ] Turn changes, the result and the winning line are announced
- [ ] Navigation order is sensible on every screen, with no unreachable or unlabelled controls
- [ ] Pieces remain distinguishable on every screen under simulation of the common forms of colour blindness
- [ ] No information anywhere is conveyed by colour alone
- [ ] Every screen is usable at the largest system font scale, with no clipped or overlapping text
- [ ] Touch targets meet platform minimum sizes on the smallest supported phone
- [ ] Contrast meets accepted guidelines in both light and dark themes
- [ ] Findings that cannot be fixed within this ticket are recorded as follow-up work rather than left undocumented
