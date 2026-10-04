import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User role — the source of truth is profiles.role in Supabase (the same value
// RLS checks). The login tab the user picked is only a UI hint and must not
// decide routing, otherwise a farmer can land on the officer dashboard.
// ─────────────────────────────────────────────────────────────────────────────
const _prefsKey = 'user_role';

/// Returns 'officer', 'admin' or 'farmer' for the signed-in user.
/// Falls back to the last cached role when offline.
Future<String> resolveUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 'farmer';

  try {
    // Rural connections often hang rather than fail; fall back to the cached
    // role instead of holding the user on the splash screen.
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 6));
    final role = (row?['role'] as String?)?.toLowerCase() ?? 'farmer';
    await prefs.setString(_prefsKey, role);
    return role;
  } catch (e) {
    debugPrint('resolveUserRole: using cached role ($e)');
    return prefs.getString(_prefsKey)?.toLowerCase() ?? 'farmer';
  }
}

Future<void> clearCachedUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefsKey);
}

String homeRouteForRole(String role) => role == 'officer' ? '/officer_dashboard' : '/main';
