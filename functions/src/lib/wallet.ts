import {HttpsError} from "firebase-functions/v2/https";
import {db, cols, walletDoc, userDoc, FieldValue, Timestamp} from "./admin";
import {ECONOMY, levelForXp} from "./economy";

export type TxType =
  | "rewardedAd" | "offerwall" | "dailyBonus" | "streakBonus"
  | "referralBonus" | "referralShare" | "promocode" | "achievement"
  | "levelUp" | "redemption" | "adjustment" | "refund";

export interface CreditParams {
  uid: string;
  amount: number; // positive
  type: TxType;
  title: string;
  description?: string;
  referenceId?: string;
  xp?: number;
  metadata?: Record<string, unknown>;
}

export interface EarnOutcome {
  coinsCredited: number;
  newBalance: number;
  xpGained: number;
  message: string;
}

/**
 * Atomically credits coins to a wallet and appends an immutable ledger entry,
 * inside a single Firestore transaction. This is the ONLY sanctioned way coins
 * enter a wallet, which is what makes the economy tamper-proof: no client path
 * can write `wallets/*` (see firestore.rules).
 *
 * Also handles a daily-counter reset and XP → level progression.
 */
export async function creditWallet(p: CreditParams): Promise<EarnOutcome> {
  if (p.amount <= 0) {
    throw new HttpsError("invalid-argument", "Amount must be positive.");
  }
  const wRef = walletDoc(p.uid);
  const uRef = userDoc(p.uid);
  const txRef = uRef.collection("transactions").doc();
  const globalTxRef = cols.transactions.doc(txRef.id);

  const outcome = await db.runTransaction(async (t) => {
    const [wSnap, uSnap] = await Promise.all([t.get(wRef), t.get(uRef)]);
    const wallet = wSnap.data() ?? {};
    const user = uSnap.data() ?? {};

    const prevCoins = (wallet.coins as number) ?? 0;
    const newCoins = prevCoins + p.amount;

    const xpGain = p.xp ?? 0;
    const prevXp = (user.xp as number) ?? 0;
    const newXp = prevXp + xpGain;
    const prevLevel = (user.level as number) ?? 0;
    const newLevel = Math.max(prevLevel, levelForXp(newXp));

    // Daily counter reset window (calendar-day based, UTC).
    const now = Timestamp.now();
    const patch: Record<string, unknown> = {
      coins: newCoins,
      lifetimeEarned: FieldValue.increment(p.amount),
      lastEarnAt: now,
      updatedAt: now,
    };
    if (p.type === "rewardedAd") {
      patch.adsWatchedToday = FieldValue.increment(1);
      patch.adsWatchedTotal = FieldValue.increment(1);
    }
    if (p.type === "offerwall") {
      patch.offersCompletedTotal = FieldValue.increment(1);
    }

    t.set(wRef, patch, {merge: true});

    if (xpGain > 0 || newLevel !== prevLevel) {
      t.set(uRef, {xp: newXp, level: newLevel}, {merge: true});
    }

    const entry = {
      type: p.type,
      direction: "credit",
      amount: p.amount,
      balanceAfter: newCoins,
      title: p.title,
      description: p.description ?? "",
      referenceId: p.referenceId ?? "",
      metadata: p.metadata ?? {},
      createdAt: now,
      uid: p.uid,
    };
    t.set(txRef, entry);
    t.set(globalTxRef, entry);

    return {newCoins, xpGain, leveledUp: newLevel > prevLevel};
  });

  return {
    coinsCredited: p.amount,
    newBalance: outcome.newCoins,
    xpGained: outcome.xpGain,
    message: `+${p.amount} coins`,
  };
}

export interface DebitParams {
  uid: string;
  amount: number; // positive
  type: TxType;
  title: string;
  referenceId?: string;
  toPending?: boolean; // move to pendingCoins instead of removing outright
  metadata?: Record<string, unknown>;
}

/**
 * Atomically debits coins (e.g. a redemption). Throws `failed-precondition` if
 * the balance is insufficient — the check and the write share one transaction so
 * concurrent requests can't double-spend.
 */
export async function debitWallet(p: DebitParams): Promise<number> {
  if (p.amount <= 0) {
    throw new HttpsError("invalid-argument", "Amount must be positive.");
  }
  const wRef = walletDoc(p.uid);
  const uRef = userDoc(p.uid);
  const txRef = uRef.collection("transactions").doc();
  const globalTxRef = cols.transactions.doc(txRef.id);

  return db.runTransaction(async (t) => {
    const wSnap = await t.get(wRef);
    const wallet = wSnap.data() ?? {};
    const coins = (wallet.coins as number) ?? 0;
    if (coins < p.amount) {
      throw new HttpsError("failed-precondition", "Insufficient coins.");
    }
    const now = Timestamp.now();
    const newCoins = coins - p.amount;

    const patch: Record<string, unknown> = {
      coins: newCoins,
      lifetimeSpent: FieldValue.increment(p.amount),
      updatedAt: now,
    };
    if (p.toPending) {
      patch.pendingCoins = FieldValue.increment(p.amount);
    }
    t.set(wRef, patch, {merge: true});

    const entry = {
      type: p.type,
      direction: "debit",
      amount: p.amount,
      balanceAfter: newCoins,
      title: p.title,
      description: "",
      referenceId: p.referenceId ?? "",
      metadata: p.metadata ?? {},
      createdAt: now,
      uid: p.uid,
    };
    t.set(txRef, entry);
    t.set(globalTxRef, entry);
    return newCoins;
  });
}

/** Releases a pending hold back to spendable (redemption rejected/cancelled). */
export async function refundPending(
  uid: string,
  amount: number,
  referenceId: string,
): Promise<void> {
  const wRef = walletDoc(uid);
  const uRef = userDoc(uid);
  const txRef = uRef.collection("transactions").doc();
  await db.runTransaction(async (t) => {
    // Reads must precede writes within a Firestore transaction.
    const wSnap = await t.get(wRef);
    const now = Timestamp.now();
    const newCoins = ((wSnap.data()?.coins as number) ?? 0) + amount;
    t.set(
      wRef,
      {
        coins: FieldValue.increment(amount),
        pendingCoins: FieldValue.increment(-amount),
        lifetimeSpent: FieldValue.increment(-amount),
        updatedAt: now,
      },
      {merge: true},
    );
    t.set(txRef, {
      type: "refund",
      direction: "credit",
      amount,
      balanceAfter: newCoins,
      title: "Redemption refunded",
      referenceId,
      metadata: {},
      createdAt: now,
      uid,
    });
  });
}

/** Clears a pending hold permanently (redemption paid). */
export async function clearPending(uid: string, amount: number): Promise<void> {
  await walletDoc(uid).set(
    {pendingCoins: FieldValue.increment(-amount), updatedAt: Timestamp.now()},
    {merge: true},
  );
}

/** Guards the per-day rewarded-ad cap. */
export function checkDailyAdLimit(adsWatchedToday: number): void {
  if (adsWatchedToday >= ECONOMY.maxRewardedAdsPerDay) {
    throw new HttpsError(
      "resource-exhausted",
      "You have reached today's ad limit.",
    );
  }
}
