import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';

/// Top-level handler required by firebase_messaging for background/terminated messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase automatically shows the notification from the data payload when
  // the app is in the background or terminated — nothing extra needed here.
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _api = ApiClient();

  static const _androidChannelId = 'saferide_alerts';
  static const _androidChannelName = 'SafeRide Alerts';

  /// Call once after Firebase.initializeApp() and after the user has logged in.
  Future<void> initialize() async {
    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show notifications while app is in foreground on iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up local notifications for Android foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show local notification when app is in foreground (Android only — iOS
    // is handled by setForegroundNotificationPresentationOptions above)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    // Register device token with the backend
    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);

    // Re-register whenever the token rotates
    _messaging.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.patch('/users/me/fcm-token', body: {'token': token});
    } catch (_) {
      // Swallow — the token will be registered on next successful launch
    }
  }
}
