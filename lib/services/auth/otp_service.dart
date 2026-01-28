import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import '../../utils/constants.dart';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;

  final Map<String, DateTime> _lastOtpSent = {};
  final Map<String, int> _otpAttempts = {};

  OTPService._internal();

  // Send OTP via email using Supabase Auth
  Future<bool> sendEmailOTP(String email) async {
    try {
      // Check rate limiting
      if (_isRateLimited(email)) {
        throw Exception('Please wait before requesting another OTP');
      }

      final supabase = SupabaseService();
      
      // Use Supabase Auth to send OTP
      await supabase.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // We'll create user after verification
      );

      _lastOtpSent[email] = DateTime.now();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Send OTP via phone using Supabase Auth
  Future<bool> sendPhoneOTP(String phone) async {
    try {
      // Check rate limiting
      if (_isRateLimited(phone)) {
        throw Exception('Please wait before requesting another OTP');
      }

      final supabase = SupabaseService();
      
      // Use Supabase Auth to send OTP
      await supabase.client.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false, // We'll create user after verification
      );

      _lastOtpSent[phone] = DateTime.now();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP for signup session
  Future<bool> verifyOTP(String sessionToken, String otp) async {
    try {
      final supabase = SupabaseService();
      
      // Get signup session
      final session = await supabase.getSignupSession(sessionToken);
      if (session == null) {
        throw Exception('Invalid session');
      }

      final identifierValue = session['identifier_value'] as String;
      final identifierType = session['identifier_type'] as String;

      // Verify OTP with Supabase Auth
      AuthResponse response;
      if (identifierType == 'email') {
        response = await supabase.client.auth.verifyOTP(
          type: OtpType.email,
          email: identifierValue,
          token: otp,
        );
      } else if (identifierType == 'phone') {
        response = await supabase.client.auth.verifyOTP(
          type: OtpType.sms,
          phone: identifierValue,
          token: otp,
        );
      } else {
        throw Exception('Invalid identifier type');
      }

      if (response.session != null) {
        // Update signup session
        await supabase.updateSignupSession(sessionToken, {
          'verification_status': 'verified',
          'step': 3, // Move to account setup step
        });

        // Reset attempts
        _otpAttempts[identifierValue] = 0;
        return true;
      }

      // Increment attempts
      _otpAttempts[identifierValue] = (_otpAttempts[identifierValue] ?? 0) + 1;

      // Check if max attempts reached
      if ((_otpAttempts[identifierValue] ?? 0) >= AuthConstants.maxOtpAttempts) {
        await supabase.updateSignupSession(sessionToken, {
          'verification_status': 'expired',
        });
        throw Exception('Maximum OTP attempts reached. Please start again.');
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Resend OTP
  Future<bool> resendOTP(String sessionToken) async {
    try {
      final supabase = SupabaseService();
      final session = await supabase.getSignupSession(sessionToken);
      
      if (session == null) {
        throw Exception('Invalid session');
      }

      final identifierValue = session['identifier_value'] as String;
      final identifierType = session['identifier_type'] as String;

      // Check cooldown
      final lastSent = _lastOtpSent[identifierValue];
      if (lastSent != null) {
        final timeSinceLastSent = DateTime.now().difference(lastSent);
        if (timeSinceLastSent < AuthConstants.otpResendCooldown) {
          final remainingSeconds = 
              (AuthConstants.otpResendCooldown - timeSinceLastSent).inSeconds;
          throw Exception(
              'Please wait $remainingSeconds seconds before requesting another OTP');
        }
      }

      // Resend OTP
      if (identifierType == 'email') {
        return await sendEmailOTP(identifierValue);
      } else if (identifierType == 'phone') {
        return await sendPhoneOTP(identifierValue);
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Check rate limiting
  bool _isRateLimited(String identifier) {
    final lastSent = _lastOtpSent[identifier];
    if (lastSent == null) return false;

    final timeSinceLastSent = DateTime.now().difference(lastSent);
    return timeSinceLastSent < AuthConstants.otpResendCooldown;
  }

  // Clear OTP attempts (called after successful verification)
  void clearAttempts(String identifier) {
    _otpAttempts.remove(identifier);
    _lastOtpSent.remove(identifier);
  }
}
