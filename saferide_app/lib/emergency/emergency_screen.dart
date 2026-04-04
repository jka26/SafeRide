import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _alertSent = false;
  bool _sending = false;

  Future<void> _sendAlert(String type) async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _sending = false;
      _alertSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.error,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Report Emergency',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _alertSent ? _SuccessView() : _AlertForm(
          sending: _sending,
          onSend: _sendAlert,
        ),
      ),
    );
  }
}

class _AlertForm extends StatelessWidget {
  final bool sending;
  final Function(String) onSend;

  const _AlertForm({required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use this only for genuine emergencies. '
                  'School admin and emergency contacts will be notified immediately.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.error,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Select emergency type',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        _EmergencyOption(
          icon: Icons.car_crash_rounded,
          label: 'Vehicle Accident',
          description: 'Bus involved in a collision or breakdown',
          color: AppColors.error,
          sending: sending,
          onTap: () => onSend('accident'),
        ),
        const SizedBox(height: 10),
        _EmergencyOption(
          icon: Icons.local_hospital_rounded,
          label: 'Medical Emergency',
          description: 'Student or driver requires medical attention',
          color: const Color(0xFFDC2626),
          sending: sending,
          onTap: () => onSend('medical'),
        ),
        const SizedBox(height: 10),
        _EmergencyOption(
          icon: Icons.security_rounded,
          label: 'Security Threat',
          description: 'Safety concern on or around the bus',
          color: AppColors.accent,
          sending: sending,
          onTap: () => onSend('security'),
        ),
        const SizedBox(height: 10),
        _EmergencyOption(
          icon: Icons.help_rounded,
          label: 'Other Emergency',
          description: 'Any other urgent situation requiring assistance',
          color: AppColors.primaryLight,
          sending: sending,
          onTap: () => onSend('other'),
        ),
      ],
    );
  }
}

class _EmergencyOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool sending;
  final VoidCallback onTap;

  const _EmergencyOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.sending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                  const SizedBox(height: 2),
                  Text(description,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    )),
                ],
              ),
            ),
            sending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(Icons.chevron_right_rounded,
                    color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.secondary, size: 44),
        ),
        const SizedBox(height: 20),
        const Text(
          'Alert Sent',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'School admin and emergency contacts\nhave been notified.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Back to Dashboard',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}