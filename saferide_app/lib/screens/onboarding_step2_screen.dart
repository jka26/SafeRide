import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import 'dashboard/dashboard_screen.dart';

class OnboardingStep2Screen extends StatefulWidget {
  final String fullName;
  final String phone;

  const OnboardingStep2Screen({
    super.key,
    required this.fullName,
    required this.phone,
  });

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final _formKey = GlobalKey<FormState>();

  // Parent fields
  final _childNameCtrl = TextEditingController();
  final _childGradeCtrl = TextEditingController();
  final _stopNameCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  // Driver fields (bus/route assigned by admin)
  final _driverEmergencyNameCtrl = TextEditingController();
  final _driverEmergencyPhoneCtrl = TextEditingController();

  Future<void> _pickEmergencyContact({
    required TextEditingController nameController,
    required TextEditingController phoneController,
  }) async {
    try {
      final permissionStatus = await Permission.contacts.request();
      if (permissionStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Contacts permission is permanently denied. Enable it in settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      final hasPermission = permissionStatus.isGranted ||
          await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact permission denied. Enter details manually.'),
            ),
          );
        }
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      final detailed = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
      );
      if (detailed == null) return;

      final selectedPhone = detailed.phones.isNotEmpty
          ? detailed.phones.first.normalizedNumber.isNotEmpty
              ? detailed.phones.first.normalizedNumber
              : detailed.phones.first.number
          : '';

      nameController.text = detailed.displayName.trim();
      if (selectedPhone.isNotEmpty) {
        phoneController.text = selectedPhone.trim();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access contacts. Enter details manually.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
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
    _childNameCtrl.dispose();
    _childGradeCtrl.dispose();
    _stopNameCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _driverEmergencyNameCtrl.dispose();
    _driverEmergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final role = context.read<AuthProvider>().selectedRole;
    final isDriver = role?.name == 'driver';

    final onboarding = context.read<OnboardingProvider>();

    if (isDriver) {
      await onboarding.submitDriverDetails(
        emergencyContactName: _driverEmergencyNameCtrl.text.trim(),
        emergencyContactPhone: _driverEmergencyPhoneCtrl.text.trim(),
      );
    } else {
      await onboarding.submitParentDetails(
        fullName: widget.fullName,
        phone: widget.phone,
        childName: _childNameCtrl.text.trim(),
        childGrade: _childGradeCtrl.text.trim(),
        stopName: _stopNameCtrl.text.trim(),
        emergencyContactName: _emergencyNameCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      );
    }

    if (onboarding.isSuccess && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false, // clears the entire back stack
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;
    final isDriver = role?.name == 'driver';
    final onboarding = context.watch<OnboardingProvider>();

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
                        // Step indicator + back
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              _StepDot(active: false),
                              const SizedBox(width: 6),
                              _StepDot(active: true),
                              const SizedBox(width: 12),
                              Text('Step 2 of 2',
                                style: TextStyle(fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5))),
                            ]),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isDriver
                              ? 'DRIVER DETAILS'
                              : 'CHILD DETAILS',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(
                          isDriver
                              ? 'Emergency\ncontact'
                              : 'About your\nchild',
                          style: const TextStyle(fontFamily: 'Outfit',
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: Colors.white, letterSpacing: -0.5,
                            height: 1.15)),
                        const SizedBox(height: 8),
                        Text(
                          isDriver
                              ? 'Your school assigns your bus and route. Add who we should call in an emergency.'
                              : 'This helps us track your child and send you the right alerts.',
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
                              // Render fields based on role
                              if (isDriver)
                                _DriverFields(
                                  emergencyNameCtrl: _driverEmergencyNameCtrl,
                                  emergencyPhoneCtrl: _driverEmergencyPhoneCtrl,
                                  onPickEmergencyContact: () => _pickEmergencyContact(
                                    nameController: _driverEmergencyNameCtrl,
                                    phoneController: _driverEmergencyPhoneCtrl,
                                  ),
                                )
                              else
                                _ParentFields(
                                  childNameCtrl: _childNameCtrl,
                                  childGradeCtrl: _childGradeCtrl,
                                  stopNameCtrl: _stopNameCtrl,
                                  emergencyNameCtrl: _emergencyNameCtrl,
                                  emergencyPhoneCtrl: _emergencyPhoneCtrl,
                                  onPickEmergencyContact: () => _pickEmergencyContact(
                                    nameController: _emergencyNameCtrl,
                                    phoneController: _emergencyPhoneCtrl,
                                  ),
                                ),

                              // Error banner
                              if (onboarding.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _ErrorBanner(
                                    message: onboarding.errorMessage!),
                              ],

                              const SizedBox(height: 32),

                              // Submit button
                              _SubmitButton(
                                isLoading: onboarding.isLoading,
                                isDriver: isDriver,
                                onTap: _handleSubmit,
                              ),

                              const SizedBox(height: 20),

                              Center(
                                child: Text(
                                  'You can update these details later in your profile',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Outfit',
                                    fontSize: 12, color: AppColors.textHint),
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

// ── Parent fields ─────────────────────────────────────────────────────────────

class _ParentFields extends StatelessWidget {
  final TextEditingController childNameCtrl;
  final TextEditingController childGradeCtrl;
  final TextEditingController stopNameCtrl;
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;
  final VoidCallback onPickEmergencyContact;

  const _ParentFields({
    required this.childNameCtrl,
    required this.childGradeCtrl,
    required this.stopNameCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
    required this.onPickEmergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: "Child's full name"),
        const SizedBox(height: 6),
        _InputField(
          controller: childNameCtrl,
          hint: 'e.g. Emma Johnson',
          icon: Icons.child_care_rounded,
          keyboardType: TextInputType.name,
          validator: (v) => v == null || v.trim().isEmpty
              ? "Child's name is required" : null,
        ),

        const SizedBox(height: 16),

        const _FieldLabel(label: 'Grade / Class'),
        const SizedBox(height: 6),
        _InputField(
          controller: childGradeCtrl,
          hint: 'e.g. Grade 5 or JHS 1',
          icon: Icons.school_rounded,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Grade is required' : null,
        ),

        const SizedBox(height: 16),

        const _FieldLabel(label: 'Bus stop name'),
        const SizedBox(height: 6),
        _InputField(
          controller: stopNameCtrl,
          hint: 'e.g. Stop 4 or Accra Mall',
          icon: Icons.location_on_rounded,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Stop name is required' : null,
        ),

        const SizedBox(height: 24),

        // Emergency contact section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.emergency_rounded, color: AppColors.error, size: 16),
                SizedBox(width: 6),
                Text('Emergency Contact',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.error)),
              ]),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onPickEmergencyContact,
                  icon: const Icon(Icons.contacts_rounded, size: 16),
                  label: const Text('Pick from contacts'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _FieldLabel(label: 'Contact name'),
              const SizedBox(height: 6),
              _InputField(
                controller: emergencyNameCtrl,
                hint: 'e.g. John Johnson',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Emergency contact name is required' : null,
              ),
              const SizedBox(height: 12),
              const _FieldLabel(label: 'Contact phone'),
              const SizedBox(height: 6),
              _InputField(
                controller: emergencyPhoneCtrl,
                hint: '+233 XX XXX XXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Emergency contact phone is required';
                  if (v.trim().length < 10)
                    return 'Enter a valid phone number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Driver fields ─────────────────────────────────────────────────────────────

class _DriverFields extends StatelessWidget {
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;
  final VoidCallback onPickEmergencyContact;

  const _DriverFields({
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
    required this.onPickEmergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emergency contact section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.emergency_rounded, color: AppColors.error, size: 16),
                SizedBox(width: 6),
                Text('Emergency Contact',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.error)),
              ]),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onPickEmergencyContact,
                  icon: const Icon(Icons.contacts_rounded, size: 16),
                  label: const Text('Pick from contacts'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _FieldLabel(label: 'Contact name'),
              const SizedBox(height: 6),
              _InputField(
                controller: emergencyNameCtrl,
                hint: 'e.g. James Davis',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Emergency contact name is required' : null,
              ),
              const SizedBox(height: 12),
              const _FieldLabel(label: 'Contact phone'),
              const SizedBox(height: 6),
              _InputField(
                controller: emergencyPhoneCtrl,
                hint: '+233 XX XXX XXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Emergency contact phone is required';
                  if (v.trim().length < 10)
                    return 'Enter a valid phone number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final bool isDriver;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.isLoading,
    required this.isDriver,
    required this.onTap,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
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
            boxShadow: [BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDark, strokeWidth: 2.5))
                : Text(
                    widget.isDriver
                        ? 'Complete Setup'
                        : 'Go to Dashboard',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
              color: AppColors.error, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}