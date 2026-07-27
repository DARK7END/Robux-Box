import * as crypto from "crypto";
import {CallableRequest, HttpsError} from "firebase-functions/v2/https";
import {db, cols, userDoc, FieldValue, Timestamp} from "./admin";
import {ECONOMY} from "./economy";

/** Asserts the caller is authenticated and returns their uid. */
export function requireAuth(req: CallableRequest): string {
  if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Please sign in to continue.");
  }
  return req.auth.uid;
}

/** Asserts the caller holds the admin custom claim. */
export function requireAdmin(req: CallableRequest): string {
  const uid = requireAuth(req);
  if (req.auth?.token?.admin !== true) {
    throw new HttpsError("permission-denied", "Admin privileges required.");
  }
  return uid;
}

/**
 * Issues a single-use, server-signed nonce bound to a user + purpose, stored
 * with a short TTL. This is the primary anti-replay mechanism for earning: a
 * credit can only be confirmed against a nonce the server itself issued and has
 * not yet consumed.
 */
export async function issueNonce(
  uid: string,
  purpose: string,
  extra: Record<string, unknown> = {},
): Promise<string> {
  const nonce = crypto.randomBytes(24).toString("hex");
  const ref = db.collection("nonces").doc(nonce);
  await ref.set({
    uid,
    purpose,
    used: false,
    createdAt: Timestamp.now(),
    expiresAt: Timestamp.fromMillis(Date.now() + ECONOMY.nonceTtlSeconds * 1000),
    ...extra,
  });
  return nonce;
}

/**
 * Atomically consumes a nonce. Throws if it is missing, for a different user,
 * for a different purpose, already used, or expired. Marking used and checking
 * validity share one transaction so a nonce cannot be redeemed twice.
 */
export async function consumeNonce(
  uid: string,
  nonce: string,
  purpose: string,
): Promise<Record<string, unknown>> {
  if (!nonce) throw new HttpsError("invalid-argument", "Missing nonce.");
  const ref = db.collection("nonces").doc(nonce);
  return db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    if (!snap.exists) {
      throw new HttpsError("failed-precondition", "Invalid session token.");
    }
    const data = snap.data()!;
    if (data.uid !== uid || data.purpose !== purpose) {
      throw new HttpsError("permission-denied", "Session token mismatch.");
    }
    if (data.used === true) {
      throw new HttpsError("failed-precondition", "This reward was already claimed.");
    }
    if ((data.expiresAt as Timestamp).toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Session expired. Try again.");
    }
    t.update(ref, {used: true, usedAt: Timestamp.now()});
    return data;
  });
}

export interface DeviceContext {
  deviceId: string;
  platform?: string;
  osVersion?: string;
  model?: string;
  appVersion?: string;
  isPhysicalDevice?: boolean;
  isDebug?: boolean;
  integrityScore?: number;
}

/**
 * Records/updates the device that made an earn request and enforces the
 * per-account device cap. Low integrity scores or excess devices raise a fraud
 * flag (soft — logged for review, not necessarily blocking).
 */
export async function recordDevice(
  uid: string,
  device: DeviceContext,
): Promise<void> {
  if (!device?.deviceId) return;
  const devRef = userDoc(uid).collection("devices").doc(device.deviceId);
  await devRef.set(
    {
      ...device,
      lastSeenAt: Timestamp.now(),
      firstSeenAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  // Enforce device cap.
  const devices = await userDoc(uid).collection("devices").count().get();
  if (devices.data().count > ECONOMY.maxDevicesPerAccount) {
    await flagFraud(uid, "too_many_devices", {count: devices.data().count});
  }

  // Same physical device shared across many accounts is a strong abuse signal.
  const shared = await db
    .collectionGroup("devices")
    .where("deviceId", "==", device.deviceId)
    .count()
    .get();
  if (shared.data().count > ECONOMY.maxDevicesPerAccount) {
    await flagFraud(uid, "shared_device", {
      deviceId: device.deviceId,
      accounts: shared.data().count,
    });
  }
}

/** Rejects requests from devices failing basic integrity heuristics. */
export function assertIntegrity(device?: DeviceContext): void {
  if (!device) return;
  if (
    typeof device.integrityScore === "number" &&
    device.integrityScore < ECONOMY.minIntegrityScore
  ) {
    throw new HttpsError(
      "permission-denied",
      "This device failed a security check.",
    );
  }
}

/**
 * A simple fixed-window rate limiter backed by a counter document. Throws
 * `resource-exhausted` when the cap for [action] in [windowSeconds] is passed.
 */
export async function rateLimit(
  uid: string,
  action: string,
  max: number,
  windowSeconds: number,
): Promise<void> {
  const bucket = Math.floor(Date.now() / (windowSeconds * 1000));
  const ref = db
    .collection("rate_limits")
    .doc(`${uid}_${action}_${bucket}`);
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const count = (snap.data()?.count as number) ?? 0;
    if (count >= max) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many attempts. Please slow down.",
      );
    }
    t.set(
      ref,
      {
        count: count + 1,
        expiresAt: Timestamp.fromMillis((bucket + 1) * windowSeconds * 1000),
      },
      {merge: true},
    );
  });
}

/** Records a fraud signal for admin review and analytics. */
export async function flagFraud(
  uid: string,
  reason: string,
  details: Record<string, unknown> = {},
): Promise<void> {
  await cols.fraudFlags.add({
    uid,
    reason,
    details,
    createdAt: Timestamp.now(),
    resolved: false,
  });
}

/** Detects abnormal earning velocity (coins/minute) as an abuse signal. */
export async function checkVelocity(uid: string, coins: number): Promise<void> {
  const oneMinAgo = Timestamp.fromMillis(Date.now() - 60_000);
  const recent = await userDoc(uid)
    .collection("transactions")
    .where("direction", "==", "credit")
    .where("createdAt", ">=", oneMinAgo)
    .get();
  const sum =
    recent.docs.reduce((acc, d) => acc + ((d.data().amount as number) ?? 0), 0) +
    coins;
  if (sum > ECONOMY.suspiciousVelocityCoinsPerMinute) {
    await flagFraud(uid, "high_velocity", {coinsPerMinute: sum});
    throw new HttpsError(
      "resource-exhausted",
      "Unusual activity detected. Please try again later.",
    );
  }
}
