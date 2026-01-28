import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth/login/login_screen.dart';
import 'screens/home_dashboard.dart';
import 'theme/instagram_theme.dart';
import 'services/auth/jwt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BSmartApp());
}

class BSmartApp extends StatefulWidget {
  const BSmartApp({super.key});

  @override
  State<BSmartApp> createState() => _BSmartAppState();
}

class _BSmartAppState extends State<BSmartApp> {
  bool _isInitialized = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final jwtService = JWTService();
      final isAuth = await jwtService.isAuthenticated();
      
      setState(() {
        _isAuthenticated = isAuth;
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: InstagramTheme.primaryPink,
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'b Smart',
      debugShowCheckedModeBanner: false,
      theme: InstagramTheme.theme,
      home: _isAuthenticated ? const HomeDashboard() : const LoginScreen(),
      // Add route observer for auth state changes
      navigatorObservers: [
        _AuthRouteObserver(),
      ],
    );
  }
}

// Route observer to handle auth state changes
class _AuthRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkAuthAndRedirect(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkAuthAndRedirect(newRoute);
    }
  }

  Future<void> _checkAuthAndRedirect(Route<dynamic> route) async {
    // Check if we need to refresh token before accessing protected routes
    if (route.settings.name != '/login' && route.settings.name != '/signup') {
      final jwtService = JWTService();
      final isAuth = await jwtService.isAuthenticated();
      
      if (!isAuth && route.settings.name != '/login') {
        // Token expired or invalid, redirect to login
        // This would be handled by the app's navigation logic
      }
    }
  }
}
