import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User role — the source of truth is profiles.role in Supabase (the same value
// RLS checks). The login tab the user picked is only a UI hint and must not
// decide routing, otherwise a farmer can land on the officer dashboard.
// ─────────────────────────────────────────────────────────────────────────────

// Cached per user, so a fallback never applies one account's role to another.
String _prefsKey(String userId) => 'user_role_$userId';

/// Reads the signed-in user's role from Supabase ('officer', 'admin' or
/// 'farmer') and caches it. Returns null when it cannot be read, e.g. on a
/// connection that hangs (rural networks often hang rather than fail).
Future<String?> fetchUserRole() async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  try {
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 6));
    final role = (row?['role'] as String?)?.toLowerCase() ?? 'farmer';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(userId), role);
    return role;
  } catch (e) {
    debugPrint('fetchUserRole failed: $e');
    return null;
  }
}

/// Role for routing an existing session (splash). Uses this user's cached
/// role straight away and refreshes it in the background, so a slow network
/// does not hold the splash screen; only a first launch waits for the lookup.
Future<String> resolveUserRole() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'farmer';
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(_prefsKey(userId));
  if (cached != null) {
    unawaited(fetchUserRole());
    return cached;
  }
  return await fetchUserRole() ?? 'farmer';
}

Future<void> clearCachedUserRole() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_role'); // key used by older builds
  if (userId != null) await prefs.remove(_prefsKey(userId));
}

String homeRouteForRole(String role) => role == 'officer' ? '/officer_dashboard' : '/main';
