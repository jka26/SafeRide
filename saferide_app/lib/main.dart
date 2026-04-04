import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:saferide_app/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import "providers/dashboard_provider.dart";
import "providers/csv_upload_provider.dart";

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    print("pausing...");
    await Future.delayed(const Duration(seconds: 3));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}