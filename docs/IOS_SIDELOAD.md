# iOS — Build & Sideload (no paid Apple Developer account)

This guide builds an **unsigned `.ipa`** you can install on your iPhone with a
sideloading tool (**iLoader**, Sideloadly, or AltStore) using a **free Apple
ID** — no $99/year Apple Developer Program needed.

The iOS Xcode project is **not committed**. It is generated on demand from
`ios_config/` by `tool/setup_ios.sh`, so there's nothing to keep in sync by hand.

---

## Option A — Build in the cloud (no Mac needed) ✅ recommended

1. Push this branch to GitHub (already done).
2. On GitHub → **Actions** → **"iOS unsigned IPA"** → **Run workflow** (pick
   `dev` for test ads). It runs on a macOS runner and:
   - generates the iOS project (`flutter create` + overlays `ios_config/`),
   - sets the bundle id to `com.robuxbox.app`,
   - builds `Runner.app` **unsigned** and wraps it into an IPA.
3. When it finishes, download the **`RobuxBox-unsigned-ipa`** artifact → unzip →
   you get `RobuxBox-unsigned.ipa`.
4. Sideload it (below).

> macOS Actions minutes are limited on free GitHub plans. A free alternative is
> **Codemagic** (500 free min/mo): point it at this repo, set the pre-build
> script to `bash tool/setup_ios.sh`, build command
> `flutter build ios --release --no-codesign`, then
> `bash tool/package_unsigned_ipa.sh`, and collect `build/ios/ipa/*.ipa`.

## Option B — Build on a Mac

```bash
bash tool/setup_ios.sh                         # generates ios/ + overlays config
flutter build ios --release --no-codesign      # unsigned Runner.app
bash tool/package_unsigned_ipa.sh              # → build/ios/ipa/RobuxBox-unsigned.ipa
```

---

## Sideloading with iLoader / Sideloadly / AltStore

1. Install the sideloading tool and connect your iPhone.
2. Load `RobuxBox-unsigned.ipa` and sign in with your **free Apple ID**.
3. Keep the bundle id **`com.robuxbox.app`** if the tool lets you (so it matches
   the Firebase iOS app). If the tool forces a unique bundle id, the app still
   runs — Firebase is initialised from `firebase_options.dart`, and Google
   Sign-In uses the URL scheme, both of which keep working.
4. Install to the device, then **Settings → General → VPN & Device Management →
   trust** your developer (Apple ID) certificate.

---

## ⚠️ Free-account limitations (important)

Sideloading with a free Apple ID has hard Apple limits — none of these are bugs:

- **7-day expiry.** The app stops opening after 7 days; just **re-sign/re-install**
  with the tool to renew. (AltStore can auto-refresh over Wi-Fi.)
- **Max 3 sideloaded apps** installed at once per free Apple ID.
- **Push notifications don't work.** Remote push (APNs) needs a paid account to
  create an APNs key and the `aps-environment` entitlement. What still works:
  the **in-app notification centre** and **local notifications**. (The scheduled
  reminder Cloud Functions will simply have no iOS device token to hit.)
- **Phone (SMS) sign-in** on iOS relies on silent APNs; without it, Firebase
  falls back to a **reCAPTCHA** web check (works, shows a brief web view).
  Google and Email/Password sign-in are unaffected.

## Firebase console — do this once so the app works while testing

- **App Check:** keep it **unenforced** for Firestore/Functions while
  sideloading. App Attest requires the app to be registered with your Apple Team
  ID, which a free/ad-hoc signature doesn't provide — so an enforced App Check
  would block the app. Enforce it later when you ship a properly signed build.
- **Authorized domains / OAuth:** the iOS Google client
  (`…csphovmpqp9rfgj3i3er0m5suesropvs`) is already in `ios_config/Info.plist`
  and `firebase_options.dart`; nothing to add.
- **AdMob:** `Info.plist` ships Google's **test** iOS app id, so `dev`/`staging`
  builds never serve live ads. Put your real AdMob iOS app id in
  `ios_config/Info.plist` (`GADApplicationIdentifier`) before a `prod` build.

## What fully works when sideloaded

Google + Email/Password sign-in, Firestore reads/writes, all Cloud Functions
(earn, spin/chest, redemption, promo), AdMob **test** rewarded ads, location →
tier, offerwall web view, in-app notifications, and the whole premium UI.

---

## Later: shipping to the App Store

When you get a paid Apple Developer account, you'll additionally need to: add
**Sign in with Apple** (required by review because you offer Google sign-in),
create an **APNs key** for push, enable **App Attest** + enforce App Check, and
archive a signed build in Xcode / `flutter build ipa` with your team. See
`docs/STORE_PREP.md`.
