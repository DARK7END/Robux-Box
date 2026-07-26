import {onCall, HttpsError} from "firebase-functions/v2/https";
import {userDoc, Timestamp} from "../lib/admin";
import {ECONOMY, weightedPick} from "../lib/economy";
import {creditWallet} from "../lib/wallet";
import {requireAuth, rateLimit} from "../lib/security";

const opts = {enforceAppCheck: true, region: "us-central1"} as const;

function isSameUtcDay(a: Date, b: Date): boolean {
  return (
    a.getUTCFullYear() === b.getUTCFullYear() &&
    a.getUTCMonth() === b.getUTCMonth() &&
    a.getUTCDate() === b.getUTCDate()
  );
}

/**
 * Plays a daily free game (spin wheel or lucky chest). One free play per game
 * per UTC day, enforced server-side. The server picks the prize from a weighted
 * table and credits it atomically, then returns the winning segment index so the
 * client can animate the wheel/chest to land on exactly that prize.
 */
export const playDailyGame = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const game = String(req.data?.game ?? "spin");
  if (game !== "spin" && game !== "chest") {
    throw new HttpsError("invalid-argument", "Unknown game.");
  }
  await rateLimit(uid, `game_${game}`, 5, 86_400);

  const uRef = userDoc(uid);
  const field = game === "spin" ? "lastSpinAt" : "lastChestAt";
  const snap = await uRef.get();
  const last = (snap.data()?.[field] as Timestamp | undefined)?.toDate();
  if (last && isSameUtcDay(last, new Date())) {
    throw new HttpsError(
      "failed-precondition",
      "You've already played today. Come back tomorrow!",
    );
  }

  const prizes = game === "spin" ? ECONOMY.spinPrizes : ECONOMY.chestPrizes;
  const weights = game === "spin" ? ECONOMY.spinWeights : ECONOMY.chestWeights;
  const index = weightedPick(weights);
  const coins = prizes[index];

  await uRef.set({[field]: Timestamp.now()}, {merge: true});

  const result = await creditWallet({
    uid,
    amount: coins,
    type: game === "spin" ? "dailyBonus" : "dailyBonus",
    title: game === "spin" ? "Spin Wheel" : "Lucky Chest",
    metadata: {game, index},
  });

  return {...result, prizeIndex: index, prizeCoins: coins};
});
