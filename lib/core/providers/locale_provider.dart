import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:plant_disease_detector/core/localization/app_strings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LocaleNotifier — manages the app's current locale and persists it.
// Reads/writes to SharedPreferences so the choice survives app restarts.
// When signed in, the choice is also kept in profiles.preferred_lang so it
// follows the account to any device (read on login, updated on change).
// ─────────────────────────────────────────────────────────────────────────────
class LocaleNotifier extends Notifier<Locale> {
  static const _prefKey = 'locale_language_code';
  static const _supported = ['en', 'si', 'ta'];

  String? _syncedUserId;
  bool _profileApplied = false;

  @override
  Locale build() {
    // Start with English; _loadSaved will update after SharedPreferences reads.
    _loadSaved();
    final sub = Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      final userId = authState.session?.user.id;
      if (userId == null) {
        _syncedUserId = null;
      } else if (userId != _syncedUserId) {
        _syncedUserId = userId;
        _loadFromProfile(userId);
      }
    });
    ref.onDispose(sub.cancel);
    return Locale(AppStrings.currentLocaleCode);
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    // The account's language (if already loaded) takes priority.
    if (_profileApplied) return;
    final code = prefs.getString(_prefKey) ?? 'en';
    AppStrings.currentLocaleCode = code;
    state = Locale(code);
  }

  // Read: apply the language saved on the signed-in user's profile.
  Future<void> _loadFromProfile(String userId) async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('preferred_lang')
          .eq('id', userId)
          .maybeSingle();
      final code = row?['preferred_lang'] as String?;
      if (code == null || !_supported.contains(code)) return;
      _profileApplied = true;
      await _applyLocally(code);
    } catch (e) {
      debugPrint('Could not load language from profile: $e');
    }
  }

  Future<void> _applyLocally(String code) async {
    AppStrings.currentLocaleCode = code;
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    await _applyLocally(code);

    // Update: keep the account's saved language in step with the app.
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'preferred_lang': code})
          .eq('id', user.id);
    } catch (e) {
      debugPrint('Could not save language to profile: $e');
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
