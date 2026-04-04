import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'parent_dashboard.dart';
import 'driver_dashboard.dart';
import 'admin_dashboard.dart';

/// Entry point — reads role from AuthProvider,
/// loads the right data, renders the right view.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = context.read<AuthProvider>().selectedRole;
      final roleStr = role?.name ?? 'parent';
      context.read<DashboardProvider>().loadDashboard(roleStr);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;
    final dashboard = context.watch<DashboardProvider>();

    if (dashboard.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (role) {
      case UserRole.driver:
        return const DriverDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.parent:
      default:
        return const ParentDashboard();
    }
  }
}