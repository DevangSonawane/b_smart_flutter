import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../models/auth/jwt_token_model.dart';
import '../../utils/constants.dart';
import '../supabase_service.dart';
import 'device_service.dart';

class JWTService {
  static final JWTService _instance = JWTService._internal();
  factory JWTService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  JWTToken? _cachedToken;

  JWTService._internal();

  // Store tokens securely
  Future<void> storeTokens(JWTToken token) async {
    _cachedToken = token;
    await _storage.write(key: AuthConstants.accessTokenKey, value: token.accessToken);
    await _storage.write(key: AuthConstants.refreshTokenKey, value: token.refreshToken);
    await _storage.write(
        key: '${AuthConstants.accessTokenKey}_expires',
        value: token.accessTokenExpiresAt.toIso8601String());
    await _storage.write(
        key: '${AuthConstants.refreshTokenKey}_expires',
        value: token.refreshTokenExpiresAt.toIso8601String());
    if (token.deviceId != null) {
      await _storage.write(key: AuthConstants.deviceIdKey, value: token.deviceId);
    }
  }

  // Get stored tokens
  Future<JWTToken?> getStoredTokens() async {
    if (_cachedToken != null && !_cachedToken!.isRefreshTokenExpired) {
      return _cachedToken;
    }

    try {
      final accessToken = await _storage.read(key: AuthConstants.accessTokenKey);
      final refreshToken = await _storage.read(key: AuthConstants.refreshTokenKey);
      final accessExpiresStr = await _storage.read(key: '${AuthConstants.accessTokenKey}_expires');
      final refreshExpiresStr = await _storage.read(key: '${AuthConstants.refreshTokenKey}_expires');
      final deviceId = await _storage.read(key: AuthConstants.deviceIdKey);

      if (accessToken == null || refreshToken == null) {
        return null;
      }

      if (accessExpiresStr == null || refreshExpiresStr == null) {
        return null;
      }

      _cachedToken = JWTToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessTokenExpiresAt: DateTime.parse(accessExpiresStr),
        refreshTokenExpiresAt: DateTime.parse(refreshExpiresStr),
        deviceId: deviceId,
      );

      return _cachedToken;
    } catch (e) {
      return null;
    }
  }

  // Get access token (refresh if needed)
  Future<String?> getAccessToken() async {
    final token = await getStoredTokens();
    if (token == null) return null;

    // Check if access token is expired or will expire soon (within 1 minute)
    if (token.isAccessTokenExpired ||
        token.accessTokenExpiresAt.difference(DateTime.now()).inMinutes < 1) {
      // Try to refresh
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        return refreshed.accessToken;
      }
      return null;
    }

    return token.accessToken;
  }

  // Decode JWT payload
  JWTPayload? decodeToken(String token) {
    try {
      if (!JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);
        return JWTPayload(
          userId: decoded['user_id'] as String,
          username: decoded['username'] as String,
          authProvider: decoded['auth_provider'] as String,
          deviceId: decoded['device_id'] as String?,
          issuedAt: DateTime.fromMillisecondsSinceEpoch(
              (decoded['iat'] as int) * 1000),
          expiresAt: DateTime.fromMillisecondsSinceEpoch(
              (decoded['exp'] as int) * 1000),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Refresh access token
  Future<JWTToken?> refreshAccessToken() async {
    final currentToken = await getStoredTokens();
    if (currentToken == null || currentToken.isRefreshTokenExpired) {
      await clearTokens();
      return null;
    }

    try {
      final supabase = SupabaseService();
      final deviceService = DeviceService();
      final deviceInfo = await deviceService.getDeviceInfo();

      // Call backend to refresh token (this would be a custom endpoint)
      // For now, we'll use Supabase's built-in refresh
      final response = await supabase.client.auth.refreshSession();

      if (response.session != null) {
        // Create new token from Supabase session
        // Note: In a real implementation, you'd have a custom JWT endpoint
        // For now, we'll simulate token creation
        DateTime? expiresAt;
        if (response.session!.expiresAt != null) {
          if (response.session!.expiresAt is DateTime) {
            expiresAt = response.session!.expiresAt as DateTime;
          } else if (response.session!.expiresAt is int) {
            expiresAt = DateTime.fromMillisecondsSinceEpoch(
                (response.session!.expiresAt as int) * 1000);
          } else if (response.session!.expiresAt is String) {
            expiresAt = DateTime.parse(response.session!.expiresAt as String);
          }
        }
        
        final newToken = JWTToken(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken ?? currentToken.refreshToken,
          accessTokenExpiresAt: expiresAt ?? DateTime.now().add(AuthConstants.accessTokenExpiry),
          refreshTokenExpiresAt: DateTime.now().add(AuthConstants.refreshTokenExpiry),
          deviceId: deviceInfo.deviceId,
        );

        await storeTokens(newToken);
        return newToken;
      }

      return null;
    } catch (e) {
      await clearTokens();
      return null;
    }
  }

  // Clear all tokens
  Future<void> clearTokens() async {
    _cachedToken = null;
    await _storage.delete(key: AuthConstants.accessTokenKey);
    await _storage.delete(key: AuthConstants.refreshTokenKey);
    await _storage.delete(key: '${AuthConstants.accessTokenKey}_expires');
    await _storage.delete(key: '${AuthConstants.refreshTokenKey}_expires');
    await _storage.delete(key: AuthConstants.deviceIdKey);
    await _storage.delete(key: AuthConstants.userIdKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Get current user ID from token
  Future<String?> getCurrentUserId() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final payload = decodeToken(token);
    return payload?.userId;
  }
}

