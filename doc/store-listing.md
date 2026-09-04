# Store listing copy and privacy policy

Draft copy for App Store Connect in both listing languages (ticket 049 §1),
followed by the privacy policy both stores require.

**The listing copy is Apple's, not Play's.** It names the Apple Account, states
Apple's renewal terms, and carries the Terms of Use link Apple demands and
Google does not. A Play listing reuses the first two thirds and needs those
three things rewritten — do not paste it across.

**Not yet submitted, and several things in it are placeholders** — read the notes
at the end before pasting any of this into a console or onto a website.

Everything here is written to be *true*, which ticket 049 asks for explicitly: a
listing is a set of claims, and a wrong one is a rejection at best.

---

## In-app purchase metadata — App Store Connect

**This section exists because its absence caused a rejection.** Guideline 2.3.2,
2026-08-30: *"the display names and descriptions for your promoted In-App
Purchase products … are the same, which makes it hard for users to identify what
they are purchasing."* The two products had been named directly in App Store
Connect, nowhere else, and both ended in "computer opponents".

Nothing in the app was wrong: `shopUnlockAllName` and `shopUnlimitedName` have
always read "Unlock all opponents" and "Unlimited play", and the StoreKit
configuration matched. **The colliding strings existed only in a web form**,
which is exactly why they are written down here now — copy that lives in one
console and nowhere else is copy nobody can review.

**Apple's limits: display name 30 characters, description 45.** Both are per
locale, and both are editable after publication (unlike the product id, D213,
D365). Paste these into App Store Connect → Monetization → In-App Purchases →
each product → the English and Dutch localisations.

### `nl.evict.quadrim2.unlock_all` — one-time, €4.99

| | Display name | Description |
|---|---|---|
| English | `Unlock every opponent` | `The whole ladder, unlocked right away.` |
| Dutch | `Elke tegenstander vrij` | `De hele ladder, meteen vrijgespeeld.` |

### `nl.evict.quadrim2.unlimited` — subscription, €2.99/year

| | Display name | Description |
|---|---|---|
| English | `Unlimited daily games` | `Play more than three games a day, all year.` |
| Dutch | `Onbeperkt per dag` | `Speel meer dan drie partijen per dag.` |

**The two products now share no word at all**, in either language, in either
field — which is a stronger property than "not identical" and is the one worth
keeping. They also say different *kinds* of thing, which is what the guideline is
actually about: one is about **which opponents** you may play, the other about
**how often** you may play. A reviewer scanning the two should not have to read
carefully to tell them apart.

### The app's shop screen says the same words

`shopUnlockAllName` and `shopUnlimitedName` now read exactly as the display
names above, and the bodies open with the store descriptions. A buyer who taps
a promoted purchase on the App Store lands on a shop screen carrying the
sentence they just tapped — which is what guideline 2.3.2 is protecting, and it
cannot be checked from inside App Store Connect alone.

### If it is rejected again: unpromote the products

The guideline applies to **promoted** in-app purchases — the ones with a
promotional image, shown on the App Store product page. Apple's own second
notice offers the exit: *"If you have no future plans on promoting this In-App
Purchase product, you can delete the associated promotional image."* Deleting
the two promotional images removes the products from App Store promotion, and
the whole check stops applying. Promotion is a growth feature for an app that
already has traffic; 0.1.3 has none, so it costs nothing.

**Do not describe the unlock as lifting the cap.** It does not (§4.1) — a buyer
still plays three a day unless they also subscribe, and `shopUnlockAllCaveat`
says so in the app. A description that blurred the two would be a worse failure
of the same guideline.

---

## Listing copy — English

### Promotional text

*Max 170 characters. Editable without shipping a build, which makes it the place for anything seasonal.*

```
Four in a row, but the board is a cube. Thirty-one opponents, from one that barely spots a threat to one that cannot be beaten.
```

### Keywords

*Max 100 characters including the commas. No space after a comma — it costs a character and buys nothing. Single words rather than phrases, because Apple combines them for you.*

