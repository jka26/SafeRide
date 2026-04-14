import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/student_model.dart';
import '../../emergency/emergency_screen.dart';
import '../../maps/route_map_screen.dart';
import '../../ui/app_motion.dart';
import '../../widgets/logout_button.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final trip = dashboard.activeTrip;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _DriverAppBar(
            user: dashboard.currentUser,
            busNumber: trip?.busNumber ?? '--',
            routeName: trip?.routeName ?? '--',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(
                    child: _TripStatusCard(
                      tripStarted: dashboard.tripStarted,
                      tripStatus: trip?.status ?? 'idle',
                      canToggle: trip != null,
                      onToggle: () => context.read<DashboardProvider>().toggleTrip(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: _StatsRow(
                      checkedIn: dashboard.checkedIn,
                      pending: dashboard.pending,
                      absent: dashboard.absent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _StudentList(students: dashboard.students),
                  ),
                  const SizedBox(height: 14),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 180),
                    child: _QuickActions(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverAppBar extends StatelessWidget {
  final user;
  final String busNumber;
  final String routeName;
  const _DriverAppBar({
    required this.user,
    required this.busNumber,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(color: AppColors.secondary),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Driver Portal',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16,
                    fontWeight: FontWeight.w700, color: Colors.white)),
                Text(user?.name ?? 'Driver',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Bus $busNumber', style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white)),
                Text(routeName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const LogoutButton(),
        ],
      ),
    );
  }
}

class _TripStatusCard extends StatelessWidget {
  final bool tripStarted;
  final String tripStatus;
  final bool canToggle;
  final VoidCallback onToggle;
  const _TripStatusCard({
    required this.tripStarted,
    required this.tripStatus,
    required this.canToggle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Status',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('Trip status: ${tripStatus.toUpperCase()}',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: canToggle ? onToggle : null,
            child: Container(
              width: double.infinity, height: 48,
              decoration: BoxDecoration(
                color: canToggle
                    ? (tripStarted ? AppColors.error : AppColors.secondary)
                    : AppColors.textHint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tripStarted ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(tripStarted ? 'End Trip' : 'Start Trip',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
          if (!canToggle)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No current trip assignment.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int checkedIn, pending, absent;
  const _StatsRow({required this.checkedIn, required this.pending, required this.absent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatChip(value: checkedIn, label: 'Checked In', color: AppColors.secondary)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(value: pending, label: 'Pending', color: AppColors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(value: absent, label: 'Absent', color: AppColors.error)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 6)],
      ),
      child: Column(children: [
        Icon(
          label == 'Checked In' ? Icons.check_circle_rounded
            : label == 'Pending' ? Icons.schedule_rounded
            : Icons.cancel_rounded,
          color: color, size: 22,
        ),
        const SizedBox(height: 6),
        Text('$value', style: TextStyle(fontFamily: 'Outfit', fontSize: 20,
          fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
          color: AppColors.textSecondary)),
      ]),
    );
  }
}

// Student list with inline toggle

class _StudentList extends StatelessWidget {
  final List<StudentModel> students;
  const _StudentList({required this.students});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Student List',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
                child: Text('${students.length} students',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                    color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...students.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StudentRow(student: s),
          )),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final StudentModel student;
  const _StudentRow({required this.student});

  Color get _avatarColor {
    final colors = [
      AppColors.primaryLight, AppColors.secondary,
      AppColors.accent, AppColors.error,
      const Color(0xFF7C3AED), const Color(0xFFDB2777),
    ];
    return colors[student.name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Top row — student info
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _avatarColor, shape: BoxShape.circle),
                child: Center(child: Text(student.initials,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.white))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(student.grade,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                        color: AppColors.textSecondary)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textHint),
                      Text(' ${student.stopName ?? "--"}',
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: AppColors.textHint)),
                      const SizedBox(width: 8),
                      const Icon(Icons.schedule_rounded, size: 11, color: AppColors.textHint),
                      Text(' ${student.dropOffTime ?? "--"}',
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: AppColors.textHint)),
                    ]),
                  ],
                ),
              ),
              // Current status badge
              _StatusBadge(status: student.status),
            ],
          ),

          // Bottom row — inline toggle buttons
          if (student.status != 'boarded' && student.status != 'absent') ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: 'Present',
                    icon: Icons.check_rounded,
                    color: AppColors.secondary,
                    onTap: () => context
                        .read<DashboardProvider>()
                        .updateStudentStatus(student.id, 'boarded'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleButton(
                    label: 'Absent',
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: () => context
                        .read<DashboardProvider>()
                        .updateStudentStatus(student.id, 'absent'),
                  ),
                ),
              ],
            ),
          ],

          // Already marked — show undo option
          if (student.status == 'boarded' || student.status == 'absent') ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context
                  .read<DashboardProvider>()
                  .updateStudentStatus(student.id, 'pending'),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.undo_rounded, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text('Undo',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                      color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'boarded': return AppColors.secondary;
      case 'absent': return AppColors.error;
      default: return AppColors.accent;
    }
  }

  String get _label {
    switch (status) {
      case 'boarded': return 'On Bus';
      case 'absent': return 'Absent';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha:0.3)),
      ),
      child: Text(_label,
        style: TextStyle(fontFamily: 'Outfit', fontSize: 10,
          fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ToggleButton({required this.label, required this.icon,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
              fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// Quick actions

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RouteMapScreen(
                title: 'Full Route',
                color: AppColors.secondary,
              ),
            )),
            child: const _ActionRow(
              icon: Icons.map_rounded,
              label: 'View Full Route',
              color: AppColors.primaryLight,
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const EmergencyScreen(),
            )),
            child: const _ActionRow(
              icon: Icons.warning_rounded,
              label: 'Report Emergency',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
          fontWeight: FontWeight.w500, color: color)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: color.withValues(alpha:0.5), size: 18),
      ]),
    );
  }
}