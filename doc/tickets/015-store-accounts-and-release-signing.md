# 015 — Store accounts and release signing

**What to build:** The project can produce a signed release build that each
store will accept, and both store accounts exist.

**Re-pointed by D302, and the two halves are now independent.** This ticket was
written when Google Play was the only store that mattered and its account was
the critical path. That account cannot currently be reactivated, so the halves
have swapped roles:

- **The Apple half is the critical path for 1.0 and should be started today.**
  Enrolment involves identity verification that can take days to weeks, and no
  code can proceed past ticket 048 without it. It is waiting time rather than
  effort, which is exactly why it must start before the work that waits on it.
- **The Google half is blocked and blocks nothing.** 1.0 ships to each store as
  that store becomes able to accept it, so a stalled reactivation delays the
  Android build and no longer delays the release.

Android release signing is **done** — ticket 015's Android criteria were met
for the 0.1 and 0.2 builds. What remains here is Apple's side and the research
items, which a public listing now needs at 1.0 rather than at 0.3b.

**One decision here is genuinely irreversible: the application id.** It can never be changed once published to any track, including closed testing. Note that a lost *upload* key is not the catastrophe it is often described as — with Play App Signing, mandatory for new applications, Google holds the app signing key and an upload key can be reset through support. Back it up and verify the backup anyway; just do not let that fear crowd out the decision that actually cannot be undone.

**Blocked by:** None — can start immediately, and should. **Blocks:** 046, 048
and 049, and through them the whole of 1.0.

**Status:** ready-for-agent

- [ ] **Apple Developer Program enrolment is complete** — the critical path for
      1.0, and the one item here that cannot be shortened by working harder
- [ ] An App ID for `nl.evict.quadrim` exists in the developer portal, and a
      distribution certificate and provisioning profile are in place (see 048)
- [ ] Both store products are created — `nl.evict.quadrim.unlock_all` as a
      non-consumable, and `nl.evict.quadrim.unlimited` as a subscription **in a
      group with one base plan**, so 3.0 can add tier 3 as a second plan (046)
- [ ] Price points are chosen per country with tax treatment confirmed — spec
      gate R16, and the longest-standing open item in the project
- [ ] A Google Play Console developer account exists and is verified —
      **blocked on reactivation, and blocking only the Android half of 1.0**
- [x] The final application id is chosen, recorded, and applied, replacing the placeholder — `nl.evict.quadrim`, set 2026-08-11 before any upload (D213). **It is the iOS bundle identifier too**, checked in ticket 041
- [ ] An upload keystore is generated and backed up somewhere durable and off the development machine
- [ ] The backup has been verified by restoring it, not merely by creating it
- [ ] Release signing is configured so a signed release build can be produced by one command
- [ ] Keystore credentials are kept out of version control, and a check enforces this
- [x] A signed release build installs and runs correctly on a physical Android device — done for 0.1 and 0.2
- [ ] The same is true on iOS, which is ticket 048's whole subject
- [ ] The app version and build number scheme is defined and applied
- [ ] The app name's availability is checked on both stores and against trademark registers, and the result recorded — it sits beside the application id in irreversibility and is currently unchecked
- [ ] What **each** store requires of an individual developer account regarding a publicly displayed contact address is checked and recorded — **this now applies at 1.0**, which is sooner than the 0.3b these items were written for
- [ ] Whether a non-residential address is acceptable, and the current scope of KvK address shielding for a home-run sole trader, are checked and recorded with a date — for a solo developer both questions point at a home address
- [ ] DSA trader-verification requirements as currently enforced by both stores on EU-established developers are checked and recorded with a date, **including whether they reach closed-testing-only distribution**
