# Achievement icons — the fourteen volume and streak rungs

Prompts for the fourteen achievement icons ticket 050 needs and the opponent
avatars do not cover. Written in the style of
[avatars-overview.md](avatars-overview.md): one comma-separated phrase, subject
first, then physical detail, a named palette, the setting, the role, and the
style tags last.

The other thirty-one achievements are the per-opponent "you have beaten this
opponent" rungs, and those reuse the avatar in `designs/<id>.png` — thirty-one
portraits that already exist and already say exactly what the achievement means.

## Four constraints these prompts are built around

**No numerals and no words in the art** (D297). The rule that keeps the wooden
signs blank and lets the app letter them applies here for the same reason and one
more: both stores localise an achievement's *name and description*, and an icon
with "30 DAYS" baked into it is a Dutch player reading English. Rank has to be
carried by the picture.

**Two motifs, because the two families collide on numbers.** Volume starts at 5
and 10; so does the streak. "Five" and "five" are the same word and must not be
the same picture, so the families are drawn from different worlds:

| Family | Motif | Files | Reads as |
|---|---|---|---|
| Games in one day | **Glowing carved game cubes**, stacked | `games_in_day_<n>.png` | geometric, gold, hot, piled up |
| Consecutive days | **A growing tree**, seed to world-tree | `days_in_row_<n>.png` | organic, green, vertical, slow |

**The filename is the quest id with its colon replaced by an underscore** (D379).
Both families start at 5 and 10, so two files called "five" was two chances to
attach the wrong art to an id that can never be renamed once published.

The cube is Quadrim's own object and already appears on the rating card, so a
pile of them says "games" without a caption. A tree says "time" the same way, and
the nine streak rungs land almost exactly on seasons: 30 a month, 90 a season,
360 a year, 720 two, 1080 three, 1440 four.

**Fourteen, not thirteen.** A ninth streak rung at 1080 days — three years — was
added at D379, because two years to four was the longest gap on the ladder and
the only one a player could sit inside for two whole years with nothing ahead.

**512×512, centred, and safe under a circular crop.** Play Games wants 512×512
and renders some surfaces round; Game Center wants 512×512 in a rounded square.
One image serves both, and **only one is needed per achievement** — Play Games
desaturates its own locked state rather than taking a second asset. The avatar
prompts say `400x400 avatar`; these say `512x512 icon` because that is what both
consoles ask for.

---

## Games in one day — the cube pile

### 5 games in a day

```
Five small carved wooden game cubes resting on moss, faint amber glow escaping the lattice holes, dew beading on the grain, warm brown and pale green palette, forest floor at morning, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 10 games in a day

```
A neat stack of ten glowing carved game cubes, amber light spilling from every lattice hole, moss creeping up the lowest tier, warm brown and gold palette, sunlit forest floor, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 20 games in a day

```
A balanced cairn of twenty glowing game cubes, tilted and interlocking, thickening amber light pooling in the gaps, fallen leaves scattered at the base, brown gold and deep green palette, forest clearing in the afternoon, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 50 games in a day

```
A tall spire of stacked glowing game cubes rising above the ferns, hot amber light pouring from the lattice, sparks drifting upward into the branches, gold and ember palette against deep forest green, dusk, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 100 games in a day

```
A blazing monument of a hundred glowing game cubes, molten gold light flooding every lattice hole, embers streaming upward into a radiant crown of sparks, white-hot gold and black-green palette, deep forest at night, legendary painterly fantasy achievement icon, centred composition, breathtaking detail, 512x512 icon
```

---

## Consecutive days — the growing tree

### 5 days in a row

```
A single seed splitting open on dark forest soil, one pale green shoot curling upward, a dew drop catching the light on its tip, soft green and brown palette, morning light on the forest floor, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 10 days in a row

```
A young sprout with two unfurling leaves pushing up through moss, thin stem lit from behind, faint golden aura around the leaf edges, fresh green and warm brown palette, forest floor in early light, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 30 days in a row

```
A slender sapling with its first small crown of leaves, a ring of tiny mushrooms circling the base, gentle golden glow at the roots, green and amber palette, mossy forest clearing, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 90 days in a row

```
A young tree in full leaf with one branch already turned autumn gold, a single season visibly passed, glowing motes drifting between the leaves, green gold and russet palette, forest clearing, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 180 days in a row

```
A strong young tree split between two seasons, summer green on one side and bare frost-rimed branches on the other, faint glowing runes in the bark of the trunk, green white and gold palette, forest clearing at the turn of the year, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 360 days in a row

```
A mature tree carrying all four seasons at once around its crown, blossom then summer leaf then autumn gold then winter frost, one luminous growth ring glowing through the trunk, full forest palette of green gold russet and white, painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 720 days in a row

```
An ancient broad-trunked tree with two luminous growth rings burning through the bark, roots gripping moss-covered stone, warm lantern-light glow from within the hollow, deep green gold and stone grey palette, old forest at dusk, majestic painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 1080 days in a row

```
An ancient tree with three luminous growth rings burning through its bark, roots gripping moss-covered stone and lifting it clear of the ground, lantern-light glow deep in the hollow, deep green old gold and stone grey palette, old forest under the first stars, majestic painterly fantasy achievement icon, centred composition, highly detailed, 512x512 icon
```

### 1440 days in a row

```
A colossal world-tree crowning the whole forest, four luminous rings blazing through its bark, roots merging with ancient standing stones, constellations caught in its canopy, celestial gold deep green and night blue palette, legendary final achievement, breathtaking painterly fantasy illustration, centred composition, highly detailed, 512x512 icon
```

---

## Notes for whoever generates these

**Generate the two families in one sitting each.** The escalation only works if
the five cubes and the hundred cubes came from the same seed and the same model
run; a rung generated three weeks later reads as a different game. The avatars
already show this — the four written later (Lynx, Cairn, Flint, and the stacked
guardian) are visibly more considered than the ones around them, which is fine
for thirty-one characters and would be wrong for a ladder.

**Check them at 64 pixels before accepting any of them.** A store list renders
achievements small, and the difference between the 20-cube cairn and the 50-cube
spire has to survive that. If two adjacent rungs are indistinguishable when
shrunk, the taller one needs a silhouette change rather than more detail.

**These are store-side only.** They do not ship in the app bundle and so do not
go through `tools/artgen` — nothing in `app/assets/` needs them and
`art_assets_test.dart` does not check them. They belong in `designs/` beside the
avatars for the same reason those do: it is what makes the set re-runnable.

**The ids they attach to** are in `app/lib/services/achievements.dart` —
`games_in_day:<n>` and `days_in_row:<n>`, with Game Center ids already chosen and
Play Games ids unset until the console issues them. An achievement id cannot be
reused after publication on either store (D213, D365), so pair each icon with its
id once and do not renumber.
