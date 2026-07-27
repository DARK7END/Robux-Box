import {userDoc, messaging, Timestamp} from "./admin";

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
