import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialised = false;

  static Future<void> init() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialised = true;
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static List<int> _idsFor(String eventId) {
    final base = eventId.hashCode.abs() % 100000;
    return [base, base + 1, base + 2];
  }

  static Future<void> scheduleEventReminders({
    required String eventId,
    required String eventTitle,
    required String dateStr,
  }) async {
    await init();
    final DateTime? eventDate = DateTime.tryParse(dateStr);
    if (eventDate == null) return;

    const androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Reminders for your saved events',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final reminders = [(7, '7 days'), (3, '3 days'), (1, 'tomorrow')];
    final ids = _idsFor(eventId);

    for (var i = 0; i < reminders.length; i++) {
      final (days, label) = reminders[i];
      final trigger = eventDate.subtract(Duration(days: days));
      final schedTz = tz.TZDateTime(
        tz.local,
        trigger.year,
        trigger.month,
        trigger.day,
        10,
        0,
      );
      if (schedTz.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          id: ids[i],
          title: '🎉 $eventTitle is coming up!',
          body: 'Only $label to go — don\'t miss it!',
          scheduledDate: schedTz,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  static Future<void> cancelEventReminders(String eventId) async {
    await init();
    for (final id in _idsFor(eventId)) {
      await _plugin.cancel(id: id);
    }
  }
}
