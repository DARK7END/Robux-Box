# Robux Box 🎁

**Earn app coins by watching rewarded ads and completing offerwall tasks, then
redeem them for Robux, gift cards and digital codes.**

Robux Box is a production-grade, cross-platform (Android-first) rewards app built
with **Flutter + Firebase**. It is designed so that **both the developer and the
user profit**: the app always earns more from the ad network / offerwall than it
pays out (the margin is baked into a server-authoritative economy), while users
get a fair, fast and genuinely rewarding experience.

> Primary language: **English**. Fully localised to **Arabic** (RTL), with the
> UI language following the device by default and overridable in Settings.

---

## ✨ Features

| Area | Highlights |
|------|-----------|
| **Earning** | Rewarded video ads (AdMob), offerwall tasks (survey/game/app), daily streak rewards, promo codes, referrals with lifetime revenue share |
| **Geo tiers** | Device location → country → monetisation tier (T1–T4). Earnings scale by tier; **the tier is re-validated server-side** so it can't be spoofed |
| **Redemption** | Robux, gift cards and digital codes. Flexible pending → approved → paid/rejected lifecycle with coin holds and refunds |
| **Wallet** | Live balance, immutable transaction ledger, lifetime stats, Robux equivalent |
| **Gamification** | XP + levels, achievements, daily streaks, daily/weekly/all-time leaderboards, VIP tiers with earning multipliers |
| **Auth** | Google, Email/Password (with verification + reset), and Phone/OTP — all via Firebase Auth |
| **Notifications** | FCM push + local notifications + in-app centre; daily / reward / VIP / referral reminder campaigns |
| **Security** | Server-authoritative economy, single-use nonces, App Check, rate limiting, device/velocity anti-fraud, encrypted local storage, TLS-only networking |
| **Admin** | Cloud Functions powering users, coins, redemptions, VIP, promocodes, broadcasts, reports and audit logs |
| **UX** | Dark-first Material 3, glassmorphism, gradient backgrounds, premium typography, micro-interactions and animations |

---

## 🏛 Architecture

Feature-first **Clean Architecture** with three layers per feature
(`data` → `domain` → `presentation`) and **Riverpod** for state management + DI.

```
lib/
├─ main.dart / bootstrap.dart / app.dart      # entry, init, root widget
├─ firebase_options.dart                       # generated (flutterfire configure)
├─ core/
│  ├─ config/      # AppConfig (dart-define env), DI providers
│  ├─ constants/   # economy constants, Firestore paths
│  ├─ error/       # Result<T> + Failure taxonomy
│  ├─ l10n/        # ARB translations (en, ar) + controllers
│  ├─ network/     # Firebase error → Failure mapper
│  ├─ router/      # go_router + auth/onboarding redirect gate
│  ├─ services/    # geo tier, security, ads, offerwall, notifications, storage
│  ├─ theme/       # colors, typography, gradients, dimens, Material 3 themes
│  ├─ utils/       # logger, validators
│  └─ widgets/     # design-system widgets (GlassCard, GradientButton, …)
├─ models/         # immutable domain models w/ defensive Firestore parsing
└─ features/
   ├─ auth/  home/  earn/  wallet/  redemption/  leaderboard/
   ├─ profile/  settings/  notifications/  referrals/  vip/  achievements/
functions/          # Cloud Functions (TypeScript) — the trust boundary
firestore.rules · firestore.indexes.json · storage.rules
android/            # native config, permissions, gradle, signing
docs/               # deployment, store prep, privacy, terms, schema
```

### Why the server is authoritative
Clients can **never** write balances, transactions, tiers or redemption states
(enforced by `firestore.rules`). Every coin movement flows through a Cloud
Function running the Admin SDK inside a Firestore transaction. The client can
only *request* a credit; the backend validates (App Check, single-use nonce,
AdMob SSV, rate limits, geo-tier, device/velocity checks) before applying it.
See [`docs/SECURITY.md`](docs/SECURITY.md) and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## 🚀 Quick start

### Prerequisites
- Flutter **3.24+**, Dart **3.5+**
- A Firebase project (Blaze plan — required for Cloud Functions)
- Node **20** (for Cloud Functions), `firebase-tools`, `flutterfire_cli`
- AdMob account + rewarded ad unit; an offerwall provider account

### 1. Configure Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id>   # regenerates lib/firebase_options.dart
# Place android/app/google-services.json from the Firebase console.
```

### 2. Install & generate localisations
```bash
flutter pub get
flutter gen-l10n
```

### 3. Run
```bash
# Dev (test ad units, optional emulators)
flutter run --dart-define=FLAVOR=dev --dart-define=USE_EMULATORS=true

# Production build
flutter build appbundle \
  --dart-define=FLAVOR=prod \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXX/YYY \
  --dart-define=OFFERWALL_APP_ID=... \
  --dart-define=OFFERWALL_BASE_URL=https://wall.provider.com/wall
```

### 4. Deploy the backend
```bash
cd functions && npm install && npm run build && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Full instructions: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

---

## ⚙️ Configuration (`--dart-define`)

| Key | Default | Purpose |
|-----|---------|---------|
| `FLAVOR` | `dev` | `dev` / `staging` / `prod` |
| `USE_EMULATORS` | `false` | Point at local Firebase emulators |
| `ADMOB_REWARDED_ANDROID` | Google test id | Rewarded ad unit |
| `OFFERWALL_APP_ID` / `OFFERWALL_BASE_URL` | — | Offerwall provider |
| `MIN_WITHDRAW_COINS` | `1000` | Minimum redeemable balance |
| `SUPPORT_EMAIL` / `PRIVACY_URL` / `TERMS_URL` | placeholders | Support & legal |

Backend secrets (offerwall postback secret, SSV strictness, admin bootstrap)
live in `functions/.env` — see `functions/.env.example`.

---

## 🧪 Testing
```bash
flutter test              # unit + widget tests
cd functions && npm test  # functions unit tests
```

---

## 💰 The economy (developer + user profit)

Payout numbers live in **one place** (`lib/core/constants/app_constants.dart`
mirrored by `functions/src/lib/economy.ts`). A rewarded ad pays
`baseRewardedAdCoins × tierMultiplier × vipMultiplier`; offerwall tasks credit
`offerwallUserSharePercent` of the tier-adjusted provider payout. Because the app
collects the full ad/offer revenue and pays out a share, the margin is structural
and positive across every tier. Coins convert to Robux at `coinsPerRobux`.

---

## 📄 Documentation
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — layers, state, data flow
- [`docs/SECURITY.md`](docs/SECURITY.md) — anti-cheat / anti-fraud model
- [`docs/FIRESTORE_SCHEMA.md`](docs/FIRESTORE_SCHEMA.md) — collections & relationships
- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — end-to-end deploy guide
- [`docs/STORE_PREP.md`](docs/STORE_PREP.md) — Google Play & App Store prep
- [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md) · [`docs/TERMS_OF_SERVICE.md`](docs/TERMS_OF_SERVICE.md)

## ⚠️ Compliance notes
Robux Box is an independent rewards app and is **not affiliated with, endorsed by,
or sponsored by Roblox Corporation**. "Robux" and "Roblox" are trademarks of
Roblox Corporation. Ensure your rewarded-ads and offerwall usage complies with
Google AdMob, Google Play and your offerwall provider policies, and that the app
targets an appropriate age rating.

## License
Proprietary. © 2026 Robux Box. All rights reserved.
