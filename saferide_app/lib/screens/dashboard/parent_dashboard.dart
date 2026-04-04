import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/notification_model.dart';
import '../../notifications/notification_screen.dart';
import '../../shared/placeholder_screen.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final child = dashboard.child;
    final trip = dashboard.activeTrip;
    final notifications = dashboard.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ParentAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (child != null) _ChildCard(child: child, trip: trip),
                  const SizedBox(height: 14),
                  if (trip != null) _LiveTrackingCard(trip: trip),
                  const SizedBox(height: 14),
                  if (trip != null) _ScheduleCard(trip: trip),
                  const SizedBox(height: 14),
                  _NotificationsCard(notifications: notifications),
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

class _ParentAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SafeRide School',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 16,
                  fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Parent Portal',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white60)),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            )),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
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

class _ChildCard extends StatelessWidget {
  final child;
  final trip;
  const _ChildCard({required this.child, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PlaceholderScreen(
                title: 'Child Details',
                subtitle: 'View and manage your child\'s transport details and history.',
                icon: Icons.child_care_rounded,
                color: AppColors.primaryLight,
              ),
            )),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: Center(
                    child: Text(child.initials,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 16,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 15,
                          fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(child.grade,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 13,
                          color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Status  On Bus',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppColors.secondary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Active',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (trip != null)
            Row(
              children: [
                Expanded(child: _InfoChip(label: 'Bus Number', value: trip.busNumber, color: AppColors.primaryLight)),
                const SizedBox(width: 10),
                Expanded(child: _InfoChip(label: 'Route', value: trip.routeName, color: AppColors.accent)),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _LiveTrackingCard extends StatelessWidget {
  final trip;
  const _LiveTrackingCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 6),
              Text('Live Tracking',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated Arrival',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(trip.estimatedArrival ?? '--',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 24,
                      fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Current Stop',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('${trip.currentStop} of ${trip.totalStops}',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PlaceholderScreen(
                title: 'Live Map',
                subtitle: 'Real-time bus location will appear here once GPS tracking is connected.',
                icon: Icons.map_rounded,
                color: AppColors.primary,
              ),
            )),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('View on Map',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
                      fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final trip;
  const _ScheduleCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 6),
              Text("Today's Schedule",
                style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          _ScheduleRow(label: 'Pick-up Time', time: trip.pickupTime ?? '--',
            status: 'Completed', statusColor: AppColors.secondary),
          const SizedBox(height: 10),
          _ScheduleRow(label: 'Drop-off Time', time: trip.dropOffTime ?? '--',
            status: 'In Progress', statusColor: AppColors.primaryLight),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String label, time, status;
  final Color statusColor;
  const _ScheduleRow({required this.label, required this.time,
    required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: AppColors.textSecondary)),
              Text(time, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
              fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  final List<NotificationModel> notifications;
  const _NotificationsCard({required this.notifications});

  Color _iconColor(String type) {
    switch (type) {
      case 'success': return AppColors.secondary;
      case 'warning': return AppColors.accent;
      default: return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.notifications_rounded, color: AppColors.accent, size: 18),
                SizedBox(width: 6),
                Text('Recent Notifications',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                )),
                child: const Text('View All',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...notifications.take(3).map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    n.type == 'success' ? Icons.check_circle_rounded
                      : n.type == 'warning' ? Icons.warning_rounded
                      : Icons.info_rounded,
                    color: _iconColor(n.type), size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.message, style: const TextStyle(fontFamily: 'Outfit',
                        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text(n.timeAgo, style: const TextStyle(fontFamily: 'Outfit',
                        fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  )),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}