import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'api/session_store.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/csv_upload_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Restore persisted session token before the app renders anything
  await SessionStore.instance.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CsvUploadProvider()),
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
    // Splash is already removed after 3s — try to restore the session in the meantime
    final token = SessionStore.instance.token;

    if (token != null && token.isNotEmpty) {
      // Verify the saved token is still valid by fetching the current user
      final restored =
          await context.read<AuthProvider>().tryRestoreSession();
      setState(() {
        _hasSession = restored;
        _ready = true;
      });
    } else {
      setState(() {
        _hasSession = false;
        _ready = true;
      });
    }

    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Still checking session — keep splash visible via a blank scaffold
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: SizedBox.shrink()),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _hasSession ? const DashboardScreen() : const WelcomeScreen(),
    );
  }
}
