import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const _channelId   = 'vitd_channel';
  static const _channelName = 'Vitamin D Alerts';

  Future<void> init() async {
    // Request FCM permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Init local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // FCM background & foreground handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Print token for analytics targeting
    try {
      final token = await _fcm.getToken();
      print("FCM Token: $token");
    } catch (_) {}
  }

  void _handleForeground(RemoteMessage msg) {
    final n = msg.notification;
    if (n == null) return;
    _local.show(
      msg.hashCode,
      n.title, n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high, priority: Priority.high,
        ),
      ),
    );
  }

  /// Schedule daily exposure window reminder at given hour:minute
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Uses local notifications — for full scheduling add flutter_local_notifications TZDateTime support
    await _local.show(
      1, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }

  Future<void> sendLowVitDAlert(double totalIU) async {
    await _local.show(
      2,
      '⚠️ Low Vitamin D Today',
      'You\'ve only reached ${totalIU.round()} IU. Step outside if possible.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high, priority: Priority.high,
        ),
      ),
    );
  }

  Future<String?> getFCMToken() => _fcm.getToken();
}
