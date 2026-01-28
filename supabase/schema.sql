-- Instagram-like Authentication System Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE provider_type AS ENUM ('email', 'phone', 'google', 'username');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'expired');

-- 1. Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE,
    phone TEXT UNIQUE,
    full_name TEXT,
    date_of_birth DATE NOT NULL,
    is_under_18 BOOLEAN GENERATED ALWAYS AS (
        EXTRACT(YEAR FROM AGE(date_of_birth)) < 18
    ) STORED,
    avatar_url TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_is_active ON users(is_active);

-- 2. Auth providers table
CREATE TABLE auth_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_type provider_type NOT NULL,
    provider_id TEXT NOT NULL,
    password_hash TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, provider_type, provider_id)
);

-- Indexes for auth_providers
CREATE INDEX idx_auth_providers_user_id ON auth_providers(user_id);
CREATE INDEX idx_auth_providers_provider ON auth_providers(provider_type, provider_id);

-- 3. Signup sessions table (temporary)
CREATE TABLE signup_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_token TEXT UNIQUE NOT NULL,
    identifier_type provider_type NOT NULL,
    identifier_value TEXT NOT NULL,
    otp_code TEXT,
    otp_expires_at TIMESTAMP WITH TIME ZONE,
    verification_status verification_status DEFAULT 'pending',
    step INTEGER DEFAULT 1 CHECK (step >= 1 AND step <= 5),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Indexes for signup_sessions
CREATE INDEX idx_signup_sessions_token ON signup_sessions(session_token);
CREATE INDEX idx_signup_sessions_expires ON signup_sessions(expires_at);
CREATE INDEX idx_signup_sessions_identifier ON signup_sessions(identifier_type, identifier_value);

-- 4. Refresh tokens table
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    device_id TEXT NOT NULL,
    device_fingerprint TEXT,
    ip_address TEXT,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for refresh_tokens
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_device ON refresh_tokens(device_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);

-- 5. Device sessions table
CREATE TABLE device_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id TEXT UNIQUE NOT NULL,
    device_name TEXT,
    device_type TEXT,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_trusted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for device_sessions
CREATE INDEX idx_device_sessions_user_id ON device_sessions(user_id);
CREATE INDEX idx_device_sessions_device_id ON device_sessions(device_id);

-- 6. Profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 0,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for profiles
CREATE INDEX idx_profiles_user_id ON profiles(user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to check username availability
CREATE OR REPLACE FUNCTION check_username_availability(username_to_check TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM users WHERE username = username_to_check
    );
END;
$$ LANGUAGE plpgsql;

-- Function to create user account (called after signup completion)
CREATE OR REPLACE FUNCTION create_user_account(
    p_username TEXT,
    p_email TEXT,
    p_phone TEXT,
    p_full_name TEXT,
    p_date_of_birth DATE,
    p_password_hash TEXT,
    p_provider_type provider_type,
    p_google_id TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_profile_id UUID;
BEGIN
    -- Create user
    INSERT INTO users (username, email, phone, full_name, date_of_birth, is_active)
    VALUES (p_username, p_email, p_phone, p_full_name, p_date_of_birth, true)
    RETURNING id INTO v_user_id;

    -- Create auth provider
    INSERT INTO auth_providers (user_id, provider_type, provider_id, password_hash, is_verified)
    VALUES (
        v_user_id,
        p_provider_type,
        COALESCE(p_google_id, p_email, p_phone, p_username),
        p_password_hash,
        true
    );

    -- Create profile
    INSERT INTO profiles (user_id)
    VALUES (v_user_id)
    RETURNING id INTO v_profile_id;

    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to rotate refresh token
CREATE OR REPLACE FUNCTION rotate_refresh_token(
    p_old_token TEXT,
    p_device_id TEXT,
    p_new_token TEXT,
    p_expires_at TIMESTAMP WITH TIME ZONE
)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get user_id from old token
    SELECT user_id INTO v_user_id
    FROM refresh_tokens
    WHERE token = p_old_token
        AND device_id = p_device_id
        AND is_revoked = false
        AND expires_at > NOW();

    IF v_user_id IS NULL THEN
        RETURN false;
    END IF;

    -- Revoke old token
    UPDATE refresh_tokens
    SET is_revoked = true
    WHERE token = p_old_token;

    -- Create new token
    INSERT INTO refresh_tokens (user_id, token, device_id, expires_at)
    VALUES (v_user_id, p_new_token, p_device_id, p_expires_at);

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to invalidate user sessions
CREATE OR REPLACE FUNCTION invalidate_user_sessions(
    p_user_id UUID,
    p_keep_device_id TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE refresh_tokens
    SET is_revoked = true
    WHERE user_id = p_user_id
        AND (p_keep_device_id IS NULL OR device_id != p_keep_device_id);

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE signup_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users: Users can read their own data, public can check username availability
CREATE POLICY "Users can read own data" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Public can check username availability" ON users
    FOR SELECT USING (true);

-- Auth providers: Users can read their own auth providers
CREATE POLICY "Users can read own auth providers" ON auth_providers
    FOR SELECT USING (auth.uid() = user_id);

-- Signup sessions: Anyone can create, read own session by token
CREATE POLICY "Anyone can create signup session" ON signup_sessions
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Can read own signup session" ON signup_sessions
    FOR SELECT USING (true); -- Will be validated by session_token in application

-- Refresh tokens: Users can manage their own tokens
CREATE POLICY "Users can read own refresh tokens" ON refresh_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own refresh tokens" ON refresh_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own refresh tokens" ON refresh_tokens
    FOR UPDATE USING (auth.uid() = user_id);

-- Device sessions: Users can manage their own devices
CREATE POLICY "Users can read own device sessions" ON device_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own device sessions" ON device_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own device sessions" ON device_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- Profiles: Users can read their own profile, public can read basic profile info
CREATE POLICY "Users can read own profile" ON profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Public can read basic profile info" ON profiles
    FOR SELECT USING (true);

-- Cleanup function for expired signup sessions (run periodically)
CREATE OR REPLACE FUNCTION cleanup_expired_signup_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    DELETE FROM signup_sessions
    WHERE expires_at < NOW() OR verification_status = 'expired';

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;
