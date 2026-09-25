import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as path from 'path';

const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

try {
  initializeApp({
    credential: cert(require(serviceAccountPath))
  });
  console.log("Firebase Admin initialized successfully.");
} catch (error) {
  console.error("Firebase Admin initialization error:", error);
}

/**
 * Sends a push notification to a specific FCM token
 */
export const sendPushNotification = async (fcmToken: string, title: string, body: string, data: any = {}) => {
  if (!fcmToken) {
    console.error("No FCM token provided for notification");
    return false;
  }

  try {
    const message = {
      notification: {
        title,
        body,
      },
      data,
      token: fcmToken,
    };

    const response = await getMessaging().send(message);
    console.log("Successfully sent notification:", response);
    return true;
  } catch (error) {
    console.error("Error sending push notification:", error);
    return false;
  }
};

