import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../main.dart';
import '../models/staff_user.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    // Support both older string versions and newer TimezoneInfo versions
    final String timeZoneName = tzInfo is String ? tzInfo as String : (tzInfo as dynamic).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Navigate to notification inbox when the notification is tapped
        navigatorKey.currentState?.pushNamed('/notifications');
      },
    );
    _initialized = true;
  }

  Future<void> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> updateNotificationsForUser(StaffUser? user) async {
    if (!_initialized) await init();

    if (user == null || user.role == 'owner') {
      // Cancel all notifications if logged out or if user is owner
      await _flutterLocalNotificationsPlugin.cancelAll();
      return;
    }

    // Just request permission so we are ready to send on-demand notifications
    await requestPermission();
  }

  Future<void> showShopClosedNotification(double todayIncome) async {
    if (!_initialized) await init();
    if (await Permission.notification.isGranted) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'burnin_alerts',
        'BurnIn Alerts',
        channelDescription: 'Alerts and summaries for BurnIn shop',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        0,
        'Shop Closed',
        'Today\'s total income: ₹${todayIncome.toStringAsFixed(2)}',
        platformDetails,
      );
    }
  }
}
