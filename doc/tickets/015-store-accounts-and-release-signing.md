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

**Android release signing was recorded as done and was not** ([D355](../idea-v3-decisions.md)).
`build.gradle.kts` still held the Flutter template's `signingConfig =
signingConfigs.getByName("debug")` with its TODO intact, and no keystore
existed anywhere. Whatever ran on a device for 0.1 and 0.2 was debug-signed,
which Play rejects on upload. The Gradle side is now genuinely done — a release
task without `key.properties` fails instead of falling back — but **the
keystore itself does not exist yet and only the developer can create it**.

**One decision here is genuinely irreversible: the application id.** It can never be changed once published to any track, including closed testing. Note that a lost *upload* key is not the catastrophe it is often described as — with Play App Signing, mandatory for new applications, Google holds the app signing key and an upload key can be reset through support. Back it up and verify the backup anyway; just do not let that fear crowd out the decision that actually cannot be undone.

**Blocked by:** None — can start immediately, and should. **Blocks:** 046, 048
and 049, and through them the whole of 1.0.

**Status:** in-progress — Android blocked only on the keystore (developer action)

- [ ] **Apple Developer Program enrolment is complete** — the critical path for
      1.0, and the one item here that cannot be shortened by working harder
- [ ] An App ID for `nl.evict.quadrim` exists in the developer portal, and a
      distribution certificate and provisioning profile are in place (see 048)
- [ ] Both store products are created — `nl.evict.quadrim.unlock_all` as a
      non-consumable, and `nl.evict.quadrim.unlimited` as a subscription **in a
      group with one base plan**, so 3.0 can add tier 3 as a second plan (046)
- [ ] Price points are chosen per country with tax treatment confirmed — spec
      gate R16, and the longest-standing open item in the project
- [x] A Google Play Console developer account exists and is verified —
      reactivated 2026-08-21, and the app entry created in the console
- [x] The final application id is chosen, recorded, and applied, replacing the placeholder — `nl.evict.quadrim`, set 2026-08-11 before any upload (D213). **It is the iOS bundle identifier too**, checked in ticket 041
- [x] An upload keystore is generated and backed up somewhere durable and off the development machine — `quadrim-upload.jks`, RSA 2048, valid to 2054, created 2026-08-21 outside the working tree
- [x] The backup has been verified by restoring it, not merely by creating it — confirmed 2026-08-21
- [x] Release signing is configured so a signed release build can be produced by one command — `flutter build appbundle --release`, reading `app/android/key.properties` (D355)
- [x] Keystore credentials are kept out of version control, and a check enforces this — `check.sh` asks git what is tracked rather than trusting `.gitignore`
- [ ] A signed release build installs and runs correctly on a physical Android device — **previously ticked in error**: the 0.1 and 0.2 builds were signed with the debug key (D355)
- [ ] The same is true on iOS, which is ticket 048's whole subject
- [x] The app version and build number scheme is defined and applied — `<name>+<code>` in `pubspec.yaml`, the name for people and the code a ratchet Play enforces; spent on upload rather than on release (D358)
- [ ] The app name's availability is checked on both stores and against trademark registers, and the result recorded — it sits beside the application id in irreversibility and is currently unchecked
- [ ] What **each** store requires of an individual developer account regarding a publicly displayed contact address is checked and recorded — **this now applies at 1.0**, which is sooner than the 0.3b these items were written for
- [ ] Whether a non-residential address is acceptable, and the current scope of KvK address shielding for a home-run sole trader, are checked and recorded with a date — for a solo developer both questions point at a home address
- [ ] DSA trader-verification requirements as currently enforced by both stores on EU-established developers are checked and recorded with a date, **including whether they reach closed-testing-only distribution**
