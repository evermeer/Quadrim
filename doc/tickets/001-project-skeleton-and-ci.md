# 001 — Project skeleton and CI

**What to build:** A developer can clone the repository, run one command, and get a Flutter app that launches on an Android device and shows a placeholder home screen. The pure logic packages exist but are empty. Static analysis and tests run in CI on every push. Localisation is wired for English and Dutch from the very first screen, and light and dark themes follow the system setting.

This ticket exists to make every later ticket cheap. Nothing here is user-visible beyond a placeholder, but every convention the project relies on is established now — particularly that no user-facing string is ever hard-coded and that the logic packages cannot accidentally depend on Flutter.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Workspace contains the Flutter application plus two pure Dart packages, one for the game engine and one for rating
- [ ] Neither pure package declares a dependency on Flutter, Firebase, or platform I/O, and a check enforces this
- [ ] The application launches on a physical Android device and on an emulator
- [ ] A single command runs static analysis and the full test suite across every package
- [ ] CI runs that command on every push and fails on any analysis error or test failure
- [ ] Localisation resources exist for English and Dutch, and the placeholder screen draws its text from them
- [ ] A check fails the build when a user-facing literal string is introduced
- [ ] Light and dark themes are defined and follow the system setting
- [ ] The application id is a clearly marked placeholder, with a recorded note that it is permanent once published and must be decided before the first upload
