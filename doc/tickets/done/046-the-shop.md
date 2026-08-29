# Ticket 046 — The shop: products, purchase and entitlement

**Depends on:** 041 (an iOS project to test on), 015 (store accounts and the
products created in each console)

**Status:** **done.** The products exist, the shop is working, and purchases
have been tested against a real store — the condition this ticket was held open
for. AC 4, 5 and 6 describe events that cannot be made to happen on demand (an
interruption, a lapse, a refund); they are covered by test here and carried into
022 as things to watch in the wild rather than pretended into a tick. See the
amendment at the end.

## Why

Two things are for sale (§4.1):

| Product | Type | Price |
|---|---|---|
| Unlock all opponents | non-consumable / one-time | $4.99 |
| Unlimited play (tier 2) | auto-renewing subscription, yearly | $1.99 |

The subscription is created now **as one product with one base plan inside a
group**, even though only one plan exists at 1.0. 3.0 adds tier 3 as a second
plan in the same group, and that is the only mechanism by which upgrading
cancels the lower tier — the store performs a plan change and prorates. A
group cannot be retro-fitted around a product that already has subscribers, and
getting it wrong produces double-billed users and a refund queue (D223).

## What it does

### 1. Product identifiers, chosen once

Product ids **cannot be reused after deletion** on either store, which puts
them in the same category as the application id: cheap to choose carefully now,
impossible to change later.

```
nl.evict.quadrim2.unlock_all          non-consumable / one-time
nl.evict.quadrim2.unlimited           subscription, yearly base plan
```

The subscription id carries no tier number and no "tier2", because 3.0 adds a
*plan* to this product rather than a second product, and an id that says
"tier 2" would then name a group containing tier 3.

### 2. `in_app_purchase`

Flutter's official plugin, one API over StoreKit and Play Billing. Chosen over
RevenueCat, which would have given server-side validation without a server of
ours — and would have assigned an anonymous app user id and sent purchase data
to a third party, which presses directly on "no device identifier, in any
release" (D307).

The plugin goes in `app/`, never in a package: `quadrim_engine`,
`quadrim_rating` and `quadrim_progression` declare no runtime dependencies at
all and `check.sh` enforces it.

### 3. Entitlement

**At 1.0 the store's own signed transaction is the authority, read on the
device** (D303). There is no server. What that gives:

- It survives a reinstall, because the store re-issues it to the same store
  account. **This is why the unlock is safe to sell before there is a backend**
  and the free month is not.
- Refund and chargeback revocation follows the store's next refresh rather than
  being immediate.

What it must do:

- **Restore is a visible action**, not only an automatic one. Apple requires it
  and a player who reinstalls needs it. It belongs in settings.
- **A purchased unlock is stored with `source` distinguishing it from points**
  (§8.8), so that a refund can revoke exactly what was bought and nothing the
  player earned.
- **An unlock is never revoked by a billing event.** Not on lapse, not on
  refund of the *subscription*. Only a refund of the unlock purchase itself
  touches unlocks, and only the ones it paid for (§4.1).
- **The pending-purchase path must complete.** A purchase interrupted by a
  crash, a lost connection or an "Ask to Buy" approval arrives later; the
  plugin delivers it on the next stream event and it must be completed or the
  store retries forever.

### 4. What this ticket does not do

No paywall, no purchase screen, no meter enforcement. 047 is all of that. This
ticket ends with products that can be bought and an entitlement the rest of the
app can ask about.

## Acceptance criteria

1. Both products exist in App Store Connect and — when the account allows — in
   Play Console, with the subscription inside a group holding one base plan.
2. A sandbox purchase of each product completes and the entitlement is
   readable afterwards.
3. **A reinstall restores both**, via the explicit restore action and without
   re-paying.
4. An interrupted purchase completes on the next launch rather than being lost
   or retried forever.
5. A lapsed subscription leaves every unlock intact.
6. A refund of the subscription leaves every unlock intact; a refund of the
   unlock purchase revokes only what it bought.
