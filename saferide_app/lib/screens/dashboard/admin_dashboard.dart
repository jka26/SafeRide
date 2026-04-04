import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/bus_model.dart';
import '../../admin/bus_students_screen.dart';
import '../../admin/csv_upload_screen.dart';
import '../../shared/placeholder_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6D28D9),
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload Students',
          style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
            fontWeight: FontWeight.w600, color: Colors.white)),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const CsvUploadScreen(),
        )),
      ),
      body: Column(
        children: [
          _AdminAppBar(tabController: _tabController),
          _StatsRow(dashboard: dashboard),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FleetOverview(buses: dashboard.buses),
                const _RecentEvents(),
                const _Reports(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAppBar extends StatelessWidget {
  final TabController tabController;
  const _AdminAppBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 0,
      ),
      decoration: const BoxDecoration(color: Color(0xFF6D28D9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 16,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Central Monitoring System',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.white60)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('Live', style: TextStyle(fontFamily: 'Outfit',
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Fleet Overview'),
              Tab(text: 'Recent Events'),
              Tab(text: 'Reports'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DashboardProvider dashboard;
  const _StatsRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatCard(icon: Icons.directions_bus_rounded,
              value: '${dashboard.activeBuses}/${dashboard.buses.length}',
              label: 'Active Buses', color: const Color(0xFF6D28D9)),
            _StatCard(icon: Icons.people_rounded,
              value: '${dashboard.totalStudentsOnBoard}',
              label: 'Students On Board', color: const Color(0xFF6D28D9)),
            _StatCard(icon: Icons.check_circle_rounded,
              value: '${dashboard.completedTrips}',
              label: 'Completed', color: AppColors.secondary),
            _StatCard(icon: Icons.warning_rounded,
              value: '${dashboard.activeAlerts}',
              label: 'Active Alerts', color: AppColors.accent),
            _StatCard(icon: Icons.location_on_rounded,
              value: '${dashboard.activeRoutes}',
              label: 'Active Routes', color: AppColors.primaryLight),
            _StatCard(icon: Icons.trending_up_rounded,
              value: '${dashboard.onTimeRate.toStringAsFixed(0)}%',
              label: 'On-Time Rate', color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatCard({required this.icon, required this.value,
    required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'Outfit', fontSize: 16,
          fontWeight: FontWeight.w800, color: color)),
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 10,
            color: AppColors.textSecondary, height: 1.3)),
      ]),
    );
  }
}

class _FleetOverview extends StatelessWidget {
  final List<BusModel> buses;
  const _FleetOverview({required this.buses});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Fleet Status',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PlaceholderScreen(
                    title: 'Fleet Map',
                    subtitle: 'All active buses will appear on the live map here.',
                    icon: Icons.map_rounded,
                    color: Color(0xFF6D28D9),
                  ),
                )),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.map_outlined, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text('View All on Map',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                        color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...buses.map((bus) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BusCard(bus: bus),
          )),
        ],
      ),
    );
  }
}

class _BusCard extends StatelessWidget {
  final BusModel bus;
  const _BusCard({required this.bus});

  Color get _statusColor {
    switch (bus.status) {
      case 'active': return AppColors.secondary;
      case 'delayed': return AppColors.accent;
      case 'completed': return AppColors.primaryLight;
      default: return AppColors.textHint;
    }
  }

  Color get _cardBg {
    switch (bus.status) {
      case 'active': return AppColors.secondary.withOpacity(0.04);
      case 'delayed': return AppColors.accent.withOpacity(0.05);
      case 'completed': return AppColors.primaryLight.withOpacity(0.04);
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.read<DashboardProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_bus_rounded, color: _statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bus.busNumber,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(bus.routeName,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                      color: AppColors.textSecondary)),
                ]),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  bus.status[0].toUpperCase() + bus.status.substring(1),
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Driver: ${bus.driverName}',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                  color: AppColors.textSecondary)),
              Text('${bus.studentsOnBoard} students',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Route Progress',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                  color: AppColors.textSecondary)),
              Text('${(bus.routeProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                  fontWeight: FontWeight.w600, color: _statusColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: bus.routeProgress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlaceholderScreen(
                  title: 'Tracking ${bus.busNumber}',
                  subtitle: 'Live GPS location for ${bus.busNumber} on ${bus.routeName} will appear here.',
                  icon: Icons.location_on_rounded,
                  color: _statusColor,
                ),
              )),
              child: _BusActionButton(
                icon: Icons.location_on_rounded,
                label: 'Track',
                color: _statusColor,
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BusStudentsScreen(
                  bus: bus,
                  students: dashboard.students,
                ),
              )),
              child: _BusActionButton(
                icon: Icons.people_rounded,
                label: 'Students',
                color: _statusColor,
              ),
            )),
          ]),
        ],
      ),
    );
  }
}

class _BusActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _BusActionButton({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
    );
  }
}

class _RecentEvents extends StatelessWidget {
  const _RecentEvents();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Recent Events — Coming Soon',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary)),
    );
  }
}

class _Reports extends StatelessWidget {
  const _Reports();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Reports — Coming Soon',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary)),
    );
  }
}