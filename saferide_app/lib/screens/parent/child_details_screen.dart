import 'package:flutter/material.dart';

import '../../maps/live_map_screen.dart';
import '../../models/student_model.dart';
import '../../models/trip_model.dart';
import '../../theme/app_theme.dart';

class ChildDetailsScreen extends StatelessWidget {
  const ChildDetailsScreen({
    super.key,
    required this.child,
    required this.trip,
  });

  final StudentModel child;
  final TripModel? trip;

  String get _statusLabel {
    switch (trip?.status) {
      case 'active':
        return 'On Bus';
      case 'completed':
        return 'Trip Completed';
      case 'idle':
        return 'Scheduled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'No Active Trip';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Child Details',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        child.initials,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
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
                          child.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          child.grade,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Status', value: _statusLabel),
            _DetailRow(label: 'Stop', value: child.stopName ?? '--'),
            _DetailRow(label: 'Drop-off Time', value: child.dropOffTime ?? '--'),
            _DetailRow(label: 'Bus', value: trip?.busNumber ?? '--'),
            _DetailRow(label: 'Route', value: trip?.routeName ?? '--'),
            if (trip?.currentStop != null && trip!.currentStop!.isNotEmpty)
              _DetailRow(label: 'Current Stop', value: trip!.currentStop!),
            if (trip?.estimatedArrival != null && trip!.estimatedArrival!.isNotEmpty)
              _DetailRow(label: 'ETA', value: trip!.estimatedArrival!),
            const SizedBox(height: 16),
            if (trip != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LiveMapScreen(tripId: trip!.id),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('View Live Map'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
