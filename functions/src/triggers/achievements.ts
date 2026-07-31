import * as functionsV1 from "firebase-functions/v1";
import {userDoc, Timestamp} from "../lib/admin";
import {creditWallet} from "../lib/wallet";

interface WalletData {
  adsWatchedTotal?: number;
  offersCompletedTotal?: number;
  lifetimeSpent?: number;
}

interface UserData {
  streakCount?: number;
  referralCount?: number;
  level?: number;
}

interface AchievementDef {
  id: string;
  title: string;
  description: string;
  icon: string;
  rewardCoins: number;
  target: number;
  progress: (wallet: WalletData, user: UserData) => number;
}

/**
 * The achievements catalog. `icon` is a stable key the client maps to a
 * Material icon (see AchievementsScreen._icon) — never a literal asset path,
 * so this list can grow without a client release.
 */
const CATALOG: AchievementDef[] = [
  {
    id: "first_earn",
    title: "First Steps",
    description: "Watch your first rewarded ad",
    icon: "first_earn",
    rewardCoins: 50,
    target: 1,
    progress: (w) => w.adsWatchedTotal ?? 0,
  },
  {
    id: "streak",
    title: "On a Roll",
    description: "Reach a 7-day streak",
    icon: "streak",
    rewardCoins: 100,
    target: 7,
    progress: (_w, u) => u.streakCount ?? 0,
  },
  {
    id: "offers",
    title: "Task Master",
    description: "Complete your first offer",
    icon: "offers",
    rewardCoins: 100,
    target: 1,
    progress: (w) => w.offersCompletedTotal ?? 0,
  },
  {
    id: "referrals",
    title: "Recruiter",
    description: "Invite your first friend",
    icon: "referrals",
    rewardCoins: 150,
    target: 1,
    progress: (_w, u) => u.referralCount ?? 0,
  },
  {
    id: "redeem",
    title: "Cashing In",
    description: "Redeem your first reward",
    icon: "redeem",
    rewardCoins: 100,
    target: 1,
    progress: (w) => ((w.lifetimeSpent ?? 0) > 0 ? 1 : 0),
  },
  {
    id: "level",
    title: "Leveling Up",
    description: "Reach level 5",
    icon: "level",
    rewardCoins: 150,
    target: 5,
    progress: (_w, u) => u.level ?? 0,
  },
];

/**
 * Re-evaluates the achievement catalog whenever a wallet changes and credits
 * `rewardCoins` the moment one is newly unlocked.
 *
 * Triggered on `wallets/{uid}` rather than `users/{uid}` because every
 * economic event in the app — ads, offers, streak claims, referral bonuses,
 * redemptions — always writes the wallet doc via `creditWallet`/
 * `debitWallet` (see lib/wallet.ts), even when the achievement's own signal
 * (streakCount, referralCount, level) lives on the user doc: those fields
 * are always written *before* the paired wallet write completes, so this
 * trigger reads them fresh every time it fires. That makes this a single,
 * comprehensive hook instead of one trigger per earning path.
 *
 * Crediting an unlock writes the wallet doc again, which re-fires this
 * function — but the newly-unlocked achievement is already marked
 * `unlockedAt` from the first pass, so the second pass finds nothing new to
 * credit and does not write the wallet, which is what stops the recursion.
 */
export const syncAchievementsOnWalletWrite = functionsV1.firestore
  .document("wallets/{uid}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return; // wallet deleted (account deletion)
    const uid = context.params.uid as string;
    const wallet = (change.after.data() ?? {}) as WalletData;

    const uSnap = await userDoc(uid).get();
    const user = (uSnap.data() ?? {}) as UserData;

    const achievementsCol = userDoc(uid).collection("achievements");
    const existingSnap = await achievementsCol.get();
    const existingById = new Map(existingSnap.docs.map((d) => [d.id, d.data()]));

    const now = Timestamp.now();
    const writes: Array<Promise<unknown>> = [];
    const unlocks: AchievementDef[] = [];

    CATALOG.forEach((def, index) => {
      const progress = Math.min(def.progress(wallet, user), def.target);
      const prior = existingById.get(def.id);
      const wasUnlocked = !!prior?.unlockedAt;
      const nowUnlocked = progress >= def.target;
      const unlockedAt = wasUnlocked ? prior!.unlockedAt : (nowUnlocked ? now : null);

      // Skip the write entirely if nothing this achievement cares about
      // actually changed — most single events only move one of the six.
      if (prior && prior.progress === progress && !!prior.unlockedAt === !!unlockedAt) {
        return;
      }

      writes.push(achievementsCol.doc(def.id).set({
        title: def.title,
        description: def.description,
        icon: def.icon,
        rewardCoins: def.rewardCoins,
        target: def.target,
        sortOrder: index,
        progress,
        unlockedAt,
      }, {merge: true}));

      if (nowUnlocked && !wasUnlocked) {
        unlocks.push(def);
      }
    });

    await Promise.all(writes);

    for (const def of unlocks) {
      await creditWallet({
        uid,
        amount: def.rewardCoins,
        type: "achievement",
        title: `Achievement unlocked: ${def.title}`,
        referenceId: def.id,
      });
    }
  });
