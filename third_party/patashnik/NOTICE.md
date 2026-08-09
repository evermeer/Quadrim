# Patashnik's Qubic strategy dictionary

`qubic.dictionary` is vendored **byte for byte**, header and all.

| | |
|---|---|
| Bytes | 54,745 |
| SHA-256 | `38d9b7820fd97269968e6eea32c6448712d0551e66c1f2ed1ce47f74f3069499` |
| Retrieved from | `https://raw.githubusercontent.com/kogorman/qubic/master/qubic.dictionary` |
| Retrieved on | 2026-08-09 |

## Provenance

- **Oren Patashnik** constructed the 2929 strategic moves in 1976-77 and published
  the proof that Qubic is a first-player win: *"Qubic: 4x4x4 Tic-Tac-Toe"*,
  Mathematics Magazine **53** (4), September 1980, pages 202-216.
- **Ken Thompson** put the dictionary into its current form in 1978.
- **Kevin O'Gorman** published this copy, having obtained Patashnik's permission
  around 2000 to build a game around the strategic moves.

## Terms

The file states its own terms in its header, and they are the terms this project
relies on:

> Copyright 1988, all rights reserved.
> […] Anyone may use this dictionary as long its moves are unchanged and as long
> as its source is credited.

Two obligations, and how each is met:

1. **Moves unchanged.** The file is vendored verbatim; `tool/check.sh` verifies
   the SHA-256 above on every run, and `.gitattributes` marks it `-text` so no
   line-ending conversion can alter it. The generator reads it and never writes
   it.
2. **Source credited.** Credited here, in the header of every generated file
   derived from it, and — the obligation that actually matters, because it is
   the binary that reaches people — **in the application itself**. See D174.

## What is deliberately *not* used from that repository

`github.com/kogorman/qubic` is licensed **GPL-2.0**, which covers Kevin
O'Gorman's C++ under `qval/`. Quadrim takes **only `qubic.dictionary`**, which
carries its own permissive notice quoted above and predates that repository by
decades. No line of the GPL-2.0 source was read or adapted; the move-generation
procedure is implemented from the description in the dictionary's own header and
from Patashnik's published article.

This separation is the whole basis on which Quadrim can ship as it does, and it
must survive any future update of this directory: **if you refresh the data, take
the dictionary and nothing else.**