7. Purchased unlocks are stored with `source` set so points-earned and
   bought-outright are distinguishable.
8. No package outside `app/` gains a dependency; `check.sh`'s purity scan
   passes.
9. `bash tool/check.sh` passes.

## Notes for whoever picks this up

**A StoreKit Configuration file in Xcode lets you test purchases with no App
Store Connect products at all**, against a local definition. Use it for the
first pass — it turns a round trip through a web console into an edit — and
then re-test against real sandbox products, because the two do not behave
identically on restore.

**Sandbox purchases need a Sandbox Apple Account**, created in App Store
Connect and signed in on the device under Settings → Developer → Sandbox Apple
Account. Do not sign into the *device's* main App Store account with it.

**Subscription durations are compressed in sandbox** — a year renews in
minutes — which is the only practical way to test a lapse. Note the mapping in
the closure so the next person does not wait for a real year.

**The Android half can be written but not verified** until the Play account
returns. Write it, test what can be tested against the plugin's own fakes, and
record explicitly in the closure that the Play path is unverified — a
half-tested purchase flow that is described as done is how money goes missing.

## Closure

**Partially complete, and the incomplete half is named rather than implied.**
Everything that can be built and tested without a store console is done and
under test. Nothing has been bought — not in sandbox, not against a StoreKit
configuration — so **AC 2 through 6 are unverified**, and a half-tested purchase
flow described as done is how money goes missing, which this ticket says itself.

`bash tool/check.sh`: **ALL CHECKS PASSED**, 357 app tests (was 341).

### What exists

`app/lib/shop/` is the whole of it, and nothing outside `app/` gained a
dependency — the purity scan still passes, so AC 8 is met.

- **`products.dart`** — the two ids, fixed forever, and `Entitlement`.
- **`shop.dart`** — `PurchasePlatform`, an interface this app owns over
  `InAppPurchase`, its real adapter, and `Shop`. The interface exists so the
  part that can lose money is testable without a store in the room.
- **`Quadrim.storekit`** — a StoreKit configuration with both products, the
  subscription inside a group holding one base plan, so a purchase can be
  exercised in Xcode with no App Store Connect products at all.

Three design decisions the ticket left open, all recorded: the unlock is
**materialised into `UnlockDocument`s** at `UnlockSource.purchase` rather than
held as a flag, because AC 6 and AC 7 are questions about records (D348);
entitlement is **rebuilt each launch and never persisted**, because a cache is
a second answer that is wrong exactly when a refund has landed (D349); and
buying the whole roster gets **its own repository method** so D229's sequential
rule stays categorical in the method that carries it (D350).

`Shop.start()` is called but **not awaited** at launch, and subscribes to the
purchase stream before its first `await` — which is what AC 4 turns on (D351).

### What is tested

`test/shop_test.dart`, 16 tests against a fake store. The ones that matter:

- an errored *and* a cancelled purchase are still completed, because an
  uncompleted purchase is redelivered forever and the player is charged for
  something they never received;
- a pending purchase owns nothing and completes nothing;
- a lapse leaves every unlock intact, modelled as what it actually is — a fresh
  launch where the store no longer re-delivers the subscription;
- a refund revokes only `UnlockSource.purchase` records, and an opponent earned
  with points keeps both its source and the price it cost;
- granting twice does not overwrite an earned unlock.

### The iOS build takes the plugin without a Podfile

`in_app_purchase_storekit` resolves through Swift Package Manager like
`path_provider_foundation` (D325), so there is still no `ios/Podfile`. The
release build signs and installs.

**It also ships its own `PrivacyInfo.xcprivacy`, and it is empty** — no
tracking, no collection, no accessed APIs. That is a useful confirmation of
D345's reasoning rather than a contradiction of it: a plugin with a native
bundle can carry a manifest and does; `path_provider_foundation` has no native
bundle and therefore cannot. **The app's own manifest needs no change** — with
no server of ours, nothing about a purchase is collected or transmitted, so
`NSPrivacyCollectedDataTypes` stays empty.

### Acceptance criteria

