import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await _requestWebPermission().timeout(const Duration(seconds: 5));
      } else {
        await _requestMobilePermission().timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? 'BKFN_ic4RRxyjQFnfUuqOPDH3MKDGBdtCCyChMSbKezvTnjBtGdbNwynnEf7JPhtNhuH59M4XFeJkVkdC6tP9CI' : null,
      ).timeout(const Duration(seconds: 10));

      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }
  }

  Future<void> _requestWebPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _requestMobilePermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Otrzymano wiadomość: ${message.notification?.title}');
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Otwarto aplikację z powiadomienia: ${message.notification?.title}');
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) {
      await _messaging.subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }
}
