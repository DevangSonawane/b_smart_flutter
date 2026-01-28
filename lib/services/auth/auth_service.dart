import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../models/auth/auth_user_model.dart';
import '../../models/auth/signup_session_model.dart';
import '../../models/auth/jwt_token_model.dart';
import '../../utils/constants.dart';
import 'jwt_service.dart';
import 'otp_service.dart';
import 'device_service.dart';
import 'google_auth_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final JWTService _jwtService = JWTService();
  final OTPService _otpService = OTPService();
  final DeviceService _deviceService = DeviceService();
  final GoogleAuthService _googleAuth = GoogleAuthService();

  AuthUser? _currentUser;
  final Map<String, DateTime> _loginAttempts = {};

  // Mock data storage
  final Map<String, Map<String, dynamic>> _mockUsers = {};
  final Map<String, Map<String, dynamic>> _mockSignupSessions = {};
  final Map<String, String> _mockPasswords = {}; // email/phone -> password hash
  final Map<String, String> _mockUsernames = {}; // username -> userId

  AuthService._internal();

  // Helper method to create and login with a default mock user
  Future<AuthUser> _createAndLoginMockUser({
    String? email,
    String? phone,
    String? username,
  }) async {
    final userId = _generateSessionToken();
    final now = DateTime.now();
    final defaultUsername = username ?? 'user_${userId.substring(0, 8)}';
    
    final userData = {
      'id': userId,
      'username': defaultUsername,
      'email': email,
      'phone': phone,
      'full_name': 'Test User',
      'date_of_birth': '2000-01-01',
      'is_under_18': false,
      'avatar_url': null,
      'bio': null,
      'is_active': true,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    _mockUsers[userId] = userData;
    if (defaultUsername.isNotEmpty) {
      _mockUsernames[defaultUsername.toLowerCase()] = userId;
    }

    final user = AuthUser.fromJson(userData);
    await _performLogin(user, email != null ? IdentifierType.email : (phone != null ? IdentifierType.phone : IdentifierType.google));
    
    return user;
  }

  // ==================== SIGNUP METHODS ====================

  // Signup with email - Step 1 (Skip all steps, login immediately)
  Future<SignupSession> signupWithEmail(String email, String password) async {
    // Skip all steps - just create user and login
    await _createAndLoginMockUser(email: email);
    
    // Return a dummy session for compatibility
    final sessionToken = _generateSessionToken();
    final sessionData = {
      'id': sessionToken,
      'session_token': sessionToken,
      'identifier_type': 'email',
      'identifier_value': email,
      'verification_status': 'verified',
      'step': 5,
      'metadata': jsonEncode({'email': email}),
      'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    return SignupSession.fromJson(sessionData);
  }

  // Signup with phone - Step 1 (Skip all steps, login immediately)
  Future<SignupSession> signupWithPhone(String phone) async {
    // Skip all steps - just create user and login
    await _createAndLoginMockUser(phone: phone);
    
    // Return a dummy session for compatibility
    final sessionToken = _generateSessionToken();
    final sessionData = {
      'id': sessionToken,
      'session_token': sessionToken,
      'identifier_type': 'phone',
      'identifier_value': phone,
      'verification_status': 'verified',
      'step': 5,
      'metadata': jsonEncode({'phone': phone}),
      'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    return SignupSession.fromJson(sessionData);
  }

  // Signup with Google - Step 1 (Skip all steps, login immediately)
  Future<SignupSession> signupWithGoogle() async {
    try {
      await _googleAuth.signIn();
    } catch (e) {
      // If Google sign-in fails, continue anyway
    }
    
    // Skip all steps - just create user and login
    await _createAndLoginMockUser(email: 'user@example.com');
    
    // Return a dummy session for compatibility
    final sessionToken = _generateSessionToken();
    final sessionData = {
      'id': sessionToken,
      'session_token': sessionToken,
      'identifier_type': 'google',
      'identifier_value': 'user@example.com',
      'verification_status': 'verified',
      'step': 5,
      'metadata': jsonEncode({'email': 'user@example.com'}),
      'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    return SignupSession.fromJson(sessionData);
  }

  // Verify OTP - Step 2 (Skip OTP check)
  Future<SignupSession> verifyOTP(String sessionToken, String otp) async {
    // Skip OTP verification - just return verified session
    final session = _mockSignupSessions[sessionToken];
    if (session != null) {
      session['verification_status'] = 'verified';
      session['step'] = 3;
      return SignupSession.fromJson(session);
    }
    
    // If no session, create a dummy one
    final sessionData = {
      'id': sessionToken,
      'session_token': sessionToken,
      'identifier_type': 'email',
      'identifier_value': 'user@example.com',
      'verification_status': 'verified',
      'step': 3,
      'metadata': jsonEncode({'email': 'user@example.com'}),
      'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    return SignupSession.fromJson(sessionData);
  }

  // Complete signup - Steps 3-5 (Skip all checks, login immediately)
  Future<AuthUser> completeSignup(
    String sessionToken,
    String username,
    String? fullName,
    String? password,
    DateTime dateOfBirth,
  ) async {
    // Skip all checks - just create user and login
    return await _createAndLoginMockUser(username: username);
  }

  // ==================== LOGIN METHODS ====================

  // Login with email (Skip all checks, login immediately)
  Future<AuthUser> loginWithEmail(String email, String password) async {
    // Skip all checks - just create user and login
    return await _createAndLoginMockUser(email: email);
  }

  // Login with username (Skip all checks, login immediately)
  Future<AuthUser> loginWithUsername(String username, String password) async {
    // Skip all checks - just create user and login
    return await _createAndLoginMockUser(username: username);
  }

  // Login with phone (Skip all checks, login immediately)
  Future<SignupSession> loginWithPhone(String phone) async {
    // Skip all checks - just create user and login
    await _createAndLoginMockUser(phone: phone);
    
    // Return a dummy session for compatibility
    final sessionToken = _generateSessionToken();
    final sessionData = {
      'id': sessionToken,
      'session_token': sessionToken,
      'identifier_type': 'phone',
      'identifier_value': phone,
      'verification_status': 'verified',
      'step': 5,
      'metadata': jsonEncode({'phone': phone, 'is_login': true}),
      'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    return SignupSession.fromJson(sessionData);
  }

  // Complete phone login after OTP verification (Skip OTP check)
  Future<AuthUser> completePhoneLogin(String sessionToken, String otp) async {
    // Skip OTP verification - just create user and login
    return await _createAndLoginMockUser(phone: '1234567890');
  }

  // Login with Google (Skip all checks, login immediately)
  Future<AuthUser> loginWithGoogle() async {
    try {
      await _googleAuth.signIn();
    } catch (e) {
      // If Google sign-in fails, continue anyway
    }
    
    // Skip all checks - just create user and login
    return await _createAndLoginMockUser(email: 'user@example.com');
  }

  // ==================== SESSION MANAGEMENT ====================

  // Perform login (create tokens, device session)
  Future<void> _performLogin(AuthUser user, IdentifierType providerType) async {
    final deviceInfo = await _deviceService.getDeviceInfo();

    // Create JWT tokens (in real implementation, this would come from backend)
    // For now, we'll use a locally generated token that includes device_id
    final accessToken = _generateToken(
      user.id,
      user.username,
      providerType,
      deviceId: deviceInfo.deviceId,
    );
    final refreshToken = _generateToken(
      user.id,
      user.username,
      providerType,
      isRefresh: true,
      deviceId: deviceInfo.deviceId,
    );

    final jwtToken = JWTToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: DateTime.now().add(AuthConstants.accessTokenExpiry),
      refreshTokenExpiresAt: DateTime.now().add(AuthConstants.refreshTokenExpiry),
      deviceId: deviceInfo.deviceId,
    );

    await _jwtService.storeTokens(jwtToken);

    // TODO: Implement backend integration to store refresh token
    // await backend.insertRefreshToken({
    //   'user_id': user.id,
    //   'token': refreshToken,
    //   'device_id': deviceInfo.deviceId,
    //   'device_fingerprint': deviceInfo.deviceFingerprint,
    //   'ip_address': deviceInfo.ipAddress,
    //   'user_agent': deviceInfo.userAgent,
    //   'expires_at': jwtToken.refreshTokenExpiresAt.toIso8601String(),
    // });

    // Create/update device session
    await _deviceService.getOrCreateDeviceSession(user.id);

    _currentUser = user;
  }

  // Refresh access token
  Future<JWTToken> refreshAccessToken() async {
    final result = await _jwtService.refreshAccessToken();
    if (result == null) {
      throw Exception(AuthConstants.tokenExpired);
    }
    return result;
  }

  // Logout
  Future<void> logout() async {
    final userId = await _jwtService.getCurrentUserId();
    if (userId != null) {
      // TODO: Implement backend integration to revoke user tokens
      // await backend.revokeAllUserTokens(userId, keepDeviceId: deviceId);
    }
    await _jwtService.clearTokens();
    _currentUser = null;
  }

  // Get current user
  Future<AuthUser?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    final userId = await _jwtService.getCurrentUserId();
    if (userId == null) {
      return null;
    }
    // Get user from mock storage
    final userData = _mockUsers[userId];
    if (userData == null) {
      return null;
    }
    _currentUser = AuthUser.fromJson(userData);
    return _currentUser;
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    return await _jwtService.isAuthenticated();
  }

  // Check username availability (for mock)
  Future<bool> checkUsernameAvailability(String username) async {
    return !_mockUsernames.containsKey(username.toLowerCase());
  }

  // Update signup session (for mock)
  Future<void> updateSignupSession(String sessionToken, Map<String, dynamic> updates) async {
    final session = _mockSignupSessions[sessionToken];
    if (session != null) {
      session.addAll(updates);
      // If metadata is being updated, merge it properly
      if (updates.containsKey('metadata') && updates['metadata'] is Map) {
        final existingMetadata = session['metadata'];
        final existingMap = existingMetadata is Map<String, dynamic>
            ? existingMetadata
            : (existingMetadata is String
                ? jsonDecode(existingMetadata) as Map<String, dynamic>
                : {});
        final newMetadata = Map<String, dynamic>.from(existingMap);
        newMetadata.addAll(updates['metadata'] as Map<String, dynamic>);
        session['metadata'] = jsonEncode(newMetadata);
      }
    }
  }

  // ==================== HELPER METHODS ====================

  String _generateSessionToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateToken(
    String userId,
    String username,
    IdentifierType providerType, {
    bool isRefresh = false,
    String? deviceId,
  }) {
    // In real implementation, this would be generated by backend
    // For now, create a simple token
    final payload = {
      'user_id': userId,
      'username': username,
      'auth_provider': _identifierTypeToProviderType(providerType),
      if (deviceId != null) 'device_id': deviceId,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().add(isRefresh ? AuthConstants.refreshTokenExpiry : AuthConstants.accessTokenExpiry))
          .millisecondsSinceEpoch ~/ 1000,
    };

    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
    // Note: In production, use Argon2
  }

  String _identifierTypeToProviderType(IdentifierType type) {
    switch (type) {
      case IdentifierType.email:
        return 'email';
      case IdentifierType.phone:
        return 'phone';
      case IdentifierType.google:
        return 'google';
    }
  }

  void _checkRateLimit(String identifier) {
    final attempts = _loginAttempts[identifier];
    if (attempts != null) {
      final timeSinceLastAttempt = DateTime.now().difference(attempts);
      if (timeSinceLastAttempt < AuthConstants.loginAttemptWindow) {
        throw Exception('Too many login attempts. Please try again later.');
      }
    }
  }

  void _recordFailedAttempt(String identifier) {
    _loginAttempts[identifier] = DateTime.now();
  }
}
