# Security, Anti-Cheat & Anti-Fraud

Robux Box treats the client as **untrusted**. Everything of value is decided and
written by Cloud Functions; the app can only *request* actions.

## 1. Trust boundary
- **Firestore rules** (`firestore.rules`) make `wallets`, `transactions`,
  `redemptions` (status), `tiers`, `vip` and fraud data **impossible for clients
  to write**. Reads are owner-scoped. A default-deny rule closes everything else.
- All economy mutations run in Cloud Functions with the Admin SDK, inside
  **Firestore transactions**, so checks and writes are atomic (no double-spend,
  no race).

## 2. App attestation
- **Firebase App Check** (Play Integrity on Android, App Attest on iOS) is
  activated in `bootstrap.dart` before any Firestore/Functions traffic, and
  callables set `enforceAppCheck: true`. Requests from tampered or emulated apps
  are rejected at the edge.

## 3. Rewarded-ad integrity
- **Single-use nonce**: `beginRewardedAd` issues a server nonce with a short TTL;
  `confirmRewardedAd` atomically consumes it. A reward can be claimed **once**.
- **AdMob Server-Side Verification (SSV)**: AdMob calls `admobSsv` with the nonce
  as `custom_data`, recording a verified impression. In `STRICT_SSV` mode the
  credit requires that record. (Verify Google's SSV signature in production.)
- **Daily cap + cooldown** enforced server-side (`maxRewardedAdsPerDay`,
  `rewardedAdCooldownSeconds`).

## 4. Offerwall integrity
- The wall URL is **signed server-side** (`getOfferwallUrl`); the signing secret
  never ships in the app.
- Coins are credited **only** by the provider's **server-to-server postback**
  (`offerwallPostback`), which is **HMAC-verified**, **idempotent per transaction
  id**, and applies the developer-margin user share. The in-app WebView cannot
  mint coins. Chargebacks/reversals are handled.
- **Usage-tracking consent** (ATT on iOS; usage-access on Android) is requested
  transparently before opening the wall, used only to verify engagement offers.

## 5. Geo-tier anti-spoofing
- The client resolves a tier from GPS→country only as a **UI hint**.
- `resolveTier` and every earn call **re-derive the tier server-side** from the
  account's country of record (`functions/src/lib/tiers.ts`). A spoofed GPS
  changes only what the UI previews, never the actual payout.

## 6. Device & velocity anti-fraud
- **Encrypted local storage** (`SecureStorageService`, Android Keystore / iOS
  Keychain) holds a per-install random device id + secret; no IMEI/ad-id is
  persisted.
- **Device cap** per account and **shared-device detection** across accounts
  raise fraud flags (`fraud_flags`).
- **Velocity guard** blocks abnormal coins/minute; **rate limiting** caps each
  action per window.
- **Integrity heuristics** (emulator/debug/root signals) lower an integrity score
  that gates high-value payouts.

## 7. Transport & data
- **TLS enforced** (`network_security_config.xml`); cleartext only to localhost
  emulators.
- Coordinates are rounded (~1km) before leaving the device; precise location is
  never stored.

## 8. Account safety
- Admins can restrict/ban accounts (`setAccountStatus`), which also disables the
  Firebase Auth user. All privileged actions write to `audit_logs`.

## Production hardening checklist
- [ ] Set `STRICT_SSV=true` and implement AdMob SSV signature verification.
- [ ] Restrict the first admin via `ADMIN_BOOTSTRAP_EMAIL`, then remove it.
- [ ] Configure App Check enforcement in the Firebase console for Firestore,
      Functions and Storage.
- [ ] Set offerwall postback IP allow-listing at the provider where supported.
- [ ] Review `firestore.rules` with the emulator test suite before each deploy.
