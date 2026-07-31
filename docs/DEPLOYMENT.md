# Deployment Guide

End-to-end setup for a fresh environment.

## 0. Tooling
```bash
flutter --version                      # 3.24+
npm i -g firebase-tools                # Firebase CLI
dart pub global activate flutterfire_cli
firebase login

# .firebaserc is gitignored, so select the project once per clone:
firebase use robux-box
```
(The legal pages in step 7b are on GitHub Pages, not Firebase — the CLI is
only needed for Functions, rules and indexes.)

## 1. Firebase project
1. Create a project (Firebase console) on the **Blaze** plan (Functions require it).
2. Enable: **Authentication** (Google, Email/Password, Phone), **Firestore**,
   **Cloud Functions**, **Storage**, **Cloud Messaging**, **App Check**,
   **Crashlytics**, **Analytics**.
3. Auth → add your SHA-1/SHA-256 (from `./gradlew signingReport`) for Google &
   Phone sign-in.

## 2. Wire the app to the project
```bash
flutterfire configure --project=<project-id>   # writes lib/firebase_options.dart
# Download android/app/google-services.json from console → Android app.
```

## 3. App Check
- Register the Android app with **Play Integrity**; register a **debug token**
  for local testing (console → App Check → your app → Manage debug tokens).
- Enforce App Check for Firestore, Functions and Storage in the console.

## 4. AdMob
- Create an AdMob app + **rewarded** ad unit; put the AdMob **app id** in
  `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`).
- Configure **SSV**: AdMob → ad unit → Server-side verification →
  `https://us-central1-<project-id>.cloudfunctions.net/admobSsv`.

## 5. Offerwall provider
- Create an app with your provider (AdGate/BitLabs/OfferToro/…).
- Set the **postback URL** to
  `https://us-central1-<project-id>.cloudfunctions.net/offerwallPostback`
  with the params your provider sends (subid, transId, payout, signature, …).
- Put the shared secret + base URL + app id in `functions/.env` and the app's
  `--dart-define`s.

## 6. Cloud Functions
```bash
cd functions
cp .env.example .env      # fill OFFERWALL_*, STRICT_SSV, ADMIN_BOOTSTRAP_EMAIL
npm install
npm run build             # tsc — must pass
cd ..
firebase deploy --only functions
```

## 7. Rules, indexes, storage
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 7b. Legal pages (required by Google Play)
Google Play will not publish the listing without a publicly reachable privacy
policy URL. These are published free by **GitHub Pages** from this repo — no
domain to buy and no hosting to pay for.

**One-time:** repo **Settings → Pages → Source: “GitHub Actions”**.

Then:
1. Replace every `[PLACEHOLDER]` in `docs/PRIVACY_POLICY.md` and
   `docs/TERMS_OF_SERVICE.md` (`[COMPANY NAME]`, `[DATE]`, minimum age,
   offerwall provider name/URL…).
2. Push to `main`. `.github/workflows/pages.yml` regenerates the HTML from
   that markdown and publishes it — no local step needed.

Live at:
- `https://dark7end.github.io/Robux-Box/privacy.html`
- `https://dark7end.github.io/Robux-Box/terms.html`
- `https://dark7end.github.io/Robux-Box/account-deletion.html` — this is the
  URL Play Console's Data safety → "Account deletion" field asks for. The app
  already deletes accounts in-app (Settings → Account Deletion); this page
  just describes those steps publicly, which is what Play requires.

These are the defaults compiled into `AppConfig`, so the in-app links and the
Play Store listing both work with no extra flags. To preview locally run
`python3 tool/build_legal_pages.py` and open `public/privacy.html`. If a
branded domain is ever added, point it at Pages and rebuild with
`--dart-define=PRIVACY_URL=… --dart-define=TERMS_URL=…`.

## 8. Seed initial data
Create `scripts/seed.js` (Node, Admin SDK) or add docs manually per
`docs/FIRESTORE_SCHEMA.md` (at minimum: a few `rewards`, `geo_tiers/overrides`).

## 9. Bootstrap the first admin
1. Sign in once with the email listed in `ADMIN_BOOTSTRAP_EMAIL`.
2. Call `setAdminClaim({ email })` (via the app's admin area or
   `firebase functions:shell`).
3. Sign out/in to refresh the token. Remove the bootstrap email afterwards.

## 10. Local development with emulators
```bash
firebase emulators:start          # auth, firestore, functions, storage, UI:4000
flutter run --dart-define=FLAVOR=dev --dart-define=USE_EMULATORS=true
```

## 11. Release build (Android)
```bash
# Create a keystore and android/key.properties (never commit these).
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload

flutter build appbundle --release \
  --dart-define=FLAVOR=prod \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXX/YYY \
  --dart-define=OFFERWALL_APP_ID=... \
  --dart-define=OFFERWALL_BASE_URL=https://wall.provider.com/wall \
  --dart-define=SUPPORT_EMAIL=support@yourdomain.app
# PRIVACY_URL / TERMS_URL default to the Firebase Hosting pages deployed in
# step 7b, so only pass them if you have moved to a custom domain.
```
Output: `build/app/outputs/bundle/release/app-release.aab`.

## 12. CI/CD
A sample GitHub Actions workflow is in `.github/workflows/ci.yml` (analyze +
test + functions build). Add secrets for signing and Firebase deploy tokens.

## Rollback
Functions: `firebase functions:delete <name>` or redeploy a previous tag.
Rules: keep versions in git; `firebase deploy --only firestore:rules` re-applies.
