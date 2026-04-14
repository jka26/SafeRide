import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'onboarding_step2_screen.dart';

class OnboardingStep1Screen extends StatefulWidget {
  const OnboardingStep1Screen({super.key});

  @override
  State<OnboardingStep1Screen> createState() => _OnboardingStep1ScreenState();
}

class _OnboardingStep1ScreenState extends State<OnboardingStep1Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => OnboardingStep2Screen(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      ),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;
    final isDriver = role?.name == 'driver';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2B55), Color(0xFF1A4080)],
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
                  // ── Header ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step indicator
                        Row(children: [
                          _StepDot(active: true),
                          const SizedBox(width: 6),
                          _StepDot(active: false),
                          const SizedBox(width: 12),
                          Text('Step 1 of 2',
                            style: TextStyle(fontFamily: 'Outfit',
                              fontSize: 12, color: Colors.white.withOpacity(0.5))),
                        ]),
                        const SizedBox(height: 20),
                        Text('PERSONAL INFO',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        const Text('Tell us about\nyourself',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 28,
                            fontWeight: FontWeight.bold, color: Colors.white,
                            letterSpacing: -0.5, height: 1.15)),
                        const SizedBox(height: 8),
                        Text(
                          isDriver
                              ? 'We need a few details to set up your driver profile.'
                              : 'We need a few details to set up your parent profile.',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                            color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),

                  // ── White card body ───────────────────────
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
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full name
                              const _FieldLabel(label: 'Full name'),
                              const SizedBox(height: 6),
                              _InputField(
                                controller: _nameCtrl,
                                hint: 'e.g. Mary Johnson',
                                icon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.name,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Full name is required';
                                  if (v.trim().split(' ').length < 2)
                                    return 'Please enter your full name';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Phone number
                              const _FieldLabel(label: 'Phone number'),
                              const SizedBox(height: 6),
                              _InputField(
                                controller: _phoneCtrl,
                                hint: '+233 XX XXX XXXX',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d+\s]')),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Phone number is required';
                                  if (v.trim().length < 10)
                                    return 'Enter a valid phone number';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 36),

                              // Continue button
                              _ContinueButton(onTap: _goToStep2),

                              const SizedBox(height: 20),

                              // Progress note
                              Center(
                                child: Text(
                                  'Your information is safe and encrypted',
                                  style: TextStyle(fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: AppColors.textHint),
                                ),
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

// ── Step dot indicator ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Shared form widgets ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        letterSpacing: 0.2));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
        fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
          color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2)),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ContinueButton({required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
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
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 16,
                  fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                color: AppColors.primaryDark, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}