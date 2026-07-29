# 006 — Bot engine and Pebble

**What to build:** A player can choose to play against the computer instead of a second human, and play a full game against Pebble — the weakest opponent, which places pieces at random.

Pebble is trivial, and that is the point: this ticket delivers the shared machinery that all twenty eventual opponents run on. A bot is a configuration record, not a class, so every later opponent is a catalogue entry rather than new code.

**Blocked by:** 004 — Playable board and pass-and-play

**Status:** ready-for-agent

- [ ] A single move-choosing function serves every computer opponent, parameterised by configuration
- [ ] The configuration covers search depth, which strategic rules are enabled, blunder rate, positional bias, aggression, and tie-break randomness
- [ ] An opponent catalogue exists as data, with Pebble as its first entry
- [ ] Randomness is injected rather than ambient, so a given seed and state always produce the same move
- [ ] Starting a new game offers a choice between a computer opponent and a second human
- [ ] A full game against Pebble can be played to a win, a loss, and a draw
- [ ] The chosen move is always legal, verified across thousands of randomly generated positions for every catalogue entry
- [ ] The computer's move is visible as it happens rather than appearing instantly with no feedback
- [ ] All new strings are present in English and Dutch
