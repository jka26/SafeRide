import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';
import '../theme/app_theme.dart';

/// Fleet Map screen shown to admins.
/// Displays all active buses as markers on an OSM map.
/// Uses demo coordinates until real GPS is connected.
class FleetMapScreen extends StatefulWidget {
  final List<BusModel> buses;
  const FleetMapScreen({super.key, required this.buses});

  @override
  State<FleetMapScreen> createState() => _FleetMapScreenState();
}

class _FleetMapScreenState extends State<FleetMapScreen> {
  static const _mapCenter = LatLng(5.6030, -0.1875);
  static const _schoolLocation = LatLng(5.5900, -0.1800);

  // Demo positions distributed around Accra, Ghana
  static const _demoPositions = [
    LatLng(5.6280, -0.2010),
    LatLng(5.6180, -0.1750),
    LatLng(5.5950, -0.2100),
    LatLng(5.6350, -0.1680),
    LatLng(5.5800, -0.1950),
    LatLng(5.6100, -0.2150),
  ];

  BusModel? _selectedBus;
  int? _selectedIndex;

  Color _busColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.secondary;
      case 'delayed':
        return AppColors.accent;
      case 'completed':
        return AppColors.primaryLight;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buses = widget.buses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6D28D9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Fleet Map',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${buses.length} bus${buses.length == 1 ? '' : 'es'}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 12.5,
              onTap: null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.saferide.app',
              ),
              MarkerLayer(
                markers: [
                  // School marker
                  Marker(
                    point: _schoolLocation,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  // Bus markers
                  ...List.generate(buses.length, (i) {
                    final pos = _demoPositions[i % _demoPositions.length];
                    final bus = buses[i];
                    final isSelected = _selectedIndex == i;
                    final busColor = _busColor(bus.status);

                    return Marker(
                      point: pos,
                      width: isSelected ? 54 : 44,
                      height: isSelected ? 54 : 44,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (_selectedIndex == i) {
                            _selectedBus = null;
                            _selectedIndex = null;
                          } else {
                            _selectedBus = bus;
                            _selectedIndex = i;
                          }
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: busColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: busColor.withValues(alpha: 0.4),
                                blurRadius: isSelected ? 12 : 4,
                                spreadRadius: isSelected ? 3 : 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Demo data banner
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo data — GPS tracking not yet connected',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom card: selected bus info OR legend
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _selectedBus != null
                ? GestureDetector(
                    onTap: () =>
                        setState(() {
                          _selectedBus = null;
                          _selectedIndex = null;
                        }),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _busColor(_selectedBus!.status),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedBus!.busNumber,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_selectedBus!.routeName} · ${_selectedBus!.driverName}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _busColor(_selectedBus!.status)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedBus!.status,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _busColor(_selectedBus!.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const _LegendDot(
                            color: AppColors.secondary, label: 'Active'),
                        const SizedBox(width: 14),
                        const _LegendDot(
                            color: AppColors.accent, label: 'Delayed'),
                        const SizedBox(width: 14),
                        const _LegendDot(
                            color: AppColors.textHint, label: 'Idle'),
                        const Spacer(),
                        const Text(
                          'Tap a bus for details',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
