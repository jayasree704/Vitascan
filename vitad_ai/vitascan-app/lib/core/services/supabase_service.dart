import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/scan_result.dart';
import '../../domain/models/user_profile.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Authentication ──────────────────────────────────────
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (response.user != null) {
      await createOrUpdateProfile(
        UserProfile(
          id: response.user!.id,
          fullName: fullName,
          email: email,
          createdAt: DateTime.now(),
        ),
      );
    }
    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Opens Google sign-in in the device browser via Supabase OAuth.
  /// The deep link vitascan://login-callback will return the user to the app.
  Future<void> signInWithGoogleOAuth() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'vitascan://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Returns true if the current Google user's profile is missing
  /// required fields (age/gender/DOB) — i.e. they are a brand-new Google sign-in.
  Future<bool> isProfileIncomplete(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('gender, date_of_birth')
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return true;
      return data['gender'] == null || data['date_of_birth'] == null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── User Profiles ────────────────────────────────────────
  Future<void> createOrUpdateProfile(UserProfile profile) async {
    await _client.from('profiles').upsert({
      'id': profile.id,
      'full_name': profile.fullName,
      'avatar_url': profile.avatarUrl,
      if (profile.dateOfBirth != null)
        'date_of_birth': profile.dateOfBirth!.toIso8601String().split('T').first,
      if (profile.gender != null) 'gender': profile.gender,
    });
  }

  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data, currentUser?.email ?? '');
    } catch (e) {
      return null;
    }
  }

  // ── Scans & Storage ──────────────────────────────────────
  Future<String?> uploadScanImage(File imageFile, String userId) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await _client.storage.from('scan-images').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return _client.storage.from('scan-images').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  Future<ScanResult> saveScanResult(ScanResult result) async {
    final Map<String, dynamic> fullData = result.toJson();
    if (fullData['user_id'] == 'guest_user') {
      fullData.remove('user_id');
    }

    try {
      // 1. Try full insert with all patient & recommendation metadata
      final inserted = await _client.from('scans').insert(fullData).select().single();
      return ScanResult.fromJson(inserted);
    } catch (e1) {
      assert(() {
        // ignore: avoid_print
        print('Full payload insert failed ($e1), attempting core columns fallback...');
        return true;
      }());

      try {
        // 2. Fallback insert with core schema columns only
        final Map<String, dynamic> coreData = {
          if (fullData.containsKey('user_id')) 'user_id': fullData['user_id'],
          if (fullData.containsKey('image_url')) 'image_url': fullData['image_url'],
          'vitamin_d_level': fullData['vitamin_d_level'],
          'status': fullData['status'],
          'ai_confidence': fullData['ai_confidence'],
          if (fullData.containsKey('ai_raw_response')) 'ai_raw_response': fullData['ai_raw_response'],
        };
        await _client.from('scans').insert(coreData);
        return result;
      } catch (e2) {
        assert(() {
          // ignore: avoid_print
          print('Core payload insert failed: $e2');
          return true;
        }());
        rethrow;
      }
    }
  }

  Future<List<ScanResult>> fetchUserScans(String userId) async {
    try {
      final bool hasUser = userId.isNotEmpty && userId != 'guest_user';
      final query = _client.from('scans').select();
      final List<dynamic> data = hasUser
          ? await query.eq('user_id', userId).order('created_at', ascending: false)
          : await query.order('created_at', ascending: false).limit(50);
      return data.map((e) => ScanResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('Supabase fetchUserScans error: $e');
        return true;
      }());
      return [];
    }
  }
}
