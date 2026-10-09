import 'package:flutter/material.dart' show TimeOfDay, ValueNotifier;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:plant_disease_detector/core/providers/app_settings_provider.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'dart:developer';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Consultation whose chat is on screen; its messages need no notification.
  static String? openChatId;

  /// Ticks when a case this user can see is created or changes, so case
  /// lists and stats reload without a manual refresh.
  static final ValueNotifier<int> caseChanges = ValueNotifier(0);

  RealtimeChannel? _userChannel;
  String? _userId;
  final Map<String, String> _knownStatus = {};

  Future<void> init() async {
    if (_isInitialized) return;

    // Reminders are scheduled in Sri Lanka time.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_lumina');
    
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

    _isInitialized = true;
    _listenToAnnouncements();
    // Lives as long as the app; switches alerts when another user signs in.
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => _listenForUser());
    _listenForUser();
  }

  /// Asks for the Android 13+ notification permission. Called once the user
  /// reaches the app (not on the blank launch screen), so they see why.
  Future<void> requestPermission() async {
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      log('Notification permission request failed: $e');
    }
  }

  static String _t(String en, String si, String ta) => switch (AppStrings.currentLocaleCode) {
        'si' => si,
        'ta' => ta,
        _ => en,
      };

  /// Case and chat alerts for the signed-in user. Realtime only delivers rows
  /// this user may read (RLS), so officers hear about cases they can see and
  /// farmers only about their own. Alerts arrive while the app is open;
  /// Android pauses apps in the background, so those need server push (FCM,
  /// not set up yet).
  Future<void> _listenForUser() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == _userId) return;
    final switched = _userId != null;
    _userId = uid;
    await _userChannel?.unsubscribe();
    _userChannel = null;
    _knownStatus.clear();
    // Case and chat alerts belong to the previous account; clear them from the
    // tray on sign-out (scheduled treatment reminders are left alone).
    if (switched) await _clearShownAlerts();
    if (uid == null) return;

    String role = 'farmer';
    try {
      final profile = await client.from('profiles').select('role').eq('id', uid).maybeSingle();
      role = (profile?['role'] as String?)?.toLowerCase() ?? 'farmer';
      final mine = await client.from('consultations').select('id, status').or('farmer_id.eq.$uid,officer_id.eq.$uid');
      for (final c in mine as List) {
        _knownStatus[c['id'].toString()] = c['status']?.toString() ?? '';
      }
    } catch (e) {
      log('Could not prepare case alerts: $e');
    }
    if (_userId != uid) return; // signed out or switched while loading
    final isOfficer = role == 'officer' || role == 'admin';

    try {
      _userChannel = client
          .channel('alerts_$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'consultations',
            callback: (payload) {
              caseChanges.value++;
              final c = payload.newRecord;
              final id = c['id'].toString();
              _knownStatus[id] = c['status']?.toString() ?? '';
              if (!isOfficer || c['farmer_id'] == uid) return;
              if (c['officer_id'] != null && c['officer_id'] != uid) return;
              final disease = AppStrings.translateDisease(c['disease_name']?.toString() ?? '', AppStrings.currentLocaleCode);
              showNotification(
                id: id.hashCode,
                title: _t('New case from a farmer', 'ගොවියෙකුගෙන් නව සිද්ධියක්', 'விவசாயியிடமிருந்து புதிய வழக்கு'),
                body: c['severity'] == 'high'
                    ? '$disease · ${_t('High severity', 'ඉහළ බරපතලකම', 'அதிக தீவிரம்')}'
                    : disease,
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'consultations',
            callback: (payload) {
              caseChanges.value++;
              final c = payload.newRecord;
              final id = c['id'].toString();
              final status = c['status']?.toString() ?? '';
              final before = _knownStatus[id];
              _knownStatus[id] = status;
              if (c['farmer_id'] != uid || before == null || before == status) return;
              final (title, body) = switch (status) {
                'open' => (
                    _t('An officer took your case', 'නිලධාරියෙක් ඔබේ සිද්ධිය භාර ගත්තා', 'ஒரு அலுவலர் உங்கள் வழக்கை ஏற்றுக்கொண்டார்'),
                    _t('You can now chat with them in Expert Consult.', 'දැන් ඔබට විශේෂඥ උපදෙස් තුළ ඔවුන් සමඟ කතාබස් කළ හැක.', 'இப்போது நிபுணர் ஆலோசனையில் அவருடன் உரையாடலாம்.'),
                  ),
                'resolved' => (
                    _t('Your case is resolved', 'ඔබේ සිද්ධිය විසඳා ඇත', 'உங்கள் வழக்கு தீர்க்கப்பட்டது'),
                    _t('Open Expert Consult to read the officer\'s advice.', 'නිලධාරියාගේ උපදෙස් කියවීමට විශේෂඥ උපදෙස් විවෘත කරන්න.', 'அலுவலரின் ஆலோசனையைப் படிக்க நிபுணர் ஆலோசனையைத் திறக்கவும்.'),
                  ),
                _ => ('', ''),
              };
              if (title.isNotEmpty) showNotification(id: id.hashCode ^ status.hashCode, title: title, body: body);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'consultation_messages',
            callback: (payload) {
              final m = payload.newRecord;
              final caseId = m['consultation_id']?.toString();
              if (m['sender_id'] == uid || caseId == null || caseId == openChatId) return;
              if (!_knownStatus.containsKey(caseId)) return; // not one of this user's cases
              final fromOfficer = m['sender_role'] != 'farmer';
              final text = m['content']?.toString() ?? '';
              showNotification(
                id: m['id'].hashCode,
                title: fromOfficer
                    ? _t('New message from the officer', 'නිලධාරියාගෙන් නව පණිවිඩයක්', 'அலுவலரிடமிருந்து புதிய செய்தி')
                    : _t('New message from a farmer', 'ගොවියාගෙන් නව පණිවිඩයක්', 'விவசாயியிடமிருந்து புதிய செய்தி'),
                body: text.length > 120 ? '${text.substring(0, 120)}…' : text,
              );
            },
          )
          .subscribe();
    } catch (e) {
      log('Error setting up case alerts: $e');
    }
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
                  title: '${_t('New announcement', 'නව නිවේදනය', 'புதிய அறிவிப்பு')}: ${newAnnouncement['title']}',
                  body: newAnnouncement['content'] ?? _t('Tap to read more.', 'වැඩිදුර කියවීමට තට්ටු කරන්න.', 'மேலும் படிக்கத் தட்டவும்.'),
                );
              }
            },
          )
          .subscribe();
    } catch (e) {
      log('Error setting up Realtime for notifications: $e');
    }
  }

  Future<void> _clearShownAlerts() async {
    try {
      final shown = await flutterLocalNotificationsPlugin.getActiveNotifications();
      for (final n in shown) {
        if (n.channelId == 'lumina_announcements' && n.id != null) {
          await flutterLocalNotificationsPlugin.cancel(id: n.id!);
        }
      }
    } catch (e) {
      log('Could not clear alerts: $e');
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
