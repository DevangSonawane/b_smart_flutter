import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;

  SupabaseClient? _client;
  bool _isInitialized = false;

  SupabaseService._internal();

  // Initialize Supabase (call this in main.dart)
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  SupabaseClient get client {
    if (_client == null || !_isInitialized) {
      throw Exception(
          'Supabase not initialized. Call SupabaseService().initialize() first.');
    }
    return _client!;
  }

  bool get isInitialized => _isInitialized;

  // Get current user from Supabase Auth
  User? get currentUser => client.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Database helpers
  Future<Map<String, dynamic>?> getSignupSession(String sessionToken) async {
    try {
      final response = await client
          .from('signup_sessions')
          .select()
          .eq('session_token', sessionToken)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateSignupSession(
    String sessionToken,
    Map<String, dynamic> updates,
  ) async {
    // If metadata is being updated, ensure it's properly formatted for JSONB
    if (updates.containsKey('metadata') && updates['metadata'] is Map) {
      updates['metadata'] = jsonEncode(updates['metadata']);
    }
    await client
        .from('signup_sessions')
        .update(updates)
        .eq('session_token', sessionToken);
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await client
          .rpc('check_username_availability', params: {
        'username_to_check': username,
      });

      return response as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createUserAccount(Map<String, dynamic> signupData) async {
    try {
      final response = await client.rpc('create_user_account', params: {
        'p_username': signupData['username'],
        'p_email': signupData['email'],
        'p_phone': signupData['phone'],
        'p_full_name': signupData['full_name'],
        'p_date_of_birth': signupData['date_of_birth'],
        'p_password_hash': signupData['password_hash'],
        'p_provider_type': signupData['provider_type'],
        'p_google_id': signupData['google_id'],
      });

      return response as String?;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('email', email)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('phone', phone)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('username', username)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAuthProvider(
    String userId,
    String providerType,
  ) async {
    try {
      final response = await client
          .from('auth_providers')
          .select()
          .eq('user_id', userId)
          .eq('provider_type', providerType)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<void> insertRefreshToken(Map<String, dynamic> tokenData) async {
    await client.from('refresh_tokens').insert(tokenData);
  }

  Future<Map<String, dynamic>?> getRefreshToken(String token) async {
    try {
      final response = await client
          .from('refresh_tokens')
          .select()
          .eq('token', token)
          .eq('is_revoked', false)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<void> revokeRefreshToken(String token) async {
    await client
        .from('refresh_tokens')
        .update({'is_revoked': true})
        .eq('token', token);
  }

  Future<void> revokeAllUserTokens(String userId, {String? keepDeviceId}) async {
    if (keepDeviceId != null) {
      await client
          .from('refresh_tokens')
          .update({'is_revoked': true})
          .eq('user_id', userId)
          .neq('device_id', keepDeviceId);
    } else {
      await client
          .from('refresh_tokens')
          .update({'is_revoked': true})
          .eq('user_id', userId);
    }
  }

  Future<void> upsertDeviceSession(Map<String, dynamic> deviceData) async {
    await client.from('device_sessions').upsert(
      deviceData,
      onConflict: 'device_id',
    );
  }

  Future<Map<String, dynamic>?> getDeviceSession(String deviceId) async {
    try {
      final response = await client
          .from('device_sessions')
          .select()
          .eq('device_id', deviceId)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
