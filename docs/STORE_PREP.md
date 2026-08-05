# Store Preparation — Google Play & App Store

## Google Play

### Listing

**Title** (28/30 chars — keeps "Robux" + adds "Cash" as a second
high-volume search term the app can legitimately back, since PayPal cash
is a real redemption option):
```
Robux Box: Earn Robux & Cash
```

**Short description** (79/80 chars):
```
Watch ads & complete offers to earn coins — redeem for Robux, cash & gift cards
```

**Full description** (paste as-is into Play Console; ~2,190/4000 chars —
keyword coverage for search: rewards app, earn coins, Robux, gift cards,
PayPal cash, watch ads, complete offers/surveys, VIP, leaderboard, each
named gift-card brand):
```
Robux Box is a free rewards app that pays you in coins for simple
everyday actions — watching short videos and completing offers — and
lets you redeem those coins for Robux, gift cards, and PayPal cash.

No skill, no purchase required. Just complete simple tasks and cash out.

🎮 EARN COINS
• Watch short rewarded ads for a quick coin boost, with a fresh batch of
  ad slots every day
• Complete offers from our partner network — app installs, surveys,
  sign-ups, and more — for bigger payouts
• Spin the daily reward wheel or open the lucky chest for a free bonus,
  and grow a login streak for extra perks
• Unlock achievements and badges as you play — each one pays out a coin
  bonus the moment you earn it
• Invite friends with your referral link and earn coins when they join

🎁 REDEEM FOR REAL REWARDS
• Robux top-ups and Roblox gift cards
• Steam, PlayStation, Xbox, Nintendo eShop and Google Play gift cards
• Apple, Amazon and PayPal cash rewards
• Track every redemption in one place, from request to delivery

⭐ GO VIP FOR FASTER EARNINGS
Subscribe to Bronze, Silver, Gold, or Diamond and earn coins faster on
everything you do — up to 3x — with a bigger daily ad allowance and
access to VIP-only offers. Gold and Diamond members also get priority
support and faster-processed redemption requests.

🏆 MORE REASONS TO PLAY
• Climb the leaderboard and see how you stack up against other players
• Track your full earning and redemption history in your wallet
• Get help fast from real, in-app customer support
• Available in Arabic, English, and more languages, with full right-
  to-left support

🔒 BUILT ON TRUST AND SECURITY
Every coin you earn and every redemption you request is processed and
verified on our secure servers — balances can never be edited from your
device. Sign in safely with Google, email, or phone, and your data stays
protected.

Whether you're saving up for Robux, gift cards, or cash, Robux Box turns
your spare time into real, redeemable rewards — download free today.

Robux Box is an independent rewards platform. It is not affiliated with,
endorsed by, or sponsored by Roblox Corporation. "Roblox" and "Robux"
are trademarks of Roblox Corporation.
```

**Graphics:** 512×512 icon, 1024×500 feature graphic, ≥ 4 phone screenshots
  (1080×1920), optional 30s promo video. See "Screenshots" below.

### Screenshots
Real screenshots of the running app (Home, Earn, Redeem, VIP, Wallet are
the strongest picks) work well as-is for the Play Store gallery — Play
doesn't want marketing renders, just the actual product. A separate
1024×500 feature graphic / any promotional banner artwork is a design
task outside what gets built here; bring your own asset (or a designer)
for that one.

### Data safety form (declare truthfully)
- Collected: account (email/phone), approximate & precise **location** (for
  rewards tier), device identifiers, app activity, in-app actions.
- Purpose: app functionality, fraud prevention, analytics, advertising.
- Encrypted in transit: **yes**. User can request deletion: **yes** (in-app
  "Delete account", Settings → Account Deletion).
- Play Console's **"Account deletion"** field (Data safety → Data deletion)
  takes `https://dark7end.github.io/Robux-Box/account-deletion.html` — same
  GitHub Pages pipeline as the privacy/terms URLs (`docs/ACCOUNT_DELETION.md`
  → `tool/build_legal_pages.py`).

### Policy compliance
- **Permissions:** justify `ACCESS_FINE/COARSE_LOCATION` (rewards tier),
  `AD_ID`, `PACKAGE_USAGE_STATS` (offer verification — requires a Play
  declaration and a strong justification; consider removing if not essential),
  `POST_NOTIFICATIONS`.
- **Ads:** declare the app contains ads; use AdMob families policy settings.
- **Real-money / rewards:** ensure your reward model complies with Play's
  "Real-Money Gambling, Games, and Contests" and monetisation policies. This app
  is **not** gambling (no wager/chance-of-loss), but review the ToS.
- **Target audience & content rating:** the app is **all ages** (see
  `docs/TERMS_OF_SERVICE.md` § 1 and `docs/PRIVACY_POLICY.md` § 6) — declare
  children as part of the target audience in Play Console's questionnaire, not
  just "teens." This puts the listing under the **Families** policy: no
  behaviourally-targeted ads to child users (AdMob's
  `tagForChildDirectedTreatment` / `tagForUnderAgeOfConsent`, not yet wired up
  in `lib/core/services/ads_service.dart` — needs an in-app age check to set
  per-request, since blanket-tagging the whole app would cut ad revenue for
  every user, not just children) and review of the reward/redemption flow
  against Families policy before submission — complete the IARC questionnaire
  accordingly.
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
- [ ] GitHub Pages enabled (Settings → Pages → Source: "GitHub Actions"), so
      `https://dark7end.github.io/Robux-Box/privacy.html` and `/terms.html`
      load publicly — Play Console requires the privacy URL, and rejects the
      listing if it 404s or still shows `[PLACEHOLDER]` text.
