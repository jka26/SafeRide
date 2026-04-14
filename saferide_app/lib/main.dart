import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'api/session_store.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/csv_upload_provider.dart';
import 'providers/onboarding_provider.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase before anything else
  await Firebase.initializeApp();

  // Restore persisted session token before the app renders anything
  await SessionStore.instance.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CsvUploadProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: const SafeRideApp(),
    ),
  );
}

class SafeRideApp extends StatefulWidget {
  const SafeRideApp({super.key});

  @override
  State<SafeRideApp> createState() => _SafeRideAppState();
}

class _SafeRideAppState extends State<SafeRideApp> {
  bool _ready = false;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final token = SessionStore.instance.token;

    if (token != null && token.isNotEmpty) {
      // Verify the saved token is still valid by calling GET /auth/me
      final restored = await context.read<AuthProvider>().restoreSession();
      setState(() {
        _hasSession = restored;
        _ready = true;
      });
      // Register FCM token now that we have a valid session
      if (restored) {
        unawaited(PushNotificationService.instance.initialize());
      }
    } else {
      setState(() {
        _hasSession = false;
        _ready = true;
      });
    }

    // Keep native splash visible for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Still checking session — keep splash visible via blank scaffold
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: SizedBox.shrink()),
      );
    }

    return MaterialApp(
      title: 'SafeRide School',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _hasSession
          ? const DashboardScreen()
          : const WelcomeScreen(),
    );
  }
}

/// Runs a future without awaiting — used for fire-and-forget side effects.
void unawaited(Future<void> future) {}
