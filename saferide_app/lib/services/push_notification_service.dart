import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';

class PushNotificationService {
  PushNotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) {
      // Foreground handling can be expanded to local notifications later.
      // For now, this keeps stream active and ensures plugin initialization.
      // ignore: avoid_print
      print('Push foreground message: ${message.messageId}');
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _initialized = true;
  }

  Future<void> syncDeviceToken() async {
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _registerToken(token);
    messaging.onTokenRefresh.listen((newToken) async {
      await _registerToken(newToken);
    });
  }

  Future<void> _registerToken(String token) async {
    await _apiClient.post(
      '/notifications/device-token',
      body: {
        'token': token,
        'platform': 'android',
      },
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler placeholder for future local notifications routing.
}
