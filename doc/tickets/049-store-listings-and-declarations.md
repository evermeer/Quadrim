# Ticket 049 — Store listings, declarations and privacy labels

**Depends on:** 048 (a build to attach them to), 022 (release readiness)

**Status:** blocked on the accounts

## Why

1.0 is the first public release. Everything in this ticket is a declaration or
a piece of copy that a store requires before it will show the app to anyone,
and each of them is a claim that has to be **true** rather than convenient.

## What it does

### 1. The listing, in English and Dutch

Both stores, both languages. Name, subtitle, description, keywords, what's-new,
screenshots at the sizes each store demands.

Screenshots come from the real app on a real device — the forest, the board,
Your Path, the opponent detail page. Not mockups: `doc/designs/` is source art
for the pipeline, not marketing material, and a screenshot showing something
the app does not do is a rejection on both stores.

### 2. Privacy declarations

- **App Store privacy labels** (App Store Connect) and **Play Data Safety**
  (Play Console). For 1.0 both are close to empty: the app collects nothing,
  transmits nothing, and contains no tracking.
- **Backup is enabled**, and that must not be described as "no data leaves the
  device" — that sentence is forbidden everywhere in this project because it is
  false (D72, and ticket 022 carries the same rule). Android's system backup
  copies `files/quadrim/` to the user's own Google account; iOS's iCloud backup
  does the same. What is true is that *the app* sends nothing anywhere and that
  the backup is the platform's, to the player's own account.
- **Purchases are declared** now that there are purchases — both stores ask
  about them separately from data collection.

### 3. The subscription listing

Apple and Google both require the subscription's price, period and what it
provides to appear in the listing itself, not only in the app. It says what it
is: unlimited computer games, lifting the three-a-day cap. It does **not**
imply online play, which does not exist until 2.0.

### 4. Content rating and audience

The questionnaire on both stores. The audience answer constrains what may be
shown and sold, so answer it once, correctly, and record the answer and its
date. Ticket 015 already flags that the target-audience declaration has
downstream consequences.

### 5. Support and contact obligations

Ticket 015 lists the open questions that arrive with a public listing for an
individual developer in the EU: the publicly displayed contact address, whether
a non-residential address is acceptable, and DSA trader verification. **These
were "needed by 0.3b" and are now needed by 1.0**, which is sooner. They are
research with a date attached, not code.

## Acceptance criteria

1. Complete listings exist on both stores in English and Dutch — subject to
   the Play account, which may make the Android half wait.
2. Screenshots are from the shipping build on a real device, at every required
   size.
3. Privacy labels and Data Safety are complete, consistent with each other,
   and consistent with what the app does.
4. **The phrase "no data leaves the device" appears nowhere**, in any language,
   in any listing (D72).
5. The subscription's price, period and benefit appear in the listing.
6. Content rating and target audience are answered and recorded with the date.
7. The contact-address and DSA questions from ticket 015 are answered with a
   date, and whatever they require is in place.
8. The privacy policy URL required for a public listing exists and is
   reachable. *(2.0 rewrites it when accounts arrive; 1.0 needs one that is
   true today.)*

## Notes

**This ticket cannot be done by an agent.** Every item needs the owner's store
accounts and several need the owner's own decisions about a home address and a
business identity. What an agent can do is draft the listing copy and the
answers; what it cannot do is submit them.
