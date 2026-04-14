import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'onboarding_step1_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final _emailCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _selectedRole = 'PARENT';
  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Password strength (0–4)
  int _passwordStrength = 0;

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

    _passwordCtrl.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final p = _passwordCtrl.text;
    int strength = 0;
    if (p.length >= 6) strength++;
    if (p.length >= 10) strength++;
    if (p.contains(RegExp(r'[0-9]'))) strength++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1: return 'Weak';
      case 2: return 'Fair — add numbers or symbols';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return AppColors.error;
      case 2: return AppColors.accent;
      case 3: return AppColors.secondary;
      case 4: return AppColors.secondary;
      default: return AppColors.divider;
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
      role: _selectedRole,   // ← use the dropdown value, not the controller
    );
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingStep1Screen()),
        (route) => false,
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2B55),
              Color(0xFF1A4080),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navy header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Eyebrow
                        Text(
                          'GET STARTED',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha:0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Headline
                        const Text(
                          'Create your\naccount',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        // Text(
                        //   "You'll set up your profile after sign up",
                        //   style: TextStyle(
                        //     fontFamily: 'Outfit',
                        //     fontSize: 13,
                        //     color: Colors.white.withValues(alpha:0.5),
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  // White card body
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(24, 32, 24, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'Full name'),
                              const SizedBox(height: 10),
                              _InputField(
                                controller: _fullNameCtrl,
                                hint: 'Jane Doe',
                                icon: Icons.person_outline_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().length < 2) {
                                    return 'Full name is required';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Email
                              const _FieldLabel(label: 'Email address'),
                              const SizedBox(height: 10),
                              _InputField(
                                controller: _emailCtrl,
                                hint: 'you@school.edu',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Email is required';
                                  if (!v.contains('@'))
                                    return 'Enter a valid email';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password
                              const _FieldLabel(label: 'Password'),
                              const SizedBox(height: 10),
                              _InputField(
                                controller: _passwordCtrl,
                                hint: 'Create a password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !_passwordVisible,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() =>
                                      _passwordVisible = !_passwordVisible),
                                  child: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textHint,
                                    size: 18,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Password is required';
                                  if (v.length < 8)
                                    return 'Minimum 8 characters';
                                  return null;
                                },
                              ),

                              // Password strength bar
                              if (_passwordCtrl.text.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: List.generate(4, (i) {
                                    return Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            right: i < 3 ? 4 : 0),
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: i < _passwordStrength
                                              ? _strengthColor
                                              : AppColors.divider,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _strengthLabel,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    color: _strengthColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Confirm password
                              const _FieldLabel(label: 'Confirm password'),
                              const SizedBox(height: 10),
                              _InputField(
                                controller: _confirmPasswordCtrl,
                                hint: 'Re-enter password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !_confirmPasswordVisible,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() =>
                                      _confirmPasswordVisible =
                                          !_confirmPasswordVisible),
                                  child: Icon(
                                    _confirmPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textHint,
                                    size: 18,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Please confirm your password';
                                  if (v != _passwordCtrl.text)
                                    return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // role selection
                              const _FieldLabel(label: 'I am a'),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                onChanged: (v) => setState(() => _selectedRole = v!),
                                validator: (v) => v == null || v.isEmpty ? 'Please select a role' : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.textSecondary),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.divider),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.divider),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'PARENT', child: Text('Parent')),
                                  DropdownMenuItem(value: 'DRIVER', child: Text('Driver')),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Error banner
                              if (auth.hasError &&
                                  auth.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _ErrorBanner(message: auth.errorMessage!),
                              ],

                              const SizedBox(height: 28),

                              // ── Create account button ─────
                              _CreateAccountButton(
                                isLoading: auth.isLoading,
                                onTap: _handleSignUp,
                              ),

                              const SizedBox(height: 28),

                              // ── Sign in redirect ──────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _goToLogin,
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Field label

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}

// Input field

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: AppColors.textHint,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}

// Create account button

class _CreateAccountButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _CreateAccountButton(
      {required this.isLoading, required this.onTap});

  @override
  State<_CreateAccountButton> createState() => _CreateAccountButtonState();
}

class _CreateAccountButtonState extends State<_CreateAccountButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha:0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDark,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Create account',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Error banner

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha:0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}