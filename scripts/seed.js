/**
 * Seed script — populates the minimum Firestore data needed to run Robux Box:
 * remote config, geo-tier overrides, a starter reward catalogue, a demo promo
 * code, and sample home banners.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
 *   node scripts/seed.js
 *
 * Safe to re-run (uses merge/set on fixed document ids).
 */
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

async function main() {
  const batch = db.batch();

  // Remote config
  batch.set(db.doc("config/economy"), {
    coinsPerRobux: 100,
    baseRewardedAdCoins: 15,
    maxRewardedAdsPerDay: 40,
    offerwallUserSharePercent: 0.7,
  }, {merge: true});
  batch.set(db.doc("config/feature_flags"), {
    offerwallEnabled: true,
    vipEnabled: true,
    referralsEnabled: true,
  }, {merge: true});
  batch.set(db.doc("config/maintenance"), {enabled: false, message: ""}, {merge: true});
  // Empty until an admin sets it — notifyAdmins() (functions/src/lib/notify.ts)
  // no-ops silently until this has at least one address. Not client-readable
  // (see firestore.rules); requires the Trigger Email extension to actually
  // deliver mail — see docs/DEPLOYMENT.md.
  batch.set(db.doc("config/notifications"), {adminEmails: []}, {merge: true});

  // Geo-tier overrides (extend/adjust as needed)
  batch.set(db.doc("geo_tiers/overrides"), {
    map: {US: 1, GB: 1, CA: 1, DE: 1, FR: 2, BR: 3, IN: 4, EG: 4},
  }, {merge: true});

  // Reward catalogue. The six Robux tiers mirror the bundled global gift-card
  // art (assets/images/robux_packages/) — coinCost applies a graduated bulk
  // discount off the flat coinsPerRobux rate (0% -> 15%) as the tier grows.
  const rewards = [
    {id: "robux_100", kind: "robux", title: "100 Robux", subtitle: "Global gift card",
      coinCost: 10000, faceValue: 100, currency: "RBX", provider: "manual",
      isActive: true, sortOrder: 1, badge: ""},
    {id: "robux_200", kind: "robux", title: "200 Robux", subtitle: "Global gift card",
      coinCost: 19500, faceValue: 200, currency: "RBX", provider: "manual",
      isActive: true, sortOrder: 2, badge: ""},
    {id: "robux_400", kind: "robux", title: "400 Robux", subtitle: "Global gift card",
      coinCost: 38000, faceValue: 400, currency: "RBX", provider: "manual",
      isActive: true, sortOrder: 3, badge: "Popular"},
    {id: "robux_800", kind: "robux", title: "800 Robux", subtitle: "Global gift card",
      coinCost: 72000, faceValue: 800, currency: "RBX", provider: "manual",
      isActive: true, sortOrder: 4, badge: ""},
    {id: "robux_1000", kind: "robux", title: "1000 Robux", subtitle: "Global gift card",
      coinCost: 88000, faceValue: 1000, currency: "RBX", provider: "manual",
      isActive: true, sortOrder: 5, badge: ""},
    {id: "robux_2500", kind: "robux", title: "2500 Robux", subtitle: "Global gift card",
      coinCost: 212500, faceValue: 2500, currency: "RBX", provider: "manual",
      isActive: true, sortOrder: 6, badge: "Best value"},
    {id: "gc_amazon_10", kind: "giftCard", title: "$10 Amazon", subtitle: "Gift card",
      coinCost: 100000, faceValue: 10, currency: "USD", provider: "reloadly",
      isActive: true, sortOrder: 10, badge: ""},
    {id: "gc_gplay_10", kind: "digitalCode", title: "$10 Google Play",
      subtitle: "Digital code", coinCost: 100000, faceValue: 10, currency: "USD",
      provider: "reloadly", isActive: true, sortOrder: 20, badge: ""},
  ];
  for (const r of rewards) {
    const {id, ...data} = r;
    batch.set(db.doc(`rewards/${id}`), data, {merge: true});
  }

  // Demo promo code
  batch.set(db.doc("promocodes/WELCOME"), {
    rewardCoins: 200, maxRedemptions: -1, perUserLimit: 1, redemptionCount: 0,
    isActive: true, expiresAt: null,
  }, {merge: true});

  // Home banners
  batch.set(db.doc("banners/welcome"), {
    title: "Welcome to Robux Box", subtitle: "Watch ads, earn coins, get Robux",
    imageUrl: "", gradientColors: ["#6C5CE7", "#00D1FF"], deeplink: "/earn",
    isActive: true, sortOrder: 1, startsAt: null, endsAt: null,
  }, {merge: true});

  await batch.commit();
  console.log("✅ Seed complete.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
