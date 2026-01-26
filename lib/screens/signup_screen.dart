import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../theme/instagram_theme.dart';
import '../widgets/clay_container.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  String _selectedMethod = 'email'; // 'email', 'phone'
  bool _isPasswordVisible = false;
  bool _isOTPSent = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_selectedMethod == 'email' && _emailController.text.isEmpty) {
      _showError('Please enter your email first');
      return;
    }
    if (_selectedMethod == 'phone' && _phoneController.text.isEmpty) {
      _showError('Please enter your phone number first');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isOTPSent = true;
      _isLoading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('OTP sent successfully!'),
        backgroundColor: InstagramTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: InstagramTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_acceptedTerms) {
      _showError('Please accept Terms & Privacy Policy');
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (!_isOTPSent) {
        await _sendOTP();
        return;
      }

      if (_otpController.text.isEmpty) {
        _showError('Please enter OTP');
        return;
      }

      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SignUpSuccessScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final maxWidth = isTablet ? 500.0 : size.width;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: InstagramTheme.responsivePadding(context),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Center(
                        child: ClayContainer(
                          width: 80,
                          height: 80,
                          borderRadius: 40,
                          child: Center(
                            child: Icon(
                              Icons.smart_toy_outlined,
                              size: 40,
                              color: InstagramTheme.primaryPink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 32),

                      // Method Selection
                      Row(
                        children: [
                          Expanded(
                            child: ClayButton(
                              color: _selectedMethod == 'email'
                                  ? InstagramTheme.primaryPink
                                  : InstagramTheme.surfaceWhite,
                              onPressed: () {
                                setState(() {
                                  _selectedMethod = 'email';
                                  _isOTPSent = false;
                                });
                              },
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  color: _selectedMethod == 'email'
                                      ? InstagramTheme.backgroundWhite
                                      : InstagramTheme.textGrey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ClayButton(
                              color: _selectedMethod == 'phone'
                                  ? InstagramTheme.primaryPink
                                  : InstagramTheme.surfaceWhite,
                              onPressed: () {
                                setState(() {
                                  _selectedMethod = 'phone';
                                  _isOTPSent = false;
                                });
                              },
                              child: Text(
                                'Phone',
                                style: TextStyle(
                                  color: _selectedMethod == 'phone'
                                      ? InstagramTheme.backgroundWhite
                                      : InstagramTheme.textGrey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: InstagramTheme.textBlack),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email/Phone Field
                      if (_selectedMethod == 'email')
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: InstagramTheme.textBlack),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Enter email';
                            if (!value!.contains('@')) return 'Invalid email';
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: InstagramTheme.textBlack),
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Enter phone number' : null,
                        ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: InstagramTheme.textBlack),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: InstagramTheme.textGrey,
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Enter password';
                          if (value!.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // OTP Field
                      if (_isOTPSent)
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: InstagramTheme.textBlack),
                          decoration: const InputDecoration(
                            labelText: 'OTP',
                            prefixIcon: Icon(Icons.lock_clock_outlined),
                          ),
                        ),
                      if (_isOTPSent) const SizedBox(height: 16),

                      // Terms
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            activeColor: InstagramTheme.primaryPink,
                            checkColor: InstagramTheme.backgroundWhite,
                            onChanged: (val) =>
                                setState(() => _acceptedTerms = val ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'I accept Terms & Conditions and Privacy Policy',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Button
                      SizedBox(
                        height: 56,
                        child: ClayButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        InstagramTheme.backgroundWhite),
                                  ),
                                )
                              : Text(_isOTPSent ? 'VERIFY & SIGN UP' : 'SEND OTP'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpSuccessScreen extends StatelessWidget {
  const SignUpSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: InstagramTheme.responsivePadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClayContainer(
                  width: 120,
                  height: 120,
                  borderRadius: 60,
                  child: Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: InstagramTheme.primaryPink,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Account Created!',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your account has been successfully created.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ClayButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('GO TO LOGIN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
