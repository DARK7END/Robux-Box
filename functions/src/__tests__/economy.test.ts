import {Timestamp} from "firebase-admin/firestore";
import {
  ECONOMY, TIER_MULTIPLIERS, earnMultiplier, rewardedAdCoins, levelForXp,
  effectiveVipLevel, vipRank, maxAdsPerDay,
} from "../lib/economy";

describe("economy", () => {
  test("tier multipliers descend T1..T4", () => {
    expect(TIER_MULTIPLIERS[1]).toBeGreaterThan(TIER_MULTIPLIERS[2]);
    expect(TIER_MULTIPLIERS[2]).toBeGreaterThan(TIER_MULTIPLIERS[3]);
    expect(TIER_MULTIPLIERS[3]).toBeGreaterThan(TIER_MULTIPLIERS[4]);
    expect(TIER_MULTIPLIERS[1]).toBe(1.0);
  });

  test("earnMultiplier combines tier and VIP", () => {
    expect(earnMultiplier(1, "none")).toBeCloseTo(1.0);
    expect(earnMultiplier(1, "gold")).toBeCloseTo(2.0);
    expect(earnMultiplier(4, "none")).toBeCloseTo(TIER_MULTIPLIERS[4]);
    // Unknown VIP falls back to 1x.
    expect(earnMultiplier(2, "unknown")).toBeCloseTo(TIER_MULTIPLIERS[2]);
  });

  test("rewardedAdCoins is tier-adjusted and at least 1", () => {
    const t1 = rewardedAdCoins(1, "none");
    const t4 = rewardedAdCoins(4, "none");
    expect(t1).toBe(ECONOMY.baseRewardedAdCoins);
    expect(t1).toBeGreaterThan(t4);
    expect(t4).toBeGreaterThanOrEqual(1);
  });

  test("developer margin: user share never exceeds provider payout", () => {
    expect(ECONOMY.offerwallUserSharePercent).toBeGreaterThan(0);
    expect(ECONOMY.offerwallUserSharePercent).toBeLessThan(1);
  });

  test("levelForXp is monotonic non-decreasing", () => {
    let prev = -1;
    for (let xp = 0; xp <= 5000; xp += 250) {
      const lvl = levelForXp(xp);
      expect(lvl).toBeGreaterThanOrEqual(prev);
      prev = lvl;
    }
  });

  test("effectiveVipLevel treats a lapsed subscription as none", () => {
    const past = Timestamp.fromMillis(Date.now() - 1000);
    const future = Timestamp.fromMillis(Date.now() + 1000);
    expect(effectiveVipLevel({vipLevel: "gold", vipExpiresAt: past})).toBe("none");
    expect(effectiveVipLevel({vipLevel: "gold", vipExpiresAt: future})).toBe("gold");
    // No expiry at all means permanent (never-VIP, or an admin grant).
    expect(effectiveVipLevel({vipLevel: "diamond", vipExpiresAt: null})).toBe("diamond");
    expect(effectiveVipLevel({vipLevel: "none"})).toBe("none");
  });

  test("vipRank orders tiers and maxAdsPerDay scales with them", () => {
    expect(vipRank("none")).toBe(0);
    expect(vipRank("diamond")).toBeGreaterThan(vipRank("gold"));
    expect(vipRank("gold")).toBeGreaterThan(vipRank("silver"));
    expect(vipRank("silver")).toBeGreaterThan(vipRank("bronze"));
    expect(maxAdsPerDay("diamond")).toBeGreaterThan(maxAdsPerDay("none"));
    expect(maxAdsPerDay("none")).toBe(ECONOMY.maxRewardedAdsPerDay);
  });
});
