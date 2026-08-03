# 029 — Placeholder art and opponent content

**What to build:** The visual and written identity of the twenty opponents, at the quality a private closed test needs and no higher.

Several tickets already *consume* this — ticket 011 renders an avatar and a personality blurb for each opponent, ticket 016 requires an app icon for the listing — but nothing produced it. That is the gap this closes.

**Placeholder art is deliberate.** Twenty finished character avatars is a commissioning exercise with a cost and an external dependency, and 0.1 goes to twelve people who know the developer. Real art is explicit scope in 0.2, alongside the App Store submission.

The writing is not placeholder. Twenty personality blurbs are what make the roster feel like opponents rather than difficulty levels, and they are what a tester reads when choosing who to play.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Twenty distinct placeholder avatars exist, one per opponent, visually distinguishable at the size the opponent list renders them
- [ ] Avatars are distinguishable without relying on colour alone
- [ ] They are generated or geometric rather than commissioned, and are clearly identifiable as placeholder so nobody mistakes 0.1 for the finished look
- [ ] A plain app icon exists at every size both stores require
- [ ] Each of the twenty has a one-line personality blurb describing how it plays, in English and Dutch — forty strings
- [ ] Blurbs describe observable behaviour, so that what a player reads matches what they meet at the board
- [ ] Quadrim Prime's blurb says extremely strong, **not perfect** — it ships without the strategy book
- [ ] Opponent names are not translated; blurbs and tier labels are
- [ ] A note is carried into 0.2's scope: twenty real avatars, a real icon, and store graphics, with a make-or-commission decision and a cost
