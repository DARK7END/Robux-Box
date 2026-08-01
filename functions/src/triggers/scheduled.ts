import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, cols, Timestamp} from "../lib/admin";
import {sendTopic} from "../lib/notify";
import {computeAnalytics} from "../lib/analytics";

const region = "us-central1";

/** Hourly analytics rollup for the admin dashboard. */
export const analyticsAggregate = onSchedule(
  {schedule: "0 * * * *", timeZone: "Etc/UTC", region},
  async () => {
    await computeAnalytics();
  },
);

/**
 * Midnight UTC: reset per-day counters (ads watched today) in batches. Keeps the
 * daily ad cap accurate without per-read date math.
 */
export const resetDailyCounters = onSchedule(
  {schedule: "0 0 * * *", timeZone: "Etc/UTC", region},
  async () => {
    const snap = await cols.wallets.where("adsWatchedToday", ">", 0).get();
    let batch = db.batch();
    let n = 0;
    for (const doc of snap.docs) {
      batch.set(doc.ref, {adsWatchedToday: 0, dailyResetAt: Timestamp.now()},
        {merge: true});
      if (++n % 400 === 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    if (n % 400 !== 0) await batch.commit();
    console.log(`Reset daily counters for ${n} wallets`);
  },
);

/**
 * Sweeps lapsed VIP subscriptions back to `none`. `AppUser.effectiveVipLevel`
 * / `effectiveVipLevel()` already treat a past `vipExpiresAt` as expired
 * everywhere earnings/gating are decided, so this job isn't load-bearing for
 * correctness — it just keeps the stored field (and anything that reads it
 * naively, like the leaderboard snapshot below) honest within a day.
 * Admin-granted VIP (`setVipLevel`) has no `vipExpiresAt` and is untouched.
 */
export const vipExpiryDowngrade = onSchedule(
  {schedule: "30 0 * * *", timeZone: "Etc/UTC", region},
  async () => {
    const snap = await cols.users.where("vipExpiresAt", "<=", Timestamp.now()).get();
    let batch = db.batch();
    let n = 0;
    for (const doc of snap.docs) {
      const level = doc.data().vipLevel as string | undefined;
      if (!level || level === "none") continue;
      batch.set(doc.ref, {vipLevel: "none", vipExpiresAt: null}, {merge: true});
      if (++n % 400 === 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    if (n % 400 !== 0) await batch.commit();
    console.log(`Downgraded ${n} lapsed VIP subscriptions`);
  },
);

/**
 * Rebuilds the daily/weekly/all-time leaderboards from the wallet lifetime and
 * period aggregates. Runs hourly so ranks stay fresh without expensive live
 * queries on the client.
 */
export const aggregateLeaderboards = onSchedule(
  {schedule: "0 * * * *", timeZone: "Etc/UTC", region},
  async () => {
    // All-time uses lifetimeEarned; daily/weekly use rolling transaction sums.
    await buildAllTime();
    await buildRolling("daily", 1);
    await buildRolling("weekly", 7);
  },
);

async function buildAllTime(): Promise<void> {
  const top = await cols.wallets.orderBy("lifetimeEarned", "desc").limit(100).get();
  await writeEntries("all_time", top.docs.map((d) => ({
    uid: d.id, score: (d.data().lifetimeEarned as number) ?? 0,
  })));
}

async function buildRolling(period: string, days: number): Promise<void> {
  const since = Timestamp.fromMillis(Date.now() - days * 86_400_000);
  const txs = await db.collectionGroup("transactions")
    .where("direction", "==", "credit")
    .where("createdAt", ">=", since)
    .get();
  const totals = new Map<string, number>();
  for (const doc of txs.docs) {
    const d = doc.data();
    const uid = d.uid as string;
    if (!uid) continue;
    totals.set(uid, (totals.get(uid) ?? 0) + ((d.amount as number) ?? 0));
  }
  const ranked = [...totals.entries()]
    .map(([uid, score]) => ({uid, score}))
    .sort((a, b) => b.score - a.score)
    .slice(0, 100);
  await writeEntries(period, ranked);
}

async function writeEntries(
  period: string,
  ranked: {uid: string; score: number}[],
): Promise<void> {
  const col = cols.leaderboards.doc(period).collection("entries");
  // Enrich with profile data and write ranks.
  let batch = db.batch();
  let n = 0;
  for (let i = 0; i < ranked.length; i++) {
    const {uid, score} = ranked[i];
    const user = (await cols.users.doc(uid).get()).data() ?? {};
    batch.set(col.doc(uid), {
      rank: i + 1,
      score,
      displayName: user.displayName ?? "Player",
      photoUrl: user.photoUrl ?? "",
      countryCode: user.countryCode ?? "",
      vipLevel: user.vipLevel ?? "none",
      updatedAt: Timestamp.now(),
    });
    if (++n % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (n % 400 !== 0) await batch.commit();
  await cols.leaderboards.doc(period).set(
    {updatedAt: Timestamp.now(), size: ranked.length}, {merge: true});
}

// --------------------------- Reminder campaigns ----------------------------
// Topic subscriptions are managed client-side in NotificationService.

export const dailyReminder = onSchedule(
  {schedule: "0 18 * * *", timeZone: "Etc/UTC", region},
  async () => {
    await sendTopic("reminder_daily", "Your daily reward is ready 🎁",
      "Come back to claim your streak bonus before it resets!", "/home");
  },
);

export const rewardReminder = onSchedule(
  {schedule: "0 13 * * *", timeZone: "Etc/UTC", region},
  async () => {
    await sendTopic("reminder_rewards", "New offers just dropped 💰",
      "Fresh high-paying offers are waiting for you.", "/earn");
  },
);

export const vipReminder = onSchedule(
  {schedule: "0 11 * * 6", timeZone: "Etc/UTC", region},
  async () => {
    await sendTopic("reminder_vip", "VIP boost waiting ⭐",
      "Upgrade to earn up to 1.5x on everything.", "/vip");
  },
);

export const referralReminder = onSchedule(
  {schedule: "0 15 * * 0", timeZone: "Etc/UTC", region},
  async () => {
    await sendTopic("reminder_referral", "Invite friends, earn coins 👥",
      "Share your code and both of you get rewarded.", "/referrals");
  },
);
