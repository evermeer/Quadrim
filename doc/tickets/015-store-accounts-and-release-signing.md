# 015 — Store accounts and release signing

**What to build:** The project can produce a signed release build that Google Play will accept, and both store accounts exist.

**This ticket is numbered here but has no code dependencies and should be started on day one.** Apple's enrolment involves identity verification that can take days to weeks, and Google Play account setup is a prerequisite for everything downstream. Both are waiting time rather than effort, and both sit on the critical path to the project's stated definition of success. Starting them late delays the release regardless of how fast the code goes.

Two decisions made here are irreversible. The application id can never be changed once published. A lost upload keystore can never be recovered.

**Blocked by:** None — can start immediately, and should.

**Status:** ready-for-agent

- [ ] A Google Play Console developer account exists and is verified
- [ ] Apple Developer Program enrolment is started, with its status tracked
- [ ] The final application id is chosen, recorded, and applied, replacing the placeholder
- [ ] An upload keystore is generated and backed up somewhere durable and off the development machine
- [ ] The backup has been verified by restoring it, not merely by creating it
- [ ] Release signing is configured so a signed release build can be produced by one command
- [ ] Keystore credentials are kept out of version control, and a check enforces this
- [ ] A signed release build installs and runs correctly on a physical Android device
- [ ] The app version and build number scheme is defined and applied
