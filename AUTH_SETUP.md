# Authentication System Setup Guide

This guide will help you set up the Instagram-like authentication system for the b Smart app.

## Prerequisites

1. A Supabase account (sign up at https://supabase.com)
2. Flutter SDK installed
3. Your Supabase project URL and anon key

## Step 1: Set Up Supabase Project

1. Create a new project in Supabase
2. Go to Settings > API to get your:
   - Project URL
   - Anon (public) key

## Step 2: Run Database Schema

1. Open the Supabase SQL Editor
2. Copy and paste the contents of `supabase/schema.sql`
3. Run the SQL script to create all tables, functions, and policies

## Step 3: Configure Supabase Auth

1. Go to Authentication > Providers in Supabase dashboard
2. Enable Email provider
3. Enable Phone provider (requires Twilio setup for production)
4. Configure Google OAuth (optional, for production):
   - Go to Authentication > Providers > Google
   - Add your Google OAuth credentials

## Step 4: Configure Flutter App

### Option A: Using Environment Variables (Recommended)

1. Create a `.env` file in the project root:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

2. Update `lib/main.dart` to read from environment variables or use a config file.

### Option B: Direct Configuration

Update `lib/main.dart` and replace the placeholder values:
```dart
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseAnonKey = 'your-anon-key-here';
```

## Step 5: Install Dependencies

Run:
```bash
flutter pub get
```

## Step 6: Test the Authentication Flow

1. Run the app: `flutter run`
2. Test signup flow:
   - Email signup
   - Phone signup (OTP)
   - Google signup (mock for now)
3. Test login flow:
   - Username/Email/Phone login
   - Google login

## Features Implemented

### Signup Flow (5 Steps)
1. **Identifier Collection**: Choose Email, Phone, or Google
2. **Verification**: OTP verification for Email/Phone
3. **Account Setup**: Username, password (optional for Google), full name
4. **Age Verification**: Date of birth with age restrictions
5. **Account Creation**: Success screen and auto-login

### Login Flow
- Username + Password
- Email + Password
- Phone + OTP
- Google OAuth

### Security Features
- JWT token management with refresh tokens
- Device fingerprinting
- Rate limiting
- Password strength validation
- Age verification (COPPA compliance)
- Session management

## Database Tables

- `users`: User accounts
- `auth_providers`: Authentication methods per user
- `signup_sessions`: Temporary signup sessions
- `refresh_tokens`: JWT refresh tokens
- `device_sessions`: Device tracking
- `profiles`: User profiles

## Important Notes

1. **Google OAuth**: Currently mocked. Replace `GoogleAuthService` with real Google Sign-In implementation for production.

2. **OTP**: Uses Supabase Auth's built-in OTP. For production phone OTP, configure Twilio in Supabase.

3. **JWT Tokens**: The current implementation uses simple token generation. For production, implement proper JWT signing on your backend.

4. **Password Hashing**: Currently uses SHA-256. For production, use Argon2 (Supabase handles this automatically).

5. **Environment Variables**: Never commit `.env` files. They're already in `.gitignore`.

## Troubleshooting

### Supabase Connection Issues
- Verify your Supabase URL and anon key
- Check network connectivity
- Ensure Supabase project is active

### OTP Not Received
- Check Supabase Auth logs
- Verify email/phone provider is enabled
- For phone OTP, ensure Twilio is configured

### Token Refresh Issues
- Check token expiry times in `AuthConstants`
- Verify refresh token is stored securely
- Check device session is created

## Next Steps

1. Implement real Google OAuth
2. Add password reset functionality
3. Implement 2FA for suspicious logins
4. Add email verification links
5. Set up production OTP provider (Twilio)

## Support

For issues or questions, refer to:
- Supabase Documentation: https://supabase.com/docs
- Flutter Documentation: https://flutter.dev/docs
