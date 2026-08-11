# 015 — Store accounts and release signing

**What to build:** The project can produce a signed release build that Google Play will accept, and both store accounts exist.

**This ticket is numbered here but has no code dependencies and should be started on day one.** Apple's enrolment involves identity verification that can take days to weeks, and Google Play account setup is a prerequisite for everything downstream. Both are waiting time rather than effort.

**One decision here is genuinely irreversible: the application id.** It can never be changed once published to any track, including closed testing. Note that a lost *upload* key is not the catastrophe it is often described as — with Play App Signing, mandatory for new applications, Google holds the app signing key and an upload key can be reset through support. Back it up and verify the backup anyway; just do not let that fear crowd out the decision that actually cannot be undone.

**Blocked by:** None — can start immediately, and should.

**Status:** ready-for-agent

- [ ] A Google Play Console developer account exists and is verified
- [ ] Apple Developer Program enrolment is started, with its status tracked
- [x] The final application id is chosen, recorded, and applied, replacing the placeholder — `nl.evict.quadrim`, set 2026-08-11 before any upload (D213)
- [ ] An upload keystore is generated and backed up somewhere durable and off the development machine
- [ ] The backup has been verified by restoring it, not merely by creating it
- [ ] Release signing is configured so a signed release build can be produced by one command
- [ ] Keystore credentials are kept out of version control, and a check enforces this
- [ ] A signed release build installs and runs correctly on a physical Android device
- [ ] The app version and build number scheme is defined and applied
- [ ] The app name's availability is checked on both stores and against trademark registers, and the result recorded — it sits beside the application id in irreversibility and is currently unchecked
- [ ] What Play requires of an individual developer account regarding a publicly displayed contact address is checked and recorded, since it applies by 0.3b
- [ ] Whether a non-residential address is acceptable, and the current scope of KvK address shielding for a home-run sole trader, are checked and recorded with a date — for a solo developer both questions point at a home address
- [ ] DSA trader-verification requirements as currently enforced by both stores on EU-established developers are checked and recorded with a date, **including whether they reach closed-testing-only distribution**
