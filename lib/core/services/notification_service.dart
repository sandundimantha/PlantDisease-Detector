import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:plant_disease_detector/core/providers/app_settings_provider.dart';
import 'dart:developer';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Reminders are scheduled in Sri Lanka time.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
    _listenToAnnouncements();
  }

  void _listenToAnnouncements() {
    try {
      final supabase = Supabase.instance.client;
      supabase
          .channel('public:announcements')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'announcements',
            callback: (payload) {
              final newAnnouncement = payload.newRecord;
              if (newAnnouncement['is_published'] == true) {
                showNotification(
                  id: newAnnouncement['id'].hashCode,
                  title: 'New Announcement: ${newAnnouncement['title']}',
                  body: newAnnouncement['content'] ?? 'Tap to read more.',
                );
              }
            },
          )
          .subscribe();
    } catch (e) {
      log('Error setting up Realtime for notifications: $e');
    }
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    // Profile / Settings → Notifications switched off.
    if (!AppSettings.current.notifications) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'lumina_announcements',
      'Announcements',
      channelDescription: 'Notifications for agricultural announcements',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'lumina_reminders',
      'Treatment reminders',
      channelDescription: 'Reminders to apply crop treatments',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Schedules the next [count] treatment reminders every [everyDays] days at
  /// [time], starting with the next time that time of day comes round.
  /// Returns the date and time of the first reminder.
  Future<DateTime> scheduleTreatmentReminders({
    required String title,
    required String body,
    required int everyDays,
    required TimeOfDay time,
    int count = 6,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
    final baseId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000000;
    for (var i = 0; i < count; i++) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: baseId + i,
        title: title,
        body: body,
        scheduledDate: first.add(Duration(days: everyDays * i)),
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    return first;
  }
}
