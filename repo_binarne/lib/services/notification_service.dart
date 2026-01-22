import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (kIsWeb) {
      await _requestWebPermission();
    } else {
      await _requestMobilePermission();
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? 'BKFN_ic4RRxyjQFnfUuqOPDH3MKDGBdtCCyChMSbKezvTnjBtGdbNwynnEf7JPhtNhuH59M4XFeJkVkdC6tP9CI' : null,
    );

    if (token != null) {
      debugPrint('FCM Token: $token');
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
