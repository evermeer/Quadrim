# Ticket 046 — The shop: products, purchase and entitlement

**Depends on:** 041 (an iOS project to test on), 015 (store accounts and the
products created in each console)

**Status:** blocked — needs the Apple Developer account. The Android half is
additionally blocked on the Play account.

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
nl.evict.quadrim.unlock_all          non-consumable / one-time
nl.evict.quadrim.unlimited           subscription, yearly base plan
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