```
3d,cube,four,row,qubic,tic,tac,toe,strategy,board,offline,solo,tactics,brain,logic,elo
```

### Description

*Max 4000 characters. Only the first three lines show before "more", so the hook has to survive on its own.*

```
Four in a row, but the board is a cube.

Sixteen squares become sixty-four cells, and the lines run in directions a flat board never had: across, upward, and straight through the diagonals of the cube. Seventy-six ways to win, and most of them are hard to see until somebody has already used one on you.

THIRTY-ONE OPPONENTS
A ladder that starts with a creature which barely notices a threat and ends with one that plays the game perfectly. Each has a rating, a face and a temperament of its own. Beat one and the next is waiting.

The opponent at the top cannot be beaten when it moves first. That is not a boast: four in a row on a 4x4x4 board is a solved game, and it plays from the solution.

FIND YOUR LEVEL
Your own rating moves with every result, the way a chess rating does. A ten-game trend, a win-loss record against each opponent, and a path that opens up as you earn it.

QUESTS AND STREAKS
Small goals that give a session a shape: a first win against someone new, a first win playing second, ten games in a day, a run of days in a row.

PASS AND PLAY
Hand the phone across. No account, no opponent search, no waiting for anyone.

LEARN IT PROPERLY
A tutorial that teaches the lines rather than the buttons, followed by a practice game against a gentle opponent.

PLAYS ANYWHERE
The games, the opponents and the ratings all run on your device. No connection is needed to play, so a tunnel or a plane changes nothing.

WHAT IS FREE
The first month is unlimited. After that you can start three games a day and nine a week against the computer, free, for as long as you like. Pass and play, the tutorial, and finishing a game you have already started are never limited.

TWO OPTIONAL PURCHASES
- Unlimited play: €2.99 per year, auto-renewing. Lifts the daily and weekly limits on computer games. It does not unlock opponents.
- Unlock all opponents: €4.99, one payment. Every opponent straight away instead of earning them with points. It does not change how many games you can start.

Prices are shown in euros. Outside the euro area the store charges the equivalent in your own currency.

Payment is charged to your Apple Account at confirmation. A subscription renews automatically unless it is turned off at least 24 hours before the period ends, and you can manage or cancel it in your Apple Account settings.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy policy: https://evict.nl/quadrim/quadrim-privacy-policy

PRIVACY
No accounts, no advertising, no analytics, no tracking, and nothing collected about you. Your games are kept on your device and are included in your device's own iCloud backup, to your own account.

Perfect play at the top of the ladder comes from Oren Patashnik's Qubic strategy dictionary (1980), used with permission and with the moves unchanged.

Available in English and Dutch.
```

---

## Listing copy — Nederlands

### Promotietekst

```
Vier op een rij, maar het bord is een kubus. Eenendertig tegenstanders, van amper oplettend tot niet te verslaan.
```

### Trefwoorden

```
3d,kubus,vier,rij,qubic,boter,kaas,eieren,strategie,bord,offline,solo,tactiek,brein,logica
```

### Beschrijving

