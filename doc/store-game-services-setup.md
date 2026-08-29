# Setting up the leaderboard and achievements in both stores

Everything a person with the two consoles open needs: what to create, what to
call it, which image to attach, and what to paste back into the code afterwards.

The ids here are generated from `app/lib/services/achievements.dart` rather than
typed, so they match what the app will actually report. **They are permanent once
published** on either store, exactly like a product id (D213, D365) — there is no
rename and no delete after the first release.

---

## Before you start: three things about the images

**1. The 1440-day icon is missing.** `doc/designs/` has twelve of the thirteen:
five `streak-*.png` and seven `consecutive-*.png`. `consecutive-1440.png` is not
there. Its prompt is the last one in
[achievement-icons.md](achievement-icons.md) — the world-tree with four glowing
rings. Everything else can be set up without it; that one achievement cannot.

**2. The filenames are the reverse of the code's naming, and this will bite.**

| Image file | Code family | What it means |
|---|---|---|
| `streak-5,10,20,50,100.png` | **`games_in_day`** | games finished in one day |
| `consecutive-5,10,30,90,180,360,720.png` | **`days_in_row`** | days played in a row |

Both families start at 5 and 10, so `streak-5.png` and `consecutive-5.png` are
both "five" and are **not** interchangeable. The table below names the file for
every row; go by the table, not by the number in the filename.

**3. Both stores want 512×512; the files are 1254×1254.** Both consoles accept
larger and downscale, but 1254 to 512 is not an integer ratio — check a couple at
final size and re-export at exactly 512 if any look soft. The forest art is
detailed and this is where that shows.

---

## Google Play Console

**Path:** Play Console → your app → **Grow users → Play Games Services → Setup
and management**.

### 1. Create the Play Games Services project

Link the app to a PGS project and add an OAuth2 client. **Use the SHA-1 of
Google's app-signing certificate, not your local upload key.** The app is on Play
App Signing, so Google holds the signing key; an OAuth client registered against
the upload key produces a sign-in that works nowhere except a locally-built APK,
and it fails only on the store build. Find it under **Test and release → Setup →
App integrity → App signing key certificate**.

### 2. Add the `APP_ID` meta-data — this one is not optional

Play Games v2 needs the project id in the manifest. Without it the SDK fails when
the app first calls in. Add to `app/android/app/src/main/AndroidManifest.xml`,
inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.games.APP_ID"
    android:value="@string/game_services_project_id"/>
