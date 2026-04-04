import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/bus_model.dart';
import '../../models/student_model.dart';

class BusStudentsScreen extends StatelessWidget {
  final BusModel bus;
  final List<StudentModel> students;

  const BusStudentsScreen({
    super.key,
    required this.bus,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6D28D9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bus ${bus.busNumber} — Students',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              bus.routeName,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${students.length} students',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: students.isEmpty
          ? const Center(
              child: Text(
                'No students assigned to this bus yet.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _StudentTile(student: students[index]);
              },
            ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final StudentModel student;
  const _StudentTile({required this.student});

  Color get _avatarColor {
    final colors = [
      AppColors.primaryLight,
      AppColors.secondary,
      AppColors.accent,
      AppColors.error,
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
    ];
    return colors[student.name.length % colors.length];
  }

  Color get _statusColor {
    switch (student.status) {
      case 'boarded': return AppColors.secondary;
      case 'absent': return AppColors.error;
      default: return AppColors.accent;
    }
  }

  String get _statusLabel {
    switch (student.status) {
      case 'boarded': return 'On Bus';
      case 'absent': return 'Absent';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                student.initials,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.grade,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.textHint),
                    Text(
                      ' ${student.stopName ?? "--"}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textHint),
                    Text(
                      ' ${student.dropOffTime ?? "--"}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withOpacity(0.3)),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}