# Architecture

Robux Box uses **feature-first Clean Architecture** with **Riverpod** for state
management and dependency injection, and a **server-authoritative** backend on
Firebase.

## Layers

Each feature under `lib/features/<feature>/` is split into:

- **data/** — repositories that talk to Firebase (Firestore, Functions, Auth).
  They return `Result<T>` and never throw across the boundary.
- **domain/** — controllers (Riverpod `Notifier` / `AsyncNotifier`) holding UI
  state and orchestrating repositories. Pure Dart, easily testable.
- **presentation/** — screens and widgets (`ConsumerWidget`/`ConsumerStatefulWidget`).

Shared building blocks live in `lib/core/` (theme, widgets, services, errors,
config, l10n, router) and `lib/models/` (immutable domain models).

## State management

- **Riverpod providers** are the single DI mechanism. Firebase singletons are
  exposed via `core/config/providers.dart`, so every repository is trivially
  testable by overriding those providers with fakes.
- **Streams** (`currentUserProvider`, `currentWalletProvider`,
  `transactionsProvider`, …) turn Firestore documents into reactive UI state.
- **Controllers** expose `AsyncValue`/custom state for imperative actions
  (sign-in, watch-ad, redeem) so screens render loading/error uniformly.

## Error handling

`core/error/result.dart` defines a sealed `Result<T>` (`Success`/`Err`) and
`failure.dart` a `Failure` taxonomy (`NetworkFailure`, `AuthFailure`,
`ServerFailure`, `OperationFailure`, `PermissionFailure`, `SecurityFailure`).
`core/network/firebase_error_mapper.dart` converts raw Firebase exceptions into
`Failure`s with stable codes for localisation and analytics.

## Navigation

`go_router` (`core/router/app_router.dart`) with:
- a **redirect gate** that routes through onboarding → auth → home based on
  `authStateProvider` and the persisted onboarding flag;
- a **StatefulShellRoute** for the five primary tabs (each keeps its own stack);
- detail routes pushed over the shell (wallet, redemptions, settings, …) that
  double as notification deeplink targets.

## Data flow: "watch a rewarded ad"

```
EarnScreen ──▶ EarnController.watchRewardedAd()
   │  1. EarnRepository.beginRewardedAd()  ──▶ Fn beginRewardedAd
   │       (device integrity, daily cap, cooldown) ──▶ returns single-use nonce
   │  2. AdsService.show(userId, nonce)  ──▶ AdMob (SSV custom_data = nonce)
   │        AdMob ──▶ Fn admobSsv (records verified impression by nonce)
   │  3. EarnRepository.confirmRewardedAd(nonce) ──▶ Fn confirmRewardedAd
   │        consume nonce · re-derive tier · rate/velocity checks
   │        creditWallet() in a Firestore transaction (+ ledger entry)
   ▼
currentWalletProvider stream updates ──▶ balance animates, reward dialog shows
```

The client never writes coins; it only requests them. This is the core security
property — see [`SECURITY.md`](SECURITY.md).

## Localisation

ARB files in `core/l10n/arb/` (`app_en.arb`, `app_ar.arb`) are compiled by
`flutter gen-l10n`. `LocaleController` follows the device locale by default and
persists an in-app override; RTL is handled automatically for Arabic.

## Theming

`core/theme/` defines a token system (colors, typography, gradients, dimens) and
builds Material 3 light/dark `ThemeData` with a custom `AppSurfaces` extension
for glassmorphism tokens. Dark is the product default.
