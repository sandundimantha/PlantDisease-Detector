import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:plant_disease_detector/core/auth/user_role.dart';

class UserData {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String district;
  final String farmName;
  final String farmSize;
  final String bio;
  final List<String> primaryCrops;
  final String? imagePath;

  UserData({
    this.fullName = '',
    this.phoneNumber = '',
    this.email = '',
    this.district = '',
    this.farmName = '',
    this.farmSize = '',
    this.bio = '',
    this.primaryCrops = const [],
    this.imagePath,
  });

  UserData copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? district,
    String? farmName,
    String? farmSize,
    String? bio,
    List<String>? primaryCrops,
    String? imagePath,
  }) {
    return UserData(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      district: district ?? this.district,
      farmName: farmName ?? this.farmName,
      farmSize: farmSize ?? this.farmSize,
      bio: bio ?? this.bio,
      primaryCrops: primaryCrops ?? this.primaryCrops,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class UserNotifier extends StateNotifier<UserData> {
  StreamSubscription<AuthState>? _authSub;

  UserNotifier() : super(UserData()) {
    _loadUserData();
    // Reload on login / logout / sign-up so the previous account's name and
    // district are not shown to the next user on the same device.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.signedOut ||
          event.event == AuthChangeEvent.userUpdated) {
        _loadUserData();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      try {
        final data = await client.from('profiles').select().eq('id', user.id).maybeSingle();
        if (data != null) {
          state = UserData(
            fullName: data['full_name'] ?? '',
            phoneNumber: data['phone'] ?? '',
            email: data['email'] ?? '',
            district: data['district'] ?? '',
            farmName: data['farm_name'] ?? '',
            farmSize: data['farm_size'] ?? '',
            bio: data['bio'] ?? '',
            primaryCrops: (data['primary_crops'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            imagePath: data['avatar_url'],
          );
          return;
        }
      } catch (e) {
        debugPrint('Error loading profile from Supabase: $e');
      }
    }
    // Fallback if not logged in
    state = UserData();
  }

  Future<void> saveUserData(UserData user) async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    
    if (authUser != null) {
      try {
        await client.from('profiles').update({
          'full_name': user.fullName,
          'phone': user.phoneNumber,
          'email': user.email,
          'district': user.district,
          'farm_name': user.farmName,
          'farm_size': user.farmSize,
          'bio': user.bio,
          'primary_crops': user.primaryCrops,
          'avatar_url': user.imagePath,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', authUser.id);
      } catch (e) {
        debugPrint('Error saving profile to Supabase: $e');
      }
    } else {
      debugPrint('No logged in user, could not save to Supabase');
    }

    state = user; // Update the Riverpod state
  }

  // Permanently deletes the signed-in account (see delete_my_account() in
  // migration 019) and signs out. Throws if the database refuses, in which
  // case nothing has been deleted and the user stays signed in.
  Future<void> deleteMyAccount() async {
    final client = Supabase.instance.client;
    await client.rpc('delete_my_account');
    await clearCachedUserRole();
    try {
      await client.auth.signOut();
    } catch (e) {
      // The server-side session went with the user; the local one is cleared.
      debugPrint('Sign out after account deletion: $e');
    }
    state = UserData();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserData>((ref) {
  return UserNotifier();
});
