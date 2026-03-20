import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
 
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
 
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSignIn() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }
 
  void _goToSignUp() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const SignUpScreen(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2B55), // deep navy top
              Color(0xFF1A4080), // slightly lighter navy bottom
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 25),

                    // ── Logo ─────────────────────────────────
                    _LogoBadge(),
 
                    const SizedBox(height: 24),
 
                    // ── App name ──────────────────────────────
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'SafeRide',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: ' School',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: AppColors.accentLight,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 10),

                    // ── Tagline ───────────────────────────────
                    Text(
                      'Every journey, accounted for.\nEvery ward, safe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.7,
                      ),
                    ),
 
                    const SizedBox(height: 20),

                     // ── Trust badges row ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TrustBadge(
                          icon: Icons.location_on_rounded,
                          label: 'Live GPS',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 10),
                        _TrustBadge(
                          icon: Icons.notifications_active_rounded,
                          label: 'Instant alerts',
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        _TrustBadge(
                          icon: Icons.shield_rounded,
                          label: 'Safe & secure',
                          color: AppColors.secondaryLight,
                        ),
                      ],
                    ),
 
                    const SizedBox(height: 32),

                    // ── Divider ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.12),
                            thickness: 1.5,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white.withOpacity(0.2),
                            size: 17,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.12),
                            thickness: 1.5,
                          ),
                        ),
                      ],
                    ),
 
                    const SizedBox(height: 28),

                    // ── Feature cards ─────────────────────────
                    _FeatureCard(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.secondary,
                      iconBg: AppColors.secondary.withOpacity(0.15),
                      title: 'Real-time bus tracking',
                      subtitle:
                          'Know exactly where your child\'s bus is at all times',
                    ),
                    const SizedBox(height: 8),
                    _FeatureCard(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: AppColors.accent,
                      iconBg: AppColors.accent.withOpacity(0.15),
                      title: 'Instant parent alerts',
                      subtitle:
                          'Get notified when your child boards or alights',
                    ),
                    const SizedBox(height: 8),
                    _FeatureCard(
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: AppColors.secondaryLight,
                      iconBg: AppColors.secondaryLight.withOpacity(0.12),
                      title: 'Emergency contacts',
                      subtitle:
                          'Quick access to contacts during incidents',
                    ),
 
                    const SizedBox(height: 40),

                    // ── CTA buttons ───────────────────────────
                    _PrimaryButton(
                      label: 'Create an account',
                      onTap: _goToSignUp,
                    ),
                    const SizedBox(height: 12),
                    _SecondaryButton(
                      label: 'Login',
                      onTap: _goToSignIn,
                    ),
 
                    const SizedBox(height: 28),
 
                    // ── Footer ────────────────────────────────
                    Text(
                      'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.28),
                        height: 1.7,
                      ),
                    ),
 
                    const SizedBox(height: 16),
                  ]
                )
              )
            )
          )
        )
      )
      );
    }
  }

// ── Logo Badge ──────────────────────────────────────────────────────────────── 
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        // White circle
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x3300BFA5),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.directions_bus_rounded,
                size: 45,
                color: AppColors.primary,
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Trust Badge ───────────────────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
 
  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Card ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
 
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // White with slight transparency — the "more white" feel
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary Button (amber) ────────────────────────────────────────────────────
 
class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
 
  const _PrimaryButton({required this.label, required this.onTap});
 
  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 
// ── Secondary Button (outlined white) ────────────────────────────────────────
 
class _SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
 
  const _SecondaryButton({required this.label, required this.onTap});
 
  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}
 
class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}