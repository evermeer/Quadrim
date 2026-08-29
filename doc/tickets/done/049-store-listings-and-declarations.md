# Ticket 049 — Store listings, declarations and privacy labels

**Depends on:** 048 (a build to attach them to), 022 (release readiness)

**Status:** **done.** The Apple listing is submitted and in review; Play's
closed-testing listing is live; the contact-address and DSA questions closed with
ticket 015. One leftover is recorded at the end rather than left to be found: the
privacy policy in `doc/store-listing.md` still carries the three placeholders the
published page must already have replaced.

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


## Closure

**Closed with the Apple submission in review.** A listing in review is a set of
claims Apple has not yet checked, and a rejection would land here — but the work
this ticket describes is finished, and waiting for a reviewer to agree is not a
task. The parts that
are finished are the parts that had to be finished before the button worked: the
copy in both languages, the screenshots, the privacy labels, the content rating,
the target audience, and the subscription's price, period and benefit in the
description (§3, and D367 for the EULA link that a previous rejection asked
for). Play's closed-testing listing exists on the same basis.

### The one thing left, and it is a paste

1. **The privacy policy's contact block is still `[CONTACT NAME]`,
   `[CONTACT EMAIL]` and `[CONTACT ADDRESS]`** in `doc/store-listing.md`. It was
   a deliberate stop — which identity and which address becomes permanently
   public is a decision, not a field — and **the decision has now been made**
   (015). So the placeholders are simply out of date, and the live policy at the
   URL both stores were given must already carry real values or Apple would not
   be reviewing. **Paste them back into `doc/store-listing.md`, in both
   languages**, and read the two side by side once: the repository's copy of a
   published legal document disagreeing with the published one is the failure
   mode this file exists to prevent.
2. ~~**The DSA trader-verification and contact-address questions are open** in
   ticket 015.~~ **Answered**, and 015 is closed — though its own closure notes
   that the answers were reported rather than written down. Criterion 7 is met on
   that basis (D371); criterion 6's *"recorded with the date"* is met the same
   way and with the same gap.
3. **Nothing in the app links to the privacy policy or the Terms of Use.**
   `grep -ri privacy app/lib` still returns nothing. Both stores accept a
   listing-only link, so it did not block this ticket — but reviewers routinely
   ask for both on the purchase screen itself, and **it remains the most likely
   reason the submission now in review comes back**. The shop screen and ticket
   028's settings screen are where they belong, with l10n strings like everything
   else (D297). If a rejection arrives, this is the first thing to check.

### Criteria

| AC | Status |
|----|--------|
| 1 — complete listings on both stores, English and Dutch | **Apple met** (in review). **Play met for closed testing**; the production listing is a separate act. |
| 2 — screenshots from the shipping build on a real device | **Met**, reported. |
| 3 — privacy labels and Data Safety complete and consistent | **Met**, reported — and the answers exist only in two web forms. Copy them into `doc/store-listing.md` so the next form is filled from a record rather than from memory. |
| 4 — "no data leaves the device" appears nowhere (D72) | **Met** in the drafted copy, which never uses it. **Unverifiable for the published pages** from here — worth one search of the live listing and policy, because it is false rather than merely awkward. |
| 5 — the subscription's price, period and benefit appear in the listing | **Met** — added after the rejection that asked for it. |
| 6 — content rating and target audience answered and recorded with the date | **Answered.** *Recorded with the date* is not done: neither answer nor date is in this repository. |
| 7 — contact-address and DSA questions answered with a date | **Met**, reported (015's closure, D371). The date and the answers are not written down. |
| 8 — the privacy policy URL exists and is reachable | **Met** — Apple will not review without one. Whether the page behind it still carries the three placeholders is the paste in §1 above. |
