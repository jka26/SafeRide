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
  UserRole? _loadedRole;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final role = auth.selectedRole;
    final userId = auth.currentUser?.id;
    if (role == null || userId == null) return;
    if (role == _loadedRole && userId == _loadedUserId) return;
    _loadedRole = role;
    _loadedUserId = userId;
    context.read<DashboardProvider>().loadDashboard(role.name);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;
    final dashboard = context.watch<DashboardProvider>();

    if (role == null || dashboard.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    late final Widget roleDashboard;
    switch (role) {
      case UserRole.driver:
        roleDashboard = const DriverDashboard();
      case UserRole.admin:
        roleDashboard = const AdminDashboard();
      case UserRole.parent:
      default:
        roleDashboard = const ParentDashboard();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey<UserRole>(role),
        child: roleDashboard,
      ),
    );
  }
}