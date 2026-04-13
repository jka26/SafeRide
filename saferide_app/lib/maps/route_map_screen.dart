import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';
import '../theme/app_theme.dart';

/// Route Map screen used by drivers ("Full Route") and admins ("Tracking [bus]").
/// Shows the full route as a polyline with numbered stop markers.
/// Uses demo coordinates (Accra, Ghana) until real GPS is connected.
class RouteMapScreen extends StatelessWidget {
  final String title;
  final Color color;
  final BusModel? bus;

  const RouteMapScreen({
    super.key,
    required this.title,
    this.color = AppColors.secondary,
    this.bus,
  });

  static const _routeStops = [
    _Stop('North Legon', LatLng(5.6280, -0.2010)),
    _Stop('Madina Market', LatLng(5.6180, -0.1960)),
    _Stop('Adenta Junction', LatLng(5.6090, -0.1910)),
    _Stop('Dome', LatLng(5.6000, -0.1860)),
    _Stop('Achimota', LatLng(5.5940, -0.1820)),
    _Stop('School', LatLng(5.5900, -0.1800)),
  ];

  // Bus currently at stop index 1 (Madina Market) for demo
  static const _busLocation = LatLng(5.6180, -0.1960);
  static const _currentStopIndex = 1;

  @override
  Widget build(BuildContext context) {
    final routePoints = _routeStops.map((s) => s.point).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(5.6090, -0.1905),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.saferide.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: color,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Stop markers
                  ...List.generate(_routeStops.length, (i) {
                    final stop = _routeStops[i];
                    final isSchool = i == _routeStops.length - 1;

                    return Marker(
                      point: stop.point,
                      width: isSchool ? 44 : 36,
                      height: isSchool ? 44 : 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSchool ? AppColors.accent : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSchool ? AppColors.accent : color,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: isSchool
                            ? const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                      ),
                    );
                  }),

                  // Bus marker
                  Marker(
                    point: _busLocation,
                    width: 52,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
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
                      'Demo route — GPS not yet connected',
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

          // Stop list card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Route Stops',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_routeStops.length} stops',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_routeStops.length, (i) {
                        final isSchool = i == _routeStops.length - 1;
                        final isCurrent = i == _currentStopIndex;

                        Color chipColor;
                        if (isCurrent) {
                          chipColor = color;
                        } else if (isSchool) {
                          chipColor = AppColors.accent;
                        } else {
                          chipColor = AppColors.divider;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? color.withValues(alpha: 0.12)
                                  : isSchool
                                      ? AppColors.accent.withValues(alpha: 0.1)
                                      : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: chipColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrent) ...[
                                  Icon(
                                    Icons.directions_bus_rounded,
                                    size: 12,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _routeStops[i].name,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? color
                                        : isSchool
                                            ? AppColors.accent
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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

class _Stop {
  final String name;
  final LatLng point;
  const _Stop(this.name, this.point);
}
