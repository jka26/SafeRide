import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/notification_model.dart';
import '../../notifications/notification_screen.dart';
import '../../maps/live_map_screen.dart';
import '../parent/child_details_screen.dart';
import '../../theme/app_theme.dart';
import '../../ui/app_motion.dart';
import '../../ui/dashboard_kit.dart';
import '../../widgets/logout_button.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final child = dashboard.child;
    final trip = dashboard.activeTrip;
    final notifications = dashboard.notifications;
    final children = dashboard.children;

    // Show loading spinner while data loads
    if (dashboard.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return DashboardShell(
      header: const _ParentAppBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (child != null)
            FadeSlideIn(
              child: _ChildCard(
                child: child,
                trip: trip,
                children: children,
                selectedIndex: dashboard.selectedChildIndex,
                onSelectChild: (index) => context.read<DashboardProvider>().selectChild(index),
              ),
            ),
          if (child != null) const SizedBox(height: 14),
          if (trip != null)
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _LiveTrackingCard(trip: trip),
            ),
          if (trip != null) const SizedBox(height: 14),
          if (trip != null)
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _ScheduleCard(trip: trip),
            ),
          if (trip != null) const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: _NotificationsCard(notifications: notifications),
          ),
        ],
      ),
    );
  }
}

class _ParentAppBar extends StatelessWidget {
  const _ParentAppBar();

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<DashboardProvider>().unreadNotifications;
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
          Row(
            children: [
              TapScale(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                )),
                child: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                    if (unread > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.accent, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const LogoutButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final child;
  final trip;
  final List children;
  final int selectedIndex;
  final ValueChanged<int> onSelectChild;
  const _ChildCard({
    required this.child,
    required this.trip,
    required this.children,
    required this.selectedIndex,
    required this.onSelectChild,
  });

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

  String get _badgeLabel {
    switch (trip?.status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'idle':
        return 'Scheduled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Idle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        children: [
          if (children.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(children.length, (index) {
                    final c = children[index];
                    final active = index == selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TapScale(
                        onTap: () => onSelectChild(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primaryLight : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? AppColors.primaryLight : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            c.name.toString(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          TapScale(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChildDetailsScreen(
                child: child,
                trip: trip,
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
              color: AppColors.secondary.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondary.withValues(alpha:0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Status  $_statusLabel',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppColors.secondary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                  child: Text(_badgeLabel,
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
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Live Tracking',
            subtitle: 'Bus location and ETA',
            trailing: StatusPill(
              label: trip.status.toString().toUpperCase(),
              color: trip.status == 'active'
                  ? AppColors.secondary
                  : AppColors.primaryLight,
            ),
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
                  Text(
                    (trip.totalStops > 0)
                        ? '${trip.currentStop ?? '--'} of ${trip.totalStops}'
                        : (trip.currentStop ?? '--'),
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          TapScale(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LiveMapScreen(tripId: trip.id),
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

  String get _pickupStatus => trip.pickupCompleted ? 'Completed' : 'Scheduled';
  String get _dropOffStatus {
    switch (trip.status) {
      case 'active':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: "Today's Schedule",
            subtitle: 'Pickup and drop-off progression',
          ),
          const SizedBox(height: 14),
          _ScheduleRow(label: 'Pick-up Time', time: trip.pickupTime ?? '--',
            status: _pickupStatus, statusColor: AppColors.secondary),
          const SizedBox(height: 10),
          _ScheduleRow(label: 'Drop-off Time', time: trip.dropOffTime ?? '--',
            status: _dropOffStatus, statusColor: AppColors.primaryLight),
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
    return DashboardCard(
      child: Column(
        children: [
          SectionHeader(
            title: 'Recent Notifications',
            subtitle: 'Latest alerts and updates',
            trailing: TapScale(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              )),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No notifications yet.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
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