```
Vier op een rij, maar het bord is een kubus.

Zestien vakjes worden vierenzestig cellen, en de lijnen lopen in richtingen die een plat bord niet kent: opzij, omhoog, en dwars door de diagonalen van de kubus. Zesenzeventig manieren om te winnen, en de meeste zie je pas als iemand er een tegen jou heeft gebruikt.

EENENDERTIG TEGENSTANDERS
Een ladder die begint bij een wezen dat een dreiging amper opmerkt en eindigt bij een dat het spel perfect speelt. Elk heeft een eigen rating, een eigen gezicht en een eigen karakter. Versla er een en de volgende staat klaar.

De tegenstander bovenaan is niet te verslaan als hij begint. Dat is geen grootspraak: vier op een rij op een 4x4x4-bord is een opgelost spel, en hij speelt uit de oplossing.

VIND JE NIVEAU
Je eigen rating beweegt mee met elke uitslag, zoals een schaakrating dat doet. Een trend over tien partijen, een winst-verliesbalans per tegenstander, en een pad dat opengaat naarmate je het verdient.

OPDRACHTEN EN REEKSEN
Kleine doelen die een speelsessie vorm geven: een eerste winst tegen iemand nieuw, een eerste winst als tweede speler, tien partijen op een dag, een reeks dagen achter elkaar.

SAMEN OP EEN TOESTEL
Geef de telefoon door. Geen account, geen zoeken naar een tegenstander, geen wachten.

LEER HET GOED
Een uitleg die de lijnen leert in plaats van de knoppen, gevolgd door een oefenpartij tegen een milde tegenstander.

SPEELT OVERAL
De partijen, de tegenstanders en de ratings draaien allemaal op je toestel. Je hebt geen verbinding nodig om te spelen, dus een tunnel of een vliegtuig maakt niets uit.

WAT GRATIS IS
De eerste maand is onbeperkt. Daarna start je drie partijen per dag en negen per week tegen de computer, gratis, zolang je wilt. Samen op een toestel spelen, de uitleg, en een partij afmaken die je al begonnen bent worden nooit beperkt.

TWEE OPTIONELE AANKOPEN
- Onbeperkt spelen: € 2,99 per jaar, met automatische verlenging. Haalt de dag- en weeklimiet voor computerpartijen weg. Het speelt geen tegenstanders vrij.
- Alle tegenstanders vrijspelen: € 4,99, eenmalig. Meteen alle tegenstanders in plaats van ze met punten te verdienen. Het verandert niets aan hoeveel partijen je kunt starten.

De prijzen staan in euro's. Buiten de eurozone rekent de winkel het bedrag in je eigen valuta.

De betaling wordt bij bevestiging van je Apple Account afgeschreven. Een abonnement verlengt automatisch, tenzij het minstens 24 uur voor het einde van de periode wordt uitgezet; je beheert of stopt het in de instellingen van je Apple Account.

Gebruiksvoorwaarden (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacyverklaring: https://evict.nl/quadrim/quadrim-privacy-policy

PRIVACY
Geen accounts, geen advertenties, geen analytics, geen tracking, en niets wat over jou wordt verzameld. Je partijen staan op je toestel en gaan mee in de iCloud-back-up van je toestel zelf, naar je eigen account.

Het perfecte spel bovenaan de ladder komt uit Oren Patashniks Qubic-strategiewoordenboek (1980), gebruikt met toestemming en met de zetten ongewijzigd.

Beschikbaar in het Nederlands en het Engels.
```

---

---

## Privacy policy

Publish this at a stable public URL, give that URL to Google Play and to App
Store Connect, and keep the two identical — a store listing that disagrees with
the page it links to is a rejection.