| AC | Status |
|----|--------|
| 1 — both products exist in both consoles, subscription in a group with one base plan | **Not met.** The *StoreKit configuration* has exactly this shape, which is what lets the code be exercised. Creating the real products needs the App Store Connect web console and an account login. Play is additionally blocked on the Play account. |
| 2 — a sandbox purchase of each completes, entitlement readable after | **Not met**, and untested even locally. |
| 3 — a reinstall restores both, via the explicit action, without re-paying | **Covered by test, not by a store.** The restore action exists in settings and `start()` restores at launch. |
| 4 — an interrupted purchase completes on next launch | **Covered by test, not by a store.** The stream is subscribed before any await (D351) and every delivered purchase is completed. |
| 5 — a lapsed subscription leaves unlocks intact | **Covered by test, not by a store.** |
| 6 — refunds revoke precisely | **Covered by test, not by a store.** |
| 7 — purchased unlocks carry `source` | **Met.** Written at `UnlockSource.purchase`, tested. |
| 8 — no package outside `app/` gains a dependency | **Met.** Purity scan passes. |
| 9 — `bash tool/check.sh` passes | **Met.** |

### What has to happen next, and by whom

1. **Create both products in App Store Connect** — a web console action needing
   the account. The subscription must go inside a group with one base plan; the
   group cannot be retro-fitted later around a product that already has
   subscribers (D223).
2. **Run the StoreKit configuration pass in Xcode** — scheme → Options → StoreKit
   Configuration → `Quadrim.storekit`. This turns a console round trip into an
   edit and should be the first thing tried.
3. **Then re-test against real sandbox products**, because the two do not behave
   identically on restore. Needs a Sandbox Apple Account, created in App Store
   Connect and signed in under Settings → Developer, **not** the device's main
   App Store account.
4. **Record the sandbox subscription duration mapping** in this section when it
   is known — a year renews in minutes there, and it is the only practical way
   to test a lapse.
5. **The Android half is written but entirely unverified** and stays that way
   until the Play account returns.


## Closure amendment — verified against a real store

**The condition this ticket was held open for has been met.** The earlier
closure said "nothing has been bought — not in sandbox, not against a StoreKit
configuration", and that is no longer true: both products exist, the shop
resolves them, and purchasing works and has been tested. The ticket moves to
`done/`.

Everything below is the developer's report of what happened on a device and in
two web consoles. None of it is observable from this repository, so it is
recorded as a report rather than as a test result (D371).

| AC | Was | Now |
|----|-----|-----|
| 1 — both products exist, subscription in a group with one base plan | Not met | **Met.** Created in App Store Connect; the shop screen resolves both, which is the only way it leaves its unavailable state. |
| 2 — a sandbox purchase of each completes, entitlement readable after | Not met | **Met**, reported. |
| 3 — a reinstall restores both, via the explicit action, without re-paying | Covered by test | **Not separately recorded.** The restore action exists and is tested against the fake; whether it was exercised against the store is not stated. Listed in 022, which already asks for it. |
| 4 — an interrupted purchase completes on next launch | Covered by test | **Unchanged.** An interruption cannot be arranged to order; the code path is tested and the stream is subscribed before any await (D351). |
| 5 — a lapsed subscription leaves unlocks intact | Covered by test | **Unchanged.** A lapse is a year away in production and minutes away only in sandbox; if the sandbox duration mapping was observed, record it above. |
| 6 — refunds revoke precisely | Covered by test | **Unchanged.** Needs a real refund. |
| 7, 8, 9 | Met | Met. |

**The Android half is where the remaining doubt is, and it is one specific
question.** The merged release manifest has `INTERNET` stripped with
`tools:node="remove"` (D357), and whether Play Billing still completes a purchase
without it was left as an empirical question for the first real install. Play
Billing talks to the Play Store app over IPC rather than over a socket, so it is
*expected* to work — but expected is exactly what D357 refused to accept. **If
the purchase that was tested was an iOS one, that question is still open**, and
the closed test now running is what settles it. Whichever it was, write the
answer here.
