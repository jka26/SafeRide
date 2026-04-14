import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../screens/welcome_screen.dart';

/// Reusable logout button — call showLogoutDialog(context) from any app bar.
class LogoutButton extends StatelessWidget {
  final Color iconColor;
  const LogoutButton({super.key, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.logout_rounded, color: iconColor, size: 22),
      tooltip: 'Logout',
      onPressed: () => _showLogoutDialog(context),
    );
  }

  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Log out?',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D2B55),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will be returned to the welcome screen. '
              'Your data will remain safe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: Color(0xFF6B7A99),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
        actions: [
          // Cancel
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7A99),
              ),
            ),
          ),

          // Confirm logout
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Log out',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _performLogout(BuildContext context) {
    // Clear auth state
    context.read<AuthProvider>().signOut();

    // Clear dashboard state
    context.read<DashboardProvider>().clearDashboardState();

    // Navigate to welcome screen, removing all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      (route) => false,
    );
  }
}