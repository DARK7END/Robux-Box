# Store Preparation — Google Play & App Store

## Google Play

### Listing
- **Title:** Robux Box — Rewards & Gift Cards (≤ 30 chars for the short title)
- **Short description (≤ 80):** Watch ads & complete offers to earn coins for
  Robux, gift cards & rewards.
- **Full description:** cover earning (ads/offers), redeeming (Robux/gift cards),
  daily rewards, referrals, VIP, and a clear "not affiliated with Roblox
  Corporation" disclaimer.
- **Graphics:** 512×512 icon, 1024×500 feature graphic, ≥ 4 phone screenshots
  (1080×1920), optional 30s promo video.

### Data safety form (declare truthfully)
- Collected: account (email/phone), approximate & precise **location** (for
  rewards tier), device identifiers, app activity, in-app actions.
- Purpose: app functionality, fraud prevention, analytics, advertising.
- Encrypted in transit: **yes**. User can request deletion: **yes** (in-app
  "Delete account").

### Policy compliance
- **Permissions:** justify `ACCESS_FINE/COARSE_LOCATION` (rewards tier),
  `AD_ID`, `PACKAGE_USAGE_STATS` (offer verification — requires a Play
  declaration and a strong justification; consider removing if not essential),
  `POST_NOTIFICATIONS`.
- **Ads:** declare the app contains ads; use AdMob families policy settings.
- **Real-money / rewards:** ensure your reward model complies with Play's
  "Real-Money Gambling, Games, and Contests" and monetisation policies. This app
  is **not** gambling (no wager/chance-of-loss), but review the ToS.
- **Target audience & content rating:** complete the IARC questionnaire. If you
  target teens, comply with **Families** policy and disable personalised ads for
  under-13 where required.
- **Roblox trademark:** do not use Roblox branding/logos; keep the
  non-affiliation disclaimer visible.

### Release
- App signing by Google Play (upload key in `android/key.properties`).
- `versionCode`/`versionName` from `pubspec.yaml`.
- Roll out to **internal testing → closed → open → production**.

## Apple App Store (if you ship iOS)
- **ATT:** the app requests App Tracking Transparency before the offerwall;
  provide `NSUserTrackingUsageDescription` and
  `NSLocationWhenInUseUsageDescription` in `Info.plist` with clear copy.
- **Guideline 3.1.1 / 4.7:** rewarded content must not offer App Store items;
  redemptions are external (Robux/gift cards) — review 3.2.1 and 5.3.
- **Privacy nutrition labels:** mirror the Play data-safety declarations.
- **Sign-in:** because you offer Google sign-in, you must also offer **Sign in
  with Apple** to pass review (add it before iOS submission).
- Age rating via App Store Connect questionnaire.

## Pre-submission QA checklist
- [ ] Google/Email/Phone sign-in all succeed on a physical device.
- [ ] Rewarded ad credits exactly once; daily cap + cooldown enforced.
- [ ] Offerwall opens with consent; postback credits correctly (test txn).
- [ ] Redemption holds coins, admin approve/reject/paid works, refund on reject.
- [ ] Location permission flow + tier resolution + server re-validation.
- [ ] Arabic (RTL) layout and device-language switching.
- [ ] Delete-account removes data (verify Firestore + Auth).
- [ ] App Check enforced; no cleartext traffic; Crashlytics receiving events.
- [ ] Privacy Policy & Terms URLs reachable from Settings.
