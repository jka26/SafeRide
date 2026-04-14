import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/bus_model.dart';
import '../../admin/bus_students_screen.dart';
import '../../admin/csv_upload_screen.dart';
import '../../maps/fleet_map_screen.dart';
import '../../maps/route_map_screen.dart';
import '../../ui/app_motion.dart';
import '../../services/admin_ops_service.dart';
import '../../widgets/logout_button.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminOpsService _adminOpsService = AdminOpsService();

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
          _AdminAppBar(
            tabController: _tabController,
            onCreateBus: _showCreateBusDialog,
            onAssignBusToDriver: _showAssignBusToDriverDialog,
          ),
          _StatsRow(dashboard: dashboard),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FadeSlideIn(child: _FleetOverview(buses: dashboard.buses)),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _RecentEvents(
                    buses: dashboard.buses,
                    activeAlerts: dashboard.activeAlerts,
                    completedTrips: dashboard.completedTrips,
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: _Reports(
                    activeRoutes: dashboard.activeRoutes,
                    onTimeRate: dashboard.onTimeRate,
                    totalStudentsOnBoard: dashboard.totalStudentsOnBoard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateBusDialog() async {
    final plateCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '40');
    try {
      final created = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Bus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: plateCtrl,
                decoration: const InputDecoration(labelText: 'Plate number'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: routeCtrl,
                decoration: const InputDecoration(labelText: 'Route name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (created != true) return;

      final plate = plateCtrl.text.trim();
      final route = routeCtrl.text.trim();
      final capacity = int.tryParse(capacityCtrl.text.trim()) ?? 40;
      if (plate.isEmpty || route.isEmpty) {
        throw Exception('Plate number and route name are required.');
      }

      await _adminOpsService.createBus(
        plateNumber: plate,
        routeName: route,
        capacity: capacity,
      );
      if (!mounted) return;
      await context.read<DashboardProvider>().loadDashboard('admin');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      plateCtrl.dispose();
      routeCtrl.dispose();
      capacityCtrl.dispose();
    }
  }

  Future<void> _showAssignBusToDriverDialog() async {
    try {
      final drivers = await _adminOpsService.listDrivers();
      final buses = await _adminOpsService.listBuses();
      if (!mounted) return;
      if (drivers.isEmpty || buses.isEmpty) {
        throw Exception('Need at least one driver and one bus to assign.');
      }

      String selectedDriverId = drivers.first.id;
      String selectedBusId = buses.first.id;
      final tripNameCtrl = TextEditingController(text: 'Morning Route');
      DateTime selectedDate = DateTime.now();

      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Assign Bus to Driver'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDriverId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Driver'),
                  items: drivers
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setStateDialog(() => selectedDriverId = value);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedBusId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Bus'),
                  items: buses
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('${b.plateNumber} • ${b.routeName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setStateDialog(() => selectedBusId = value);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tripNameCtrl,
                  decoration: const InputDecoration(labelText: 'Trip name'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${selectedDate.toLocal().toString().split(' ').first}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked == null) return;
                        setStateDialog(() => selectedDate = picked);
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Assign'),
              ),
            ],
          ),
        ),
      );

      if (shouldCreate != true) {
        tripNameCtrl.dispose();
        return;
      }

      final tripName = tripNameCtrl.text.trim();
      tripNameCtrl.dispose();
      if (tripName.isEmpty) {
        throw Exception('Trip name is required.');
      }

      await _adminOpsService.createTripAssignment(
        name: tripName,
        busId: selectedBusId,
        driverId: selectedDriverId,
        tripDate: selectedDate,
      );

      if (!mounted) return;
      await context.read<DashboardProvider>().loadDashboard('admin');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus assigned to driver successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _AdminAppBar extends StatelessWidget {
  final TabController tabController;
  final Future<void> Function() onCreateBus;
  final Future<void> Function() onAssignBusToDriver;
  const _AdminAppBar({
    required this.tabController,
    required this.onCreateBus,
    required this.onAssignBusToDriver,
  });

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
                  color: Colors.white.withValues(alpha:0.15),
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
              const SizedBox(width: 8),
              const LogoutButton(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  onCreateBus();
                },
                icon: const Icon(Icons.add_road_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Create Bus',
                  style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  onAssignBusToDriver();
                },
                icon: const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Assign Driver',
                  style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
                ),
              ),
            ],
          ),
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
              TapScale(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FleetMapScreen(buses: buses),
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
      case 'active': return AppColors.secondary.withValues(alpha:0.04);
      case 'delayed': return AppColors.accent.withValues(alpha:0.05);
      case 'completed': return AppColors.primaryLight.withValues(alpha:0.04);
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
        border: Border.all(color: _statusColor.withValues(alpha:0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 6)],
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
                    color: _statusColor.withValues(alpha:0.12),
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
            Expanded(
              child: TapScale(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RouteMapScreen(
                    title: 'Tracking ${bus.busNumber}',
                    color: _statusColor,
                    tripId: bus.tripId,
                    bus: bus,
                  ),
                )),
                child: _BusActionButton(
                  icon: Icons.location_on_rounded,
                  label: 'Track',
                  color: _statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TapScale(
                onTap: () async {
                  try {
                    final students =
                        await context.read<DashboardProvider>().getBusStudents(bus.id);
                    if (!context.mounted) return;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => BusStudentsScreen(
                        bus: bus,
                        students: students,
                      ),
                    ));
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                child: _BusActionButton(
                  icon: Icons.people_rounded,
                  label: 'Students',
                  color: _statusColor,
                ),
              ),
            ),
          ]),
          if (bus.tripId.isNotEmpty && bus.status == 'idle') ...[
            const SizedBox(height: 8),
            TapScale(
              onTap: () async {
                try {
                  await AdminOpsService().startTrip(bus.tripId);
                  if (!context.mounted) return;
                  await context.read<DashboardProvider>().loadDashboard('admin');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Started trip for ${bus.busNumber}.')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: _BusActionButton(
                icon: Icons.play_arrow_rounded,
                label: 'Start Trip',
                color: AppColors.primaryLight,
              ),
            ),
          ],
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
    );
  }
}

class _RecentEvents extends StatelessWidget {
  const _RecentEvents({
    required this.buses,
    required this.activeAlerts,
    required this.completedTrips,
  });

  final List<BusModel> buses;
  final int activeAlerts;
  final int completedTrips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _EventTile(
            title: 'Trips Completed Today',
            value: '$completedTrips',
            icon: Icons.check_circle_rounded,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _EventTile(
            title: 'Active Alerts',
            value: '$activeAlerts',
            icon: Icons.warning_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          _EventTile(
            title: 'Buses Reporting',
            value: '${buses.length}',
            icon: Icons.directions_bus_rounded,
            color: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _Reports extends StatelessWidget {
  const _Reports({
    required this.activeRoutes,
    required this.onTimeRate,
    required this.totalStudentsOnBoard,
  });

  final int activeRoutes;
  final double onTimeRate;
  final int totalStudentsOnBoard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _EventTile(
            title: 'Active Routes',
            value: '$activeRoutes',
            icon: Icons.alt_route_rounded,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 12),
          _EventTile(
            title: 'On-Time Performance',
            value: '${onTimeRate.toStringAsFixed(1)}%',
            icon: Icons.trending_up_rounded,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _EventTile(
            title: 'Students On Board',
            value: '$totalStudentsOnBoard',
            icon: Icons.groups_rounded,
            color: AppColors.accentDark,
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}