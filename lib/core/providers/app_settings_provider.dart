import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppSettings — on/off choices from Profile and Settings, kept on the phone.
//   notifications: show phone alerts for admin announcements and reminders
//   location:      use GPS for the home location, weather and nearest officer
// ─────────────────────────────────────────────────────────────────────────────
class AppSettings {
  final bool notifications;
  final bool location;

  const AppSettings({this.notifications = true, this.location = true});

  AppSettings copyWith({bool? notifications, bool? location}) => AppSettings(
        notifications: notifications ?? this.notifications,
        location: location ?? this.location,
      );

  /// Last loaded value, for code outside the widget tree (notification service).
  static AppSettings current = const AppSettings();
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _notificationsKey = 'settings_notifications';
  static const _locationKey = 'settings_location';

  @override
  AppSettings build() {
    _load();
    return AppSettings.current;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = AppSettings(
      notifications: prefs.getBool(_notificationsKey) ?? true,
      location: prefs.getBool(_locationKey) ?? true,
    );
    AppSettings.current = loaded;
    state = loaded;
  }

  Future<void> setNotifications(bool on) async {
    state = state.copyWith(notifications: on);
    AppSettings.current = state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, on);
  }

  Future<void> setLocation(bool on) async {
    state = state.copyWith(location: on);
    AppSettings.current = state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationKey, on);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
