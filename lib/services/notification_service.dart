import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  static Future<void> show(String title, String body) async {
    const android = AndroidNotificationDetails(
      'conectapro_channel',       // ✅ padronizado com o backend
      'ConectaPro Notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('default'),
    );
    const details = NotificationDetails(android: android);
    await _notifications.show(0, title, body, details);
  }
}
