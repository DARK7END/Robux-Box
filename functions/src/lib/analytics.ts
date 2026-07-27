import {AggregateField, Timestamp} from "firebase-admin/firestore";
import {db, cols} from "./admin";

/**
 * Computes platform analytics with Firestore aggregation queries (server-side
 * sum/count — no full-collection reads) and writes a single summary document at
 * `analytics/summary` for the admin dashboard to read cheaply.
 */
export async function computeAnalytics(): Promise<Record<string, number>> {
  const dayAgo = Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);

  const [users, dau, wallets, paid, pending] = await Promise.all([
    cols.users.count().get(),
    cols.users.where("lastActiveAt", ">=", dayAgo).count().get(),
    cols.wallets
      .aggregate({
        coins: AggregateField.sum("coins"),
        pending: AggregateField.sum("pendingCoins"),
        earned: AggregateField.sum("lifetimeEarned"),
        spent: AggregateField.sum("lifetimeSpent"),
      })
      .get(),
    cols.redemptions
      .where("status", "==", "paid")
      .aggregate({
        count: AggregateField.count(),
        coins: AggregateField.sum("coinCost"),
        value: AggregateField.sum("faceValue"),
      })
      .get(),
    cols.redemptions.where("status", "==", "pending").count().get(),
  ]);

  const summary = {
    userCount: users.data().count,
    dau: dau.data().count,
    coinsInCirculation: wallets.data().coins ?? 0,
    pendingCoins: wallets.data().pending ?? 0,
    lifetimeEarned: wallets.data().earned ?? 0,
    lifetimeSpent: wallets.data().spent ?? 0,
    paidRedemptions: paid.data().count,
    payoutCoins: paid.data().coins ?? 0,
    payoutValue: Math.round((paid.data().value ?? 0) * 100) / 100,
    pendingRedemptions: pending.data().count,
    updatedAt: Date.now(),
  };

  await db.doc("analytics/summary").set(summary, {merge: true});
  return summary;
}
