import {userDoc, messaging, Timestamp, cols} from "./admin";

export interface NotifyPayload {
  type: string;
  title: string;
  body: string;
  deeplink?: string;
  imageUrl?: string;
}

/**
 * Persists an in-app notification and sends a push to all of the user's
 * registered device tokens. Push failures never throw — the in-app record is
 * the source of truth and the notification centre still shows it.
 */
export async function sendUserNotification(
  uid: string,
  payload: NotifyPayload,
): Promise<void> {
  // 1) Persist to the notification centre.
  await userDoc(uid).collection("notifications").add({
    type: payload.type,
    title: payload.title,
    body: payload.body,
    deeplink: payload.deeplink ?? "",
    imageUrl: payload.imageUrl ?? "",
    isRead: false,
    createdAt: Timestamp.now(),
  });

  // 2) Best-effort push to every registered device token.
  try {
    const devices = await userDoc(uid).collection("devices").get();
    const tokens = devices.docs
      .map((d) => d.data().fcmToken as string | undefined)
      .filter((t): t is string => !!t);
    if (tokens.length === 0) return;

    await messaging.sendEachForMulticast({
      tokens,
      notification: {title: payload.title, body: payload.body},
      data: {
        deeplink: payload.deeplink ?? "",
        type: payload.type,
      },
      android: {priority: "high", notification: {channelId: "robuxbox_default"}},
    });
  } catch {
    // ignore push failures
  }
}

/**
 * Emails the configured admin address(es) — used for events an admin must act
 * on manually, like a new redemption request awaiting fulfilment.
 *
 * Queues the message via the Firestore "Trigger Email" extension (writes to
 * the `mail` collection; the extension must be installed with an SMTP
 * connection for delivery to actually happen — see docs/DEPLOYMENT.md).
 * Recipients come from `config/notifications`'s `adminEmails` array, which is
 * empty by default: this no-ops silently until an admin sets it, and never
 * throws, so a notification failure can never block the caller's real work.
 */
export async function notifyAdmins(subject: string, text: string): Promise<void> {
  try {
    const snap = await cols.config.doc("notifications").get();
    const to = (snap.data()?.adminEmails as string[] | undefined) ?? [];
    if (to.length === 0) return;
    await cols.mail.add({to, message: {subject, text}});
  } catch {
    // best-effort — never block the caller.
  }
}

/** Sends a push to a broadcast topic (used by scheduled reminder campaigns). */
export async function sendTopic(
  topic: string,
  title: string,
  body: string,
  deeplink = "",
): Promise<void> {
  try {
    await messaging.send({
      topic,
      notification: {title, body},
      data: {deeplink, type: "reminder"},
      android: {priority: "high", notification: {channelId: "robuxbox_default"}},
    });
  } catch {
    // ignore
  }
}
