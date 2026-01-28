import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../models/auth/auth_user_model.dart';
import '../../models/auth/signup_session_model.dart';
import '../../models/auth/jwt_token_model.dart';
import '../../utils/constants.dart';
import '../supabase_service.dart';
import 'jwt_service.dart';
import 'otp_service.dart';
import 'device_service.dart';
import 'google_auth_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final SupabaseService _supabase = SupabaseService();
  final JWTService _jwtService = JWTService();
  final OTPService _otpService = OTPService();
  final DeviceService _deviceService = DeviceService();
  final GoogleAuthService _googleAuth = GoogleAuthService();

  AuthUser? _currentUser;
  final Map<String, DateTime> _loginAttempts = {};

  AuthService._internal();

  // ==================== SIGNUP METHODS ====================

  // Signup with email - Step 1
  Future<SignupSession> signupWithEmail(String email, String password) async {
    // Check if email already exists
    final existingUser = await _supabase.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception(AuthConstants.emailExists);
    }

    // Create signup session
    final sessionToken = _generateSessionToken();
    final expiresAt = DateTime.now().add(AuthConstants.signupSessionExpiry);

    final sessionData = {
      'session_token': sessionToken,
      'identifier_type': 'email',
      'identifier_value': email,
      'verification_status': 'pending',
      'step': 1,
      'metadata': jsonEncode({
        'email': email,
        'password_hash': _hashPassword(password),
      }),
      'expires_at': expiresAt.toIso8601String(),
    };

    await _supabase.client.from('signup_sessions').insert(sessionData);

    // Send OTP
    await _otpService.sendEmailOTP(email);

    return SignupSession.fromJson({
      'id': '', // Will be set by database
      ...sessionData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Signup with phone - Step 1
  Future<SignupSession> signupWithPhone(String phone) async {
    // Check if phone already exists
    final existingUser = await _supabase.getUserByPhone(phone);
    if (existingUser != null) {
      throw Exception(AuthConstants.phoneExists);
    }

    // Create signup session
    final sessionToken = _generateSessionToken();
    final expiresAt = DateTime.now().add(AuthConstants.signupSessionExpiry);

    final sessionData = {
      'session_token': sessionToken,
      'identifier_type': 'phone',
      'identifier_value': phone,
      'verification_status': 'pending',
      'step': 1,
      'metadata': jsonEncode({
        'phone': phone,
      }),
      'expires_at': expiresAt.toIso8601String(),
    };

    await _supabase.client.from('signup_sessions').insert(sessionData);

    // Send OTP
    await _otpService.sendPhoneOTP(phone);

    return SignupSession.fromJson({
      'id': '', // Will be set by database
      ...sessionData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Signup with Google - Step 1
  Future<SignupSession> signupWithGoogle() async {
    // Mock Google sign-in
    final googleResult = await _googleAuth.signIn();

    // Check if email already exists
    final existingUser = await _supabase.getUserByEmail(googleResult.email);
    if (existingUser != null) {
      // Link Google account to existing user
      throw Exception('Account with this email already exists. Please login.');
    }

    // Create signup session (auto-verified for Google)
    final sessionToken = _generateSessionToken();
    final expiresAt = DateTime.now().add(AuthConstants.signupSessionExpiry);

    final sessionData = {
      'session_token': sessionToken,
      'identifier_type': 'google',
      'identifier_value': googleResult.email,
      'verification_status': 'verified', // Google is pre-verified
      'step': 3, // Skip to account setup
      'metadata': jsonEncode({
        'email': googleResult.email,
        'name': googleResult.name,
        'photo_url': googleResult.photoUrl,
        'google_id_token': googleResult.idToken,
        'google_access_token': googleResult.accessToken,
      }),
      'expires_at': expiresAt.toIso8601String(),
    };

    await _supabase.client.from('signup_sessions').insert(sessionData);

    return SignupSession.fromJson({
      'id': '', // Will be set by database
      ...sessionData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Verify OTP - Step 2
  Future<SignupSession> verifyOTP(String sessionToken, String otp) async {
    final verified = await _otpService.verifyOTP(sessionToken, otp);
    if (!verified) {
      throw Exception(AuthConstants.invalidOTP);
    }

    // Get updated session
    final session = await _supabase.getSignupSession(sessionToken);
    if (session == null) {
      throw Exception(AuthConstants.sessionExpired);
    }

    return SignupSession.fromJson(session);
  }

  // Complete signup - Steps 3-5
  Future<AuthUser> completeSignup(
    String sessionToken,
    String username,
    String? fullName,
    String? password,
    DateTime dateOfBirth,
  ) async {
    // Get signup session
    final session = await _supabase.getSignupSession(sessionToken);
    if (session == null) {
      throw Exception(AuthConstants.sessionExpired);
    }

    final signupSession = SignupSession.fromJson(session);
    if (signupSession.isExpired || !signupSession.isVerified) {
      throw Exception(AuthConstants.sessionExpired);
    }

    // Check username availability
    final usernameAvailable = await _supabase.checkUsernameAvailability(username);
    if (!usernameAvailable) {
      throw Exception(AuthConstants.usernameTaken);
    }

    // Get metadata (already parsed as Map in SignupSession model)
    final metadata = signupSession.metadata;

    // Prepare signup data
    final signupData = {
      'username': username,
      'email': signupSession.identifierType == IdentifierType.email || signupSession.identifierType == IdentifierType.google
          ? signupSession.identifierValue
          : null,
      'phone': signupSession.identifierType == IdentifierType.phone
          ? signupSession.identifierValue
          : null,
      'full_name': fullName ?? metadata['name'] as String?,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0], // Date only
      'password_hash': password != null ? _hashPassword(password) : null,
      'provider_type': _identifierTypeToProviderType(signupSession.identifierType),
      'google_id': signupSession.identifierType == IdentifierType.google
          ? metadata['google_id_token'] as String?
          : null,
    };

    // Create user account
    final userId = await _supabase.createUserAccount(signupData);
    if (userId == null) {
      throw Exception('Failed to create account');
    }

    // Get created user
    final userData = await _supabase.getUserById(userId);
    if (userData == null) {
      throw Exception('Failed to retrieve user');
    }

    final user = AuthUser.fromJson(userData);
    _currentUser = user;

    // Auto-login
    await _performLogin(user, signupSession.identifierType);

    // Clean up signup session
    await _supabase.client
        .from('signup_sessions')
        .delete()
        .eq('session_token', sessionToken);

    return user;
  }

  // ==================== LOGIN METHODS ====================

  // Login with email
  Future<AuthUser> loginWithEmail(String email, String password) async {
    _checkRateLimit(email);

    final user = await _supabase.getUserByEmail(email);
    if (user == null) {
      _recordFailedAttempt(email);
      throw Exception(AuthConstants.invalidCredentials);
    }

    final authProvider = await _supabase.getAuthProvider(user['id'] as String, 'email');
    if (authProvider == null) {
      _recordFailedAttempt(email);
      throw Exception(AuthConstants.invalidCredentials);
    }

    final storedHash = authProvider['password_hash'] as String?;
    if (storedHash == null || storedHash != _hashPassword(password)) {
      _recordFailedAttempt(email);
      throw Exception(AuthConstants.invalidCredentials);
    }

    final authUser = AuthUser.fromJson(user);
    await _performLogin(authUser, IdentifierType.email);

    return authUser;
  }

  // Login with username
  Future<AuthUser> loginWithUsername(String username, String password) async {
    _checkRateLimit(username);

    final user = await _supabase.getUserByUsername(username);
    if (user == null) {
      _recordFailedAttempt(username);
      throw Exception(AuthConstants.invalidCredentials);
    }

    // Check email or username auth provider
    final emailProvider = await _supabase.getAuthProvider(user['id'] as String, 'email');
    final usernameProvider = await _supabase.getAuthProvider(user['id'] as String, 'username');

    final authProvider = emailProvider ?? usernameProvider;
    if (authProvider == null) {
      _recordFailedAttempt(username);
      throw Exception(AuthConstants.invalidCredentials);
    }

    final storedHash = authProvider['password_hash'] as String?;
    if (storedHash == null || storedHash != _hashPassword(password)) {
      _recordFailedAttempt(username);
      throw Exception(AuthConstants.invalidCredentials);
    }

    final authUser = AuthUser.fromJson(user);
    await _performLogin(authUser, IdentifierType.email);

    return authUser;
  }

  // Login with phone
  Future<SignupSession> loginWithPhone(String phone) async {
    _checkRateLimit(phone);

    final user = await _supabase.getUserByPhone(phone);
    if (user == null) {
      _recordFailedAttempt(phone);
      throw Exception(AuthConstants.userNotFound);
    }

    // Create temporary session for OTP verification
    final sessionToken = _generateSessionToken();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    final sessionData = {
      'session_token': sessionToken,
      'identifier_type': 'phone',
      'identifier_value': phone,
      'verification_status': 'pending',
      'step': 1,
      'metadata': jsonEncode({
        'user_id': user['id'] as String,
        'is_login': true,
      }),
      'expires_at': expiresAt.toIso8601String(),
    };

    await _supabase.client.from('signup_sessions').insert(sessionData);

    // Send OTP
    await _otpService.sendPhoneOTP(phone);

    return SignupSession.fromJson({
      'id': '',
      ...sessionData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Complete phone login after OTP verification
  Future<AuthUser> completePhoneLogin(String sessionToken, String otp) async {
    final verified = await _otpService.verifyOTP(sessionToken, otp);
    if (!verified) {
      throw Exception(AuthConstants.invalidOTP);
    }

    final session = await _supabase.getSignupSession(sessionToken);
    if (session == null) {
      throw Exception(AuthConstants.sessionExpired);
    }

    // Parse metadata (could be String or Map)
    final metadataRaw = session['metadata'];
    final metadata = metadataRaw is Map<String, dynamic>
        ? metadataRaw
        : jsonDecode(metadataRaw as String? ?? '{}') as Map<String, dynamic>;
    final userId = metadata['user_id'] as String;

    final userData = await _supabase.getUserById(userId);
    if (userData == null) {
      throw Exception(AuthConstants.userNotFound);
    }

    final authUser = AuthUser.fromJson(userData);
    await _performLogin(authUser, IdentifierType.phone);

    // Clean up session
    await _supabase.client
        .from('signup_sessions')
        .delete()
        .eq('session_token', sessionToken);

    return authUser;
  }

  // Login with Google
  Future<AuthUser> loginWithGoogle() async {
    final googleResult = await _googleAuth.signIn();

    final user = await _supabase.getUserByEmail(googleResult.email);
    if (user == null) {
      throw Exception(AuthConstants.userNotFound);
    }

    final authUser = AuthUser.fromJson(user);
    await _performLogin(authUser, IdentifierType.google);

    return authUser;
  }

  // ==================== SESSION MANAGEMENT ====================

  // Perform login (create tokens, device session)
  Future<void> _performLogin(AuthUser user, IdentifierType providerType) async {
    final deviceInfo = await _deviceService.getDeviceInfo();

    // Create JWT tokens (in real implementation, this would come from backend)
    // For now, we'll use Supabase's session
    final accessToken = _generateToken(user.id, user.username, providerType);
    final refreshToken = _generateToken(user.id, user.username, providerType, isRefresh: true);

    final jwtToken = JWTToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: DateTime.now().add(AuthConstants.accessTokenExpiry),
      refreshTokenExpiresAt: DateTime.now().add(AuthConstants.refreshTokenExpiry),
      deviceId: deviceInfo.deviceId,
    );

    await _jwtService.storeTokens(jwtToken);

    // Store refresh token in database
    await _supabase.insertRefreshToken({
      'user_id': user.id,
      'token': refreshToken,
      'device_id': deviceInfo.deviceId,
      'device_fingerprint': deviceInfo.deviceFingerprint,
      'ip_address': deviceInfo.ipAddress,
      'user_agent': deviceInfo.userAgent,
      'expires_at': jwtToken.refreshTokenExpiresAt.toIso8601String(),
    });

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
      final deviceId = await _deviceService.getDeviceInfo().then((info) => info.deviceId);
      await _supabase.revokeAllUserTokens(userId, keepDeviceId: deviceId);
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

    final userData = await _supabase.getUserById(userId);
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

  // ==================== HELPER METHODS ====================

  String _generateSessionToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateToken(String userId, String username, IdentifierType providerType, {bool isRefresh = false}) {
    // In real implementation, this would be generated by backend
    // For now, create a simple token
    final payload = {
      'user_id': userId,
      'username': username,
      'auth_provider': _identifierTypeToProviderType(providerType),
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
    // Note: In production, use Argon2 via Supabase Auth
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
