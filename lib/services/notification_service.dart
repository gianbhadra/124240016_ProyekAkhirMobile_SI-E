import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _expenseReminderId = 1;

  static Future<void> _initialize() async {
    if (!_initialized) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    }
  }

  static Future<bool> isHourlyExpenseReminderScheduled() async {
    await _initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((notification) => notification.id == _expenseReminderId);
  }

  static Future<bool> scheduleHourlyExpenseReminder() async {
    await _initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final permissionGranted = await android?.requestNotificationsPermission();
      if (permissionGranted == false ||
          await android?.areNotificationsEnabled() == false) {
        return false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final permissionGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permissionGranted == false) return false;
    }

    if (await isHourlyExpenseReminderScheduled()) return true;

    await _plugin.periodicallyShow(
      id: _expenseReminderId,
      title: 'Pengingat CoinWise',
      body:
          'Jangan lupa catat pengeluaranmu hari ini agar keuangan tetap terpantau.',
      repeatInterval: RepeatInterval.hourly,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'coinwise_reminders',
          'Pengingat CoinWise',
          channelDescription: 'Pengingat pencatatan keuangan di CoinWise.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return true;
  }
}