```

and put the number in `app/android/app/src/main/res/values/strings.xml`:

```xml
<string name="game_services_project_id" translatable="false">PROJECT_ID_HERE</string>
```

**A string resource rather than a literal**, because a bare number in the
manifest is read as an integer and truncated.

### 3. Create the leaderboard

**Setup and management → Leaderboards → Create leaderboard.**

| Field | Value |
|---|---|
| Name (EN) | Computer rating |
| Name (NL) | Computerrating |
| Description (EN) | Your rating against the computer opponents. |
| Description (NL) | Je rating tegen de computertegenstanders. |
| Score formatting | **Numeric**, 0 decimal places |
| Ordering | **Larger is better** |
| Limits | leave unset |

### 4. Create the 44 achievements

**Setup and management → Achievements → Create achievement**, once per row of the
table below. For each one:

- **Type: standard**, never incremental. Nothing in Quadrim reports partial
  progress (D378) — every achievement is unlocked or absent.
- **Initial state: revealed.** None of these is a spoiler; a player should be able
  to see what the ladder holds.
- **Icon:** the file named in the table.
- **XP:** the Points column.

### 5. Publish

Leaderboards and achievements stay in **Draft** until the game is published, and
then go out together. **Nothing works against a draft**, which is the usual reason
a first test reports nothing at all.

---

## App Store Connect

**Path:** App Store Connect → your app → **Services → Game Center**.

### 1. Enable Game Center

Turn it on for the app, and add the Game Center capability in Xcode (Signing &
Capabilities → + Capability → Game Center). That writes the entitlement; without
it GameKit fails at sign-in on a device while still working in the simulator.

### 2. Create the leaderboard

**Game Center → Leaderboards → + → Single leaderboard.**

| Field | Value |
|---|---|
| Leaderboard Reference Name | Computer rating |
| Leaderboard ID | `nl.evict.quadrim2.rating` |
| Score Format Type | Integer |
| Score Submission Type | **Best Score** |
| Sort Order | **High to Low** |
| Score Range | leave empty |
| Localisations | English and Dutch, same copy as the Play table above |

**Best Score, not Most Recent.** The rating goes down as well as up, and a
leaderboard showing your worst afternoon is one nobody opens twice.

### 3. Create the 44 achievements

**Game Center → Achievements → +**, once per row. For each:

- **Achievement Reference Name:** the Quadrim key from the table. It is internal,
  and using the key makes the console searchable against the code.
- **Achievement ID:** the Game Center ID column, verbatim.
- **Point Value:** the Points column.
- **Hidden:** No. **Achievable More Than Once:** No.
- **Localisations:** English and Dutch — title, pre-earned description, earned
  description, and the 512×512 image.

**Point values must total no more than 1000 across the app.** The column below
sums to **980**, leaving 20 spare. That limit, and the 100-achievement ceiling
D378 treats as the roster's hard cap, are what the code comments assume —
**confirm both in the console before entering all 44**. Apple's documentation is
rendered client-side and could not be read directly to verify them, and a
different cap means redoing the column rather than one row.

---

## The 44 achievements

Points total **980**. Order: 31 opponents in roster order, then the five volume
rungs, then the eight streak rungs.

| # | Quadrim key | Game Center ID | Image | Points | Name (EN) | Name (NL) |
|---|---|---|---|---|---|---|
| 1 | `beat:pebble` | `nl.evict.quadrim2.beat.pebble` | `pebble.png` | 5 | Pebble defeated | Pebble verslagen |
| 2 | `beat:twig` | `nl.evict.quadrim2.beat.twig` | `twig.png` | 5 | Twig defeated | Twig verslagen |
| 3 | `beat:mote` | `nl.evict.quadrim2.beat.mote` | `mote.png` | 5 | Mote defeated | Mote verslagen |
| 4 | `beat:hazel` | `nl.evict.quadrim2.beat.hazel` | `hazel.png` | 5 | Hazel defeated | Hazel verslagen |
| 5 | `beat:clover` | `nl.evict.quadrim2.beat.clover` | `clover.png` | 5 | Clover defeated | Clover verslagen |
| 6 | `beat:sorrel` | `nl.evict.quadrim2.beat.sorrel` | `sorrel.png` | 5 | Sorrel defeated | Sorrel verslagen |
| 7 | `beat:bramble` | `nl.evict.quadrim2.beat.bramble` | `bramble.png` | 10 | Bramble defeated | Bramble verslagen |
| 8 | `beat:juniper` | `nl.evict.quadrim2.beat.juniper` | `juniper.png` | 10 | Juniper defeated | Juniper verslagen |
| 9 | `beat:bracken` | `nl.evict.quadrim2.beat.bracken` | `bracken.png` | 10 | Bracken defeated | Bracken verslagen |
| 10 | `beat:willow` | `nl.evict.quadrim2.beat.willow` | `willow.png` | 10 | Willow defeated | Willow verslagen |
| 11 | `beat:rowan` | `nl.evict.quadrim2.beat.rowan` | `rowan.png` | 10 | Rowan defeated | Rowan verslagen |
| 12 | `beat:aspen` | `nl.evict.quadrim2.beat.aspen` | `aspen.png` | 10 | Aspen defeated | Aspen verslagen |
| 13 | `beat:vireo` | `nl.evict.quadrim2.beat.vireo` | `vireo.png` | 15 | Vireo defeated | Vireo verslagen |
| 14 | `beat:finch` | `nl.evict.quadrim2.beat.finch` | `finch.png` | 15 | Finch defeated | Finch verslagen |
| 15 | `beat:kestrel` | `nl.evict.quadrim2.beat.kestrel` | `kestrel.png` | 15 | Kestrel defeated | Kestrel verslagen |
| 16 | `beat:osprey` | `nl.evict.quadrim2.beat.osprey` | `osprey.png` | 15 | Osprey defeated | Osprey verslagen |
| 17 | `beat:heron` | `nl.evict.quadrim2.beat.heron` | `heron.png` | 15 | Heron defeated | Heron verslagen |
| 18 | `beat:marlin` | `nl.evict.quadrim2.beat.marlin` | `marlin.png` | 15 | Marlin defeated | Marlin verslagen |
| 19 | `beat:lynx` | `nl.evict.quadrim2.beat.lynx` | `lynx.png` | 20 | Lynx defeated | Lynx verslagen |
| 20 | `beat:sable` | `nl.evict.quadrim2.beat.sable` | `sable.png` | 20 | Sable defeated | Sable verslagen |
| 21 | `beat:ember` | `nl.evict.quadrim2.beat.ember` | `ember.png` | 20 | Ember defeated | Ember verslagen |
| 22 | `beat:lyra` | `nl.evict.quadrim2.beat.lyra` | `lyra.png` | 20 | Lyra defeated | Lyra verslagen |
| 23 | `beat:onyx` | `nl.evict.quadrim2.beat.onyx` | `onyx.png` | 20 | Onyx defeated | Onyx verslagen |
| 24 | `beat:corvus` | `nl.evict.quadrim2.beat.corvus` | `corvus.png` | 20 | Corvus defeated | Corvus verslagen |
| 25 | `beat:basalt` | `nl.evict.quadrim2.beat.basalt` | `basalt.png` | 30 | Basalt defeated | Basalt verslagen |
| 26 | `beat:cairn` | `nl.evict.quadrim2.beat.cairn` | `cairn.png` | 30 | Cairn defeated | Cairn verslagen |
| 27 | `beat:flint` | `nl.evict.quadrim2.beat.flint` | `flint.png` | 30 | Flint defeated | Flint verslagen |
| 28 | `beat:quartz` | `nl.evict.quadrim2.beat.quartz` | `quartz.png` | 30 | Quartz defeated | Quartz verslagen |
| 29 | `beat:titan` | `nl.evict.quadrim2.beat.titan` | `titan.png` | 30 | Titan defeated | Titan verslagen |
| 30 | `beat:oracle` | `nl.evict.quadrim2.beat.oracle` | `oracle.png` | 30 | Oracle defeated | Oracle verslagen |
| 31 | `beat:quadrim_prime` | `nl.evict.quadrim2.beat.quadrim_prime` | `quadrim_prime.png` | 30 | Quadrim Prime defeated | Quadrim Prime verslagen |
| 32 | `games_in_day:5` | `nl.evict.quadrim2.games_in_day.5` | `streak-5.png` | 5 | Five in a day | Vijf op één dag |
| 33 | `games_in_day:10` | `nl.evict.quadrim2.games_in_day.10` | `streak-10.png` | 10 | Ten in a day | Tien op één dag |
| 34 | `games_in_day:20` | `nl.evict.quadrim2.games_in_day.20` | `streak-20.png` | 15 | Twenty in a day | Twintig op één dag |
| 35 | `games_in_day:50` | `nl.evict.quadrim2.games_in_day.50` | `streak-50.png` | 25 | Fifty in a day | Vijftig op één dag |
| 36 | `games_in_day:100` | `nl.evict.quadrim2.games_in_day.100` | `streak-100.png` | 40 | A hundred in a day | Honderd op één dag |
| 37 | `days_in_row:5` | `nl.evict.quadrim2.days_in_row.5` | `consecutive-5.png` | 5 | Five days running | Vijf dagen op rij |
| 38 | `days_in_row:10` | `nl.evict.quadrim2.days_in_row.10` | `consecutive-10.png` | 10 | Ten days running | Tien dagen op rij |
| 39 | `days_in_row:30` | `nl.evict.quadrim2.days_in_row.30` | `consecutive-30.png` | 15 | Thirty days running | Dertig dagen op rij |
| 40 | `days_in_row:90` | `nl.evict.quadrim2.days_in_row.90` | `consecutive-90.png` | 25 | Ninety days running | Negentig dagen op rij |
| 41 | `days_in_row:180` | `nl.evict.quadrim2.days_in_row.180` | `consecutive-180.png` | 40 | Half a year | Een half jaar |
| 42 | `days_in_row:360` | `nl.evict.quadrim2.days_in_row.360` | `consecutive-360.png` | 60 | A full year | Een heel jaar |
| 43 | `days_in_row:720` | `nl.evict.quadrim2.days_in_row.720` | `consecutive-720.png` | 90 | Two years | Twee jaar |
| 44 | `days_in_row:1440` | `nl.evict.quadrim2.days_in_row.1440` | `consecutive-1440.png  **MISSING**` | 130 | Four years | Vier jaar |

## Descriptions

Play takes one description per language; Game Center takes two, before and after
earning. Both are given so neither console needs invention.

| Quadrim key | Pre-earned (EN) | Earned (EN) | Pre-earned (NL) | Earned (NL) |
|---|---|---|---|---|
| `beat:pebble` | Win a game against Pebble. | You beat Pebble. | Win een partij tegen Pebble. | Je hebt Pebble verslagen. |
| `beat:twig` | Win a game against Twig. | You beat Twig. | Win een partij tegen Twig. | Je hebt Twig verslagen. |
| `beat:mote` | Win a game against Mote. | You beat Mote. | Win een partij tegen Mote. | Je hebt Mote verslagen. |
| `beat:hazel` | Win a game against Hazel. | You beat Hazel. | Win een partij tegen Hazel. | Je hebt Hazel verslagen. |
| `beat:clover` | Win a game against Clover. | You beat Clover. | Win een partij tegen Clover. | Je hebt Clover verslagen. |
| `beat:sorrel` | Win a game against Sorrel. | You beat Sorrel. | Win een partij tegen Sorrel. | Je hebt Sorrel verslagen. |
| `beat:bramble` | Win a game against Bramble. | You beat Bramble. | Win een partij tegen Bramble. | Je hebt Bramble verslagen. |
| `beat:juniper` | Win a game against Juniper. | You beat Juniper. | Win een partij tegen Juniper. | Je hebt Juniper verslagen. |
| `beat:bracken` | Win a game against Bracken. | You beat Bracken. | Win een partij tegen Bracken. | Je hebt Bracken verslagen. |
| `beat:willow` | Win a game against Willow. | You beat Willow. | Win een partij tegen Willow. | Je hebt Willow verslagen. |
| `beat:rowan` | Win a game against Rowan. | You beat Rowan. | Win een partij tegen Rowan. | Je hebt Rowan verslagen. |
| `beat:aspen` | Win a game against Aspen. | You beat Aspen. | Win een partij tegen Aspen. | Je hebt Aspen verslagen. |
| `beat:vireo` | Win a game against Vireo. | You beat Vireo. | Win een partij tegen Vireo. | Je hebt Vireo verslagen. |
| `beat:finch` | Win a game against Finch. | You beat Finch. | Win een partij tegen Finch. | Je hebt Finch verslagen. |
| `beat:kestrel` | Win a game against Kestrel. | You beat Kestrel. | Win een partij tegen Kestrel. | Je hebt Kestrel verslagen. |
| `beat:osprey` | Win a game against Osprey. | You beat Osprey. | Win een partij tegen Osprey. | Je hebt Osprey verslagen. |
| `beat:heron` | Win a game against Heron. | You beat Heron. | Win een partij tegen Heron. | Je hebt Heron verslagen. |
| `beat:marlin` | Win a game against Marlin. | You beat Marlin. | Win een partij tegen Marlin. | Je hebt Marlin verslagen. |
| `beat:lynx` | Win a game against Lynx. | You beat Lynx. | Win een partij tegen Lynx. | Je hebt Lynx verslagen. |
| `beat:sable` | Win a game against Sable. | You beat Sable. | Win een partij tegen Sable. | Je hebt Sable verslagen. |
| `beat:ember` | Win a game against Ember. | You beat Ember. | Win een partij tegen Ember. | Je hebt Ember verslagen. |
| `beat:lyra` | Win a game against Lyra. | You beat Lyra. | Win een partij tegen Lyra. | Je hebt Lyra verslagen. |
| `beat:onyx` | Win a game against Onyx. | You beat Onyx. | Win een partij tegen Onyx. | Je hebt Onyx verslagen. |
| `beat:corvus` | Win a game against Corvus. | You beat Corvus. | Win een partij tegen Corvus. | Je hebt Corvus verslagen. |
| `beat:basalt` | Win a game against Basalt. | You beat Basalt. | Win een partij tegen Basalt. | Je hebt Basalt verslagen. |
| `beat:cairn` | Win a game against Cairn. | You beat Cairn. | Win een partij tegen Cairn. | Je hebt Cairn verslagen. |
| `beat:flint` | Win a game against Flint. | You beat Flint. | Win een partij tegen Flint. | Je hebt Flint verslagen. |
| `beat:quartz` | Win a game against Quartz. | You beat Quartz. | Win een partij tegen Quartz. | Je hebt Quartz verslagen. |
| `beat:titan` | Win a game against Titan. | You beat Titan. | Win een partij tegen Titan. | Je hebt Titan verslagen. |
| `beat:oracle` | Win a game against Oracle. | You beat Oracle. | Win een partij tegen Oracle. | Je hebt Oracle verslagen. |
| `beat:quadrim_prime` | Win a game against Quadrim Prime. | You beat Quadrim Prime. | Win een partij tegen Quadrim Prime. | Je hebt Quadrim Prime verslagen. |
| `games_in_day:5` | Finish 5 games in a single day. | You finished 5 games in a day. | Speel 5 partijen op één dag uit. | Je hebt 5 partijen op één dag gespeeld. |
| `games_in_day:10` | Finish 10 games in a single day. | You finished 10 games in a day. | Speel 10 partijen op één dag uit. | Je hebt 10 partijen op één dag gespeeld. |
| `games_in_day:20` | Finish 20 games in a single day. | You finished 20 games in a day. | Speel 20 partijen op één dag uit. | Je hebt 20 partijen op één dag gespeeld. |
| `games_in_day:50` | Finish 50 games in a single day. | You finished 50 games in a day. | Speel 50 partijen op één dag uit. | Je hebt 50 partijen op één dag gespeeld. |
| `games_in_day:100` | Finish 100 games in a single day. | You finished 100 games in a day. | Speel 100 partijen op één dag uit. | Je hebt 100 partijen op één dag gespeeld. |
| `days_in_row:5` | Play on 5 consecutive days. | You played 5 days in a row. | Speel 5 dagen achter elkaar. | Je hebt 5 dagen op rij gespeeld. |
| `days_in_row:10` | Play on 10 consecutive days. | You played 10 days in a row. | Speel 10 dagen achter elkaar. | Je hebt 10 dagen op rij gespeeld. |
| `days_in_row:30` | Play on 30 consecutive days. | You played 30 days in a row. | Speel 30 dagen achter elkaar. | Je hebt 30 dagen op rij gespeeld. |
| `days_in_row:90` | Play on 90 consecutive days. | You played 90 days in a row. | Speel 90 dagen achter elkaar. | Je hebt 90 dagen op rij gespeeld. |
| `days_in_row:180` | Play on 180 consecutive days. | You played 180 days in a row. | Speel 180 dagen achter elkaar. | Je hebt 180 dagen op rij gespeeld. |
| `days_in_row:360` | Play on 360 consecutive days. | You played 360 days in a row. | Speel 360 dagen achter elkaar. | Je hebt 360 dagen op rij gespeeld. |
| `days_in_row:720` | Play on 720 consecutive days. | You played 720 days in a row. | Speel 720 dagen achter elkaar. | Je hebt 720 dagen op rij gespeeld. |
| `days_in_row:1440` | Play on 1440 consecutive days. | You played 1440 days in a row. | Speel 1440 dagen achter elkaar. | Je hebt 1440 dagen op rij gespeeld. |

---

## Afterwards: paste the ids back

Play Games issues its own achievement and leaderboard ids. Until they are in the
code, **Android stays silent by design** — `playGamesConfigured` is false and
`GameServices` refuses to report anything, which is what stops an `UNSET`
sentinel reaching Google Play services.

In `app/lib/services/achievements.dart`:

1. Replace `kRatingLeaderboardPlayGamesId` with the leaderboard id.
2. Replace each `playGamesId: kPlayGamesIdUnset`. The catalogue is built with
   three `for` loops, so this wants a `Map<String, String>` from Quadrim key to
   Play id, read where `kPlayGamesIdUnset` currently sits — the smallest change
   that keeps the catalogue derived rather than typed out.
3. `game_services_test.dart` asserts `playGamesConfigured` is **false**. It will
   fail the moment steps 1 and 2 are done, which is deliberate: flip it to
   `isTrue` in the same commit.

Then update the two privacy declarations in the same release (ticket 050 AC 10).
Play **Data Safety** and the App Store **privacy labels** both currently say the
app collects nothing, and a leaderboard entry makes that false.
