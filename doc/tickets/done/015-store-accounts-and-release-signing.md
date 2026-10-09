# 015 — Store accounts and release signing

**What to build:** The project can produce a signed release build that each
store will accept, and both store accounts exist.

**Re-pointed by D302, and the two halves are now independent.** This ticket was
written when Google Play was the only store that mattered and its account was
the critical path. That account was then unreachable for months, which swapped
the halves around; it came back on 2026-08-21, so both now run at once:

- **The Apple half is the critical path for 1.0 and should be started today.**
  Enrolment involves identity verification that can take days to weeks, and no
  code can proceed past ticket 048 without it. It is waiting time rather than
  effort, which is exactly why it must start before the work that waits on it.
- **The Google half is unblocked again.** The Play account was reactivated and
  the app created in the console on 2026-08-21, so the Android upload is live
  work rather than parked work. Both halves now run in parallel.

**Android release signing was recorded as done and was not** ([D355](../../history/idea-v3-decisions.md)).
`build.gradle.kts` still held the Flutter template's `signingConfig =
signingConfigs.getByName("debug")` with its TODO intact, and no keystore
existed anywhere. Whatever ran on a device for 0.1 and 0.2 was debug-signed,
which Play rejects on upload. The Gradle side is now genuinely done — a release
task without `key.properties` fails instead of falling back — but **the
keystore itself does not exist yet and only the developer can create it**.

**One decision here is genuinely irreversible: the application id.** It can never be changed once published to any track, including closed testing. Note that a lost *upload* key is not the catastrophe it is often described as — with Play App Signing, mandatory for new applications, Google holds the app signing key and an upload key can be reset through support. Back it up and verify the backup anyway; just do not let that fear crowd out the decision that actually cannot be undone.

**Blocked by:** None — can start immediately, and should. **Blocks:** 046, 048
and 049, and through them the whole of 1.0.

**Status:** **done.** Both stores have a build on a testing track, so accounts,
signing and products are settled by demonstration; and the developer reports the
research half — tax treatment, the app name, the public contact address and DSA
trader verification — as answered too (D371). **The answers themselves are not in
this repository**, and the closure says which four lines are missing and why that
matters.

- [x] **Apple Developer Program enrolment is complete** — it was the critical
      path for 1.0 and it is behind us; TestFlight distribution proves it
- [x] An App ID exists in the developer portal, and a distribution certificate
      and provisioning profile are in place (see 048) — proven by an upload App
      Store Connect accepted. **The iOS id is `nl.evict.quadrim2`**, not the
      `nl.evict.quadrim` this line originally named; the two diverged at D359 and
      neither can change now
- [x] Both store products are created — `nl.evict.quadrim2.unlock_all` as a
      non-consumable, and `nl.evict.quadrim2.unlimited` as a subscription **in a
      group with one base plan**, so 3.0 can add tier 3 as a second plan (046).
      Confirmed by the shop resolving them rather than rendering its unavailable
      state
- [x] Price points are chosen — spec gate R16, and for two years the
      longest-standing open item in the project. €4.99 to unlock all
      opponents, €2.99 a year for unlimited play, decided 2026-08-27 (D368).
      Both are euro base prices; each store derives its own per-country price
      from them
- [x] Tax treatment is confirmed rather than assumed — both stores act as
      merchant of record in most territories and remit VAT themselves, which is
      the half of R16 that is a fact to check and not a choice to make
- [x] A Google Play Console developer account exists and is verified —
      reactivated 2026-08-21, and the app entry created in the console
- [x] The final application id is chosen, recorded, and applied, replacing the placeholder — `nl.evict.quadrim`, set 2026-08-11 before any upload (D213). **It is the iOS bundle identifier too**, checked in ticket 041
- [x] An upload keystore is generated and backed up somewhere durable and off the development machine — `quadrim-upload.jks`, RSA 2048, valid to 2054, created 2026-08-21 outside the working tree
- [x] The backup has been verified by restoring it, not merely by creating it — confirmed 2026-08-21
- [x] Release signing is configured so a signed release build can be produced by one command — `flutter build appbundle --release`, reading `app/android/key.properties` (D355)
- [x] Keystore credentials are kept out of version control, and a check enforces this — `check.sh` asks git what is tracked rather than trusting `.gitignore`
- [x] A signed release build installs and runs correctly on a physical Android device — the closed test is running on twelve testers' own devices, which is a stronger result than the single install this line asked for. *(It was ticked in error once before, when the 0.1 and 0.2 builds were debug-signed — D355. This time the evidence is Play accepting the bundle and testers installing it.)*
- [x] The same is true on iOS, which is ticket 048's whole subject — a
      TestFlight build installed and a full game played on it
- [x] The app version and build number scheme is defined and applied — `<name>+<code>` in `pubspec.yaml`, the name for people and the code a ratchet Play enforces; spent on upload rather than on release (D358)
- [x] The app name's availability is checked on both stores and against trademark registers, and the result recorded — it sits beside the application id in irreversibility and is currently unchecked
- [x] What **each** store requires of an individual developer account regarding a publicly displayed contact address is checked and recorded — **this now applies at 1.0**, which is sooner than the 0.3b these items were written for. **It is now the most urgent item on this ticket**: a submission is in review, and the same three fields are the placeholders still sitting in the privacy policy in `doc/store-listing.md`
- [x] Whether a non-residential address is acceptable, and the current scope of KvK address shielding for a home-run sole trader, are checked and recorded with a date — for a solo developer both questions point at a home address
- [x] DSA trader-verification requirements as currently enforced by both stores on EU-established developers are checked and recorded with a date, **including whether they reach closed-testing-only distribution**


## Closure

**Done.** Two halves closed in two different ways, and the difference is worth
keeping visible.

**The first half closed by demonstration.** Accounts, signing, application ids,
the keystore and its verified backup, the products in both consoles, and a signed
release build installing on real devices — all of it is proven by the fact that
twelve testers are playing an Android build from a closed track and a TestFlight
build has been played on iOS. Nothing here rests on anybody's word.

**The second half closed on the developer's report**, per D371: tax treatment,
the app name against trademark registers, the contact-address requirements of
both stores, the KvK shielding question, and DSA trader verification. Those are
research with an answer, and the answers are not in this repository.

### The four lines that are still missing, and why they are not a formality

Every one of those items says *"checked **and recorded**"*, and the recording is
the half that survives. The check happened in somebody's browser last week; in a
year the question will come back — a store policy update, a renewal, a second
app — and what will be reachable is this file.

One line each is enough:

1. **Tax treatment** — that both stores act as merchant of record and remit VAT
   themselves in the territories that matter here, or wherever that turned out
   not to hold.
2. **The app name** — what was searched, on which registers, and the date.
3. **The public contact address** — what each store requires of an individual
   developer, what was given, and whether it is a home address.
4. **DSA trader verification** — whether it applies, whether it reaches
   closed-testing-only distribution, and the date the rules were read. This one
   dates fastest; the date is the most useful part of it.

**And the same three fields are still placeholders in `doc/store-listing.md`.**
The privacy policy there reads `[CONTACT NAME]`, `[CONTACT EMAIL]` and
`[CONTACT ADDRESS]`, which was a deliberate stop precisely until this decision
was made. It is made — so paste the values in, in both languages, and check that
what they say matches the page actually published at the URL both stores were
given. A privacy policy that disagrees with the repository's copy of it is worse
than one that was never drafted here.

### No review section

`codereview-main.md` has no entry for this ticket and does not need one: 015's
only code artefact is the Gradle release signing config, reviewed where it landed
(D355).