**Every factual claim below was checked against the code**, not against
intention; the notes under [What this policy rests on](#what-this-policy-rests-on)
say which file settles which sentence and which ones the build enforces
mechanically. If any of them stops being true, this page is wrong the same day.

**Last updated: 25 August 2026**

## Privacy policy — English

### Privacy policy for Quadrim

Quadrim has no accounts, no advertising, no analytics and no tracking. It never
asks who you are and has no way of finding out. Everything it records — your
games, your settings, the opponents you have unlocked — is written to your own
device.

#### What Quadrim stores on your device

- **Your games.** The moves played, which opponent it was against, which side
  you took, when the game started and finished, and how it ended.
- **Opponents you have unlocked with points.** Which opponent, when, and what it
  cost at the time.
- **Your settings.** Language, light or dark theme, whether you have been
  through the tutorial, and the date this installation first ran — the last of
  these is what the free first month is measured from.

That is the complete list. None of it contains a name, an email address, a
location, a phone number or a device identifier.

#### What Quadrim does not collect

- **No account and no sign-in.** No name, no email address, no password.
- **No device identifier of any kind.** None is generated, none is stored, and
  none is transmitted.
- **No advertising.** No ads, no advertising identifier, no ad networks.
- **No analytics and no crash reporting.** No usage statistics, no event
  logging, no third-party measurement.
- **No access to your location, contacts, photos, camera, microphone, or any
  file outside the game's own storage.**

#### Backups

Backup is deliberately switched **on**. If you have Android backup or iCloud
backup enabled on your device, Quadrim's files are included in it, so replacing
your phone keeps your history and your unlocked opponents.

That copy goes to **your own** Google or Apple account and is governed by that
account's terms, not by this policy. It does not come to me and I cannot read
it. On Android the backup is limited to an explicit list — only the game's own
documents, never anything else the app might hold — and on Android 9 and later
it is end-to-end encrypted with your device credential.

This is also why this policy does not tell you that no data leaves your device.
Backup is on, so that would not be true, and a privacy promise that is not true
is worse than none.

#### The internet

**Playing Quadrim makes no network request.** Not against the computer, not
against someone on the same phone, not to look anything up. On Android this is
enforced by the operating system rather than asked of your trust: the app is
built without the `INTERNET` permission, so it cannot open a network connection
at all. The permissions it does declare cover the billing flow and reading
whether a connection exists; none of them permits opening one.

Purchases are the one thing that needs a network, and they do not go through the
app. They are handled by the Google Play Store app on Android and by Apple's
StoreKit on iOS, both of which run outside Quadrim.

#### Purchases

Quadrim offers two optional purchases: unlocking all opponents at once, and an
annual subscription that lifts the daily and weekly limits on games against the
computer. Neither is required to play.

Payment is handled entirely by Google or by Apple. **I never see your card, your
billing address or your store account.** What reaches me is what the stores
report to every developer: sales and payout totals, and the country a sale was
made in. It does not identify you.

Quadrim does not store a receipt or a purchase token. What you own is asked of
the store each time the app starts, which is also why reinstalling the app or
moving to a new phone restores your purchases without anything having been kept
on the old one.

#### Children

Quadrim is a board game and is suitable for any age. Because it collects nothing
about anybody, there is nothing it treats differently on a child's device: there
is no profile to build, no advertising to target and no data to share.

#### Keeping and deleting your data

Your games and settings stay on your device until you remove them. Uninstalling
Quadrim deletes them, as does clearing the app's data from your system settings.
There is no copy on a server for me to delete, because there is no server.

If you have device backup switched on, a copy may remain in your own Google or
Apple backup until that backup expires or you delete it from your account. Your
purchases are held by the store rather than by the game, so they survive an
uninstall and can be restored.

#### Your rights

Data-protection law gives you the right to see, correct, export and erase
personal data that an organisation holds about you. **I hold none**, so there is
nothing on my side to act on — Quadrim never sends me any. For the purchase and
payment records that Google or Apple hold, use the privacy tools in your Google
or Apple account.

#### Changes to this policy

If a future version of Quadrim collects or transmits anything, this page will be
rewritten before that version is released, and the date at the top will change.

#### Contact

Edwin Vermeer
info@evict.nl
De Langer Ring 12, Anna Paulowna, 1761 JG, Netherlands

---

## Privacy policy — Nederlands

### Privacyverklaring voor Quadrim

Quadrim heeft geen accounts, geen advertenties, geen analytics en geen tracking.
De app vraagt nooit wie je bent en kan daar ook niet achter komen. Alles wat
wordt vastgelegd — je partijen, je instellingen, de tegenstanders die je hebt
vrijgespeeld — wordt op je eigen toestel opgeslagen.

#### Wat Quadrim op je toestel bewaart

- **Je partijen.** De gespeelde zetten, tegen welke tegenstander, met welke
  kleur je speelde, wanneer de partij begon en eindigde, en hoe die afliep.
- **Tegenstanders die je met punten hebt vrijgespeeld.** Welke tegenstander,
  wanneer, en wat het op dat moment kostte.
- **Je instellingen.** Taal, licht of donker thema, of je de uitleg hebt gehad,
  en de datum waarop deze installatie voor het eerst startte — dat laatste is
  waar de gratis eerste maand vanaf loopt.

Dat is de volledige lijst. Er zit geen naam in, geen e-mailadres, geen locatie,
geen telefoonnummer en geen apparaat-identificatie.

#### Wat Quadrim niet verzamelt

- **Geen account en geen inloggen.** Geen naam, geen e-mailadres, geen
  wachtwoord.
- **Geen enkele apparaat-identificatie.** Die wordt niet aangemaakt, niet
  opgeslagen en niet verstuurd.
- **Geen advertenties.** Geen reclame, geen advertentie-id, geen advertentie-
  netwerken.
- **Geen analytics en geen crashrapportage.** Geen gebruiksstatistieken, geen
  gebeurtenissenlogboek, geen metingen door derden.
- **Geen toegang tot je locatie, contacten, foto's, camera, microfoon of
  bestanden buiten de eigen opslag van het spel.**

#### Back-ups

Back-up staat bewust **aan**. Als je op je toestel Android-back-up of
iCloud-back-up hebt ingeschakeld, gaan de bestanden van Quadrim daarin mee.
Daardoor houd je je geschiedenis en je vrijgespeelde tegenstanders wanneer je
van telefoon wisselt.

Die kopie gaat naar **je eigen** Google- of Apple-account en valt onder de
voorwaarden van dat account, niet onder deze verklaring. Hij komt niet bij mij
terecht en ik kan hem niet lezen. Op Android is de back-up beperkt tot een
uitdrukkelijke lijst — alleen de eigen documenten van het spel — en vanaf
Android 9 is hij end-to-end versleuteld met de toegangscode van je toestel.

Dit is ook de reden dat deze verklaring niet zegt dat er geen gegevens van je
toestel af gaan. Back-up staat aan, dus dat zou niet waar zijn, en een
privacybelofte die niet klopt is slechter dan geen belofte.

#### Internet

**Quadrim spelen doet geen enkel netwerkverzoek.** Niet tegen de computer, niet
tegen iemand op dezelfde telefoon, en niet om iets op te zoeken. Op Android
wordt dat door het besturingssysteem afgedwongen en niet aan je vertrouwen
overgelaten: de app wordt gebouwd zonder de `INTERNET`-toestemming en kan dus
helemaal geen netwerkverbinding openen. De toestemmingen die er wel zijn gaan
over de betaalafhandeling en over het lezen of er een verbinding bestaat; met
geen ervan kan er een geopend worden.

Aankopen zijn het enige waarvoor een netwerk nodig is, en die lopen niet via de
app. Ze worden afgehandeld door de Google Play Store-app op Android en door
StoreKit van Apple op iOS; die draaien allebei buiten Quadrim.

#### Aankopen

Quadrim heeft twee optionele aankopen: alle tegenstanders in één keer
vrijspelen, en een jaarabonnement dat de dag- en weeklimiet voor partijen tegen
de computer opheft. Geen van beide is nodig om te spelen.

De betaling wordt volledig door Google of Apple afgehandeld. **Ik zie je pas,
je factuuradres of je winkelaccount nooit.** Wat bij mij terechtkomt is wat de
winkels aan iedere ontwikkelaar rapporteren: verkoop- en uitbetalingstotalen en
het land waarin een verkoop plaatsvond. Dat wijst niet naar jou.

Quadrim bewaart geen bon en geen aankoopbewijs. Wat je bezit wordt bij elke
start aan de winkel gevraagd. Dat is ook waarom je aankopen terugkomen als je de
app opnieuw installeert of naar een nieuwe telefoon gaat, zonder dat er iets op
de oude bewaard is gebleven.

#### Kinderen

Quadrim is een bordspel en is geschikt voor elke leeftijd. Omdat er over
niemand iets wordt verzameld, gaat er op het toestel van een kind niets anders:
er is geen profiel op te bouwen, geen reclame om op te richten en geen gegeven
om te delen.

#### Bewaren en verwijderen

Je partijen en instellingen blijven op je toestel staan tot je ze weghaalt.
Quadrim verwijderen wist ze, en de appgegevens wissen via je systeeminstellingen
ook. Er is geen kopie op een server die ik kan verwijderen, want er is geen
server.

Als back-up aanstaat, kan er een kopie in je eigen Google- of Apple-back-up
achterblijven tot die verloopt of je hem uit je account verwijdert. Je aankopen
staan bij de winkel en niet bij het spel, dus die overleven het verwijderen van
de app en kun je herstellen.

#### Je rechten

De privacywetgeving geeft je het recht om persoonsgegevens die een organisatie
over je heeft in te zien, te corrigeren, mee te nemen en te laten wissen. **Ik
heb er geen**, dus er is aan mijn kant niets om op te handelen — Quadrim stuurt
mij nooit iets. Voor de aankoop- en betaalgegevens die Google of Apple bewaren,
gebruik je de privacyfuncties in je Google- of Apple-account.

#### Wijzigingen in deze verklaring

Als een toekomstige versie van Quadrim iets verzamelt of verstuurt, wordt deze
pagina herschreven vóórdat die versie uitkomt, en verandert de datum bovenaan.

#### Contact

Edwin Vermeer
info@evict.nl
De Langer Ring 12, Anna Paulowna, 1761 JG, Netherlands


---

## What this policy rests on

Each claim above, and the thing that makes it true. This is the list to re-check
before any release that touches storage, permissions or dependencies.

| Claim | What settles it |
|---|---|
| No device identifier, anywhere | D90, and `check.sh` greps for it |
| Playing makes no network call | D93; on Android the merged release manifest carries no `INTERNET` permission, stripped with `tools:node="remove"` and checked by `check.sh` (D212, D356, D357) |
| No analytics, ads or crash reporting | `app/pubspec.yaml` — the only non-Flutter, non-local dependency is `in_app_purchase` |
| The exact list of what is stored | `app/lib/data/documents.dart` — `GameDocument`, `UnlockDocument`, `SettingsDocument` and nothing else |
| Backup is an explicit allowlist | `backup_rules.xml` and `data_extraction_rules.xml`, both limited to `quadrim/` (D72, spec §9.12) |
| No receipt or purchase token is kept | `app/lib/shop/shop.dart` — entitlement is restored from the store at every launch and *"nothing about it is stored"* |
| No tracking on iOS | `app/ios/Runner/PrivacyInfo.xcprivacy` — `NSPrivacyTracking` false, `NSPrivacyCollectedDataTypes` empty |

**"No data leaves the device" must never appear here**, in any wording, in
either language. Backup is enabled, so it is false (D72, ticket 022). The
backup section says the true thing instead, and says why.

**This stops being accurate at 0.3a.** Accounts and Firebase turn several of
these claims false at once — the identifier claim, the network claim, the
"there is no server" claim and the rights section. Rewrite this page in the same
ticket that adds them, not afterwards.

---

## Before this is submitted

**The prices are set: €4.99 to unlock all opponents, €2.99 a year for
unlimited play, chosen 2026-08-27.** They appear in the description because
Apple's guideline 3.1.2 requires the price in the metadata, and the euro figures
are the base from which each store derives its own per-country price. The line
about local currency is there because the English description is read in
countries that do not use euros, where a bare euro figure would be wrong rather
than merely unhelpful.

**Two things about those prices are still open**, and neither blocks a
submission: per-country tax treatment (both stores act as merchant of record in
most territories and handle VAT, but that is a fact to confirm rather than to
assume), and whether the description should carry the price at all on Play,
which has no equivalent of 3.1.2.

**`qubic` as a keyword needs a decision.** It is the name the game is publicly
known by and the word people search for, which is exactly why it earns its
place. It was also a Parker Brothers product name. The strategy dictionary is
used with permission and credited (D172, D174), which covers the dictionary and
says nothing about the word. **Check it against the trademark registers in the
same pass as the app-name check that ticket 015 still has open**, and drop it
from both keyword lists if that goes the wrong way. Nothing else in the copy
depends on it.

**Nothing here claims VoiceOver support**, deliberately. Ticket 021 records the
screen-reader play-through as needing a real device and not yet done. It is very
likely fine — the semantics work is in and tested — but "supports VoiceOver" is
a claim a reviewer can verify in a minute, and an accessibility claim that fails
is worse than no claim at all. Add the line once 021's device pass is signed off.

**The privacy paragraph is worded around D72 and must stay that way.** It says
the games are on the device and go into *the device's own* iCloud backup, to the
player's own account. It does not say "no data leaves your device", which is
false while backup is enabled and is forbidden everywhere in this project.

**"No connection is needed to play" is scoped to play, not to the app.**
Purchases go through StoreKit and StoreKit is online. The Android build enforces
the offline claim with the absent `INTERNET` permission (D357); iOS has no
equivalent mechanism, so there the claim rests on the code both platforms share
(D306).

**The two link lines at the foot of the description are what a rejection bought,
and deleting them buys it again.** Apple refused 0.1.2 under guideline 3.1.2:
*"offers auto-renewable subscriptions but does not include a functional link to
the Terms of Use (EULA) in the app metadata that appears on the app's App Store
product page."* The App Description is that metadata — the long description on
the product page, not the privacy-policy field and nothing in the binary.

The link is to **Apple's standard EULA**, which is the cheaper of the two routes
Apple offers: link the standard one from the description, or write a custom one
and paste it into App Store Connect under App Information → License Agreement. A
custom EULA is a document to keep correct in two languages forever, in exchange
for terms this game has no need to vary. The URL was checked and returns 200:
`https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`, titled
*Licensed Application End User License Agreement*. **Functional** is the word the
rejection used, so re-check it rather than assume it.

**The same guideline wants the price, and it is now in the description.** 3.1.2
asks the metadata for the subscription's title, length and price together with
those links; all three are present, and so is the privacy policy URL. What is
still a placeholder is the contact block in the privacy policy itself, which
that guideline does not reach.

**Nothing in the app links to either document, and that is the likely second
round.** The shop screen shows each product's name, "Yearly, cancel any time",
and the store's own localised price, which covers title, length and price; it
has no Terms of Use or privacy link, and `grep -ri privacy app/lib` is still
empty. Reviewers routinely ask for both on the purchase screen itself. Ticket
028's settings screen and the shop screen are where they belong, and they need
l10n strings like everything else (D297).

**The privacy policy's three placeholders are a deliberate stop.** Publishing a
contact name, address and email is a decision about which identity and which
address of yours becomes permanently public, and it is not a detail to be filled
in by whoever pastes the page. The EU's trader and DSA requirements bear on the
same three fields and are still open in ticket 015, so fill them once, there,
and paste the result into both languages.

**Play and Apple both want the same facts twice.** The policy is one of them;
the structured form is the other, and a mismatch between them is a rejection
rather than a note. Play's **Data safety** form should say no data collected and
no data shared, and — because there is nothing collected — the encryption and
deletion questions follow from that rather than being answered independently.
Apple's **App Privacy** questionnaire should say the same, and already has its
machine-readable twin in `PrivacyInfo.xcprivacy`, which declares no tracking and
an empty collected-data list. Answer the forms from the table above, not from
memory.

**The policy needs a URL before either store will take it, and nothing links to
it from inside the app.** There is no privacy string in `app/lib` at all —
`grep -ri privacy app/lib` returns nothing. Both stores accept a listing-only
link, so this is not a blocker, but the settings screen is where it belongs and
ticket 028 is where it should land.

**This is not legal advice.** It is an accurate description of what the software
does, written from the code. Whether that description discharges your
obligations under the GDPR, the UK GDPR, the CCPA or the DSA is a separate
question, and the answer depends on facts about you rather than about the app.

**Still to write for the same listing:** the app name and subtitle (30
characters), the what's-new text, and screenshots taken from the real app on a
real device — `doc/designs/` is pipeline source art, not marketing material, and
a screenshot of something the app does not do is a rejection.
