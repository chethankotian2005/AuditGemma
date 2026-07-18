import 'package:flutter/foundation.dart';

/// FCM push notification stub.
///
/// Firebase packages require google-services.json (Android) and
/// GoogleService-Info.plist (iOS). This service is structured so the app
/// runs without Firebase config files — Firebase init is gated behind
/// a try-catch. The "simulate new case" button triggers a local callback
/// instead of a real push.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  /// Callback when a simulated push arrives (for demo)
  VoidCallback? onNewCaseNotification;

  /// Initialize FCM — gated behind try-catch for missing Firebase config
  Future<void> initialize() async {
    try {
      // NOTE: Full FCM requires google-services.json which is omitted for this demo.
      // If configured, the below will request permission and get the FCM token.
      
      // await Firebase.initializeApp();
      // final messaging = FirebaseMessaging.instance;
      // await messaging.requestPermission();
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      // FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      // final token = await messaging.getToken();
      // debugPrint('FCM Token: $token'); // Save this token in backend for the SME
      
      debugPrint('NotificationService: Firebase not configured fully, using stub');
    } catch (e) {
      debugPrint('NotificationService: Firebase init failed: $e');
    }
  }

  /// Simulate a push notification for demo purposes.
  /// Called by the "Simulate new case" test button in the officer view.
  void simulateNewCasePush() {
    debugPrint('NotificationService: Simulating new case push');
    onNewCaseNotification?.call();
  }

  // ignore: unused_element
  // static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  //   debugPrint('Background FCM: ${message.notification?.title}');
  // }

  // void _handleForegroundMessage(RemoteMessage message) {
  //   debugPrint('Foreground FCM: ${message.notification?.title}');
  //   onNewCaseNotification?.call();
  // }
}
