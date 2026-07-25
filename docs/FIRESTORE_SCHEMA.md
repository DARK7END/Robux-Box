# Firestore Schema

All collection/document paths are centralised in
`lib/core/constants/firestore_paths.dart` and mirrored in
`functions/src/lib/admin.ts`. **W** = who may write.

## Collections

### `users/{uid}` — profile & progression
`displayName, email, photoUrl, phoneNumber, countryCode, tierLevel, vipLevel,
status, xp, level, streakCount, lastDailyClaim, referralCode, referredBy,
referralCount, robloxUsername, locale, isEmailVerified, createdAt, lastActiveAt`
**W:** client may update a safe allow-list (`displayName, photoUrl,
robloxUsername, locale, lastActiveAt`); everything else is functions-only.

Subcollections:
- `users/{uid}/transactions/{txId}` — immutable ledger. **W:** functions only.
- `users/{uid}/notifications/{id}` — in-app centre. **W:** functions create;
  client may flip `isRead`.
- `users/{uid}/devices/{deviceId}` — device + FCM token. **W:** owner.
- `users/{uid}/achievements/{id}` — progress. **W:** functions only.

### `wallets/{uid}` — authoritative balance
`coins, pendingCoins, lifetimeEarned, lifetimeSpent, adsWatchedToday,
adsWatchedTotal, offersCompletedTotal, lastEarnAt, lastAdAt, dailyResetAt,
updatedAt` — **W:** functions only. **R:** owner.

### `transactions/{txId}` — global ledger mirror (admin analytics). **W/R:** admin.

### `rewards/{id}` — catalogue
`kind (robux|giftCard|digitalCode), title, subtitle, imageUrl, coinCost,
faceValue, currency, provider, stock (-1=∞), isActive, minVipLevel, sortOrder,
badge` — **R:** signed-in. **W:** admin.

### `offers/{id}` — offerwall offers (ingested)
`provider, category, title, description, iconUrl, rewardCoins, trackingUrl,
requirements[], countries[], isMultiStep, featured, expiresAt, payoutUsd`.

### `redemptions/{id}` — redemption requests
`uid, rewardId, kind, title, coinCost, faceValue, currency, provider, status
(pending|approved|rejected|paid|cancelled), deliveryTarget, deliveredCode,
rejectionReason, createdAt, processedAt, processedBy` — **R:** owner+admin.
**W:** functions/admin.

### `leaderboards/{period}/entries/{uid}` — aggregated ranks
`rank, score, displayName, photoUrl, countryCode, vipLevel, updatedAt`.
`period ∈ {daily, weekly, all_time}`. **W:** scheduled function.

### `promocodes/{CODE}` — promo codes (+ `claims/{uid}` subcollection)
`rewardCoins, maxRedemptions, redemptionCount, perUserLimit, isActive,
expiresAt` — **R/W:** admin (redeemed via function). Never client-readable.

### `banners/{id}` / `events/{id}` — home promos & campaigns. **R:** signed-in. **W:** admin.

### `referrals/{id}` — `referrerUid, refereeUid, code, createdAt`. **W:** functions.

### `offer_completions/{transId}` — idempotency + offer audit. **W:** functions.
### `ad_impressions/{nonce}` — AdMob SSV records. **W:** functions.
### `nonces/{nonce}` / `rate_limits/{key}` — security internals. Default-deny.
### `fraud_flags/{id}` / `audit_logs/{id}` — review & audit. **R:** admin.
### `reports/{id}` — user-filed reports. **create:** owner. **R/update:** admin.

### `config/{doc}` & `geo_tiers/overrides` — remote config
`config/economy`, `config/feature_flags`, `config/maintenance`,
`geo_tiers/overrides {map: {US:1, …}}` — **R:** signed-in. **W:** admin.

## Relationships

```
users/{uid} 1──1 wallets/{uid}
users/{uid} 1──* users/{uid}/transactions
users/{uid} 1──* redemptions (by uid)      *──1 rewards
users/{uid} 1──* users/{uid}/notifications
users/{uid} 1──* users/{uid}/devices
users/{referrerUid} 1──* referrals *──1 users/{refereeUid}
leaderboards/{period} 1──* entries (by uid → users)
promocodes/{CODE} 1──* claims (by uid)
```

## Seed data (minimum to run)

```jsonc
// config/economy  (optional — client has defaults)
{ "coinsPerRobux": 100, "baseRewardedAdCoins": 15, "maxRewardedAdsPerDay": 40 }

// geo_tiers/overrides
{ "map": { "US": 1, "GB": 1, "IN": 4 } }

// rewards/robux_400
{ "kind": "robux", "title": "400 Robux", "coinCost": 40000, "faceValue": 400,
  "currency": "RBX", "provider": "manual", "isActive": true, "sortOrder": 1,
  "badge": "Popular" }
```
See `docs/DEPLOYMENT.md` for a seed script.
