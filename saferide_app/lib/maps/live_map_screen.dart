import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  static const _pollInterval = Duration(seconds: 15);
  static const _schoolLocation = LatLng(5.5900, -0.1800);
  static const _mapCenter = LatLng(5.6030, -0.1875);

  final ApiClient _apiClient = ApiClient();
  Timer? _pollTimer;

  bool _isLoading = true;
  String? _error;
  LatLng? _busLocation;
  String _tripName = 'Live Map';
  String _tripStatus = 'idle';
  String? _currentStop;
  int? _etaMinutes;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final response = await _apiClient.get('/parent/tracking/trips/${widget.tripId}')
          as Map<String, dynamic>;
      final trip = (response['trip'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
      final latestLocation =
          (response['latestLocation'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
      final hasLocation = latestLocation.isNotEmpty;

      setState(() {
        _tripName = (trip['name'] ?? 'Live Map').toString();
        _tripStatus = (trip['status'] ?? 'idle').toString().toUpperCase();
        _currentStop = (trip['currentStopName'] as String?)?.trim();
        _etaMinutes = (trip['etaMinutes'] as num?)?.toInt();
        _busLocation = hasLocation
            ? LatLng(
                (latestLocation['latitude'] as num?)?.toDouble() ?? _mapCenter.latitude,
                (latestLocation['longitude'] as num?)?.toDouble() ?? _mapCenter.longitude,
              )
            : null;
        _error = null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String get _statusLabel {
    switch (_tripStatus) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return _tripStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _busLocation ?? _mapCenter;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Live Tracking',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.saferide.app',
                    ),
                    if (_busLocation != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_busLocation!, _schoolLocation],
                            color: AppColors.primary,
                            strokeWidth: 3,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
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
                        if (_busLocation != null)
                          Marker(
                            point: _busLocation!,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_bus_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_error == null
                              ? AppColors.primary
                              : AppColors.error)
                          .withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error ??
                                '$_tripName • $_statusLabel'
                                    '${_etaMinutes == null ? '' : ' • ETA ${_etaMinutes} min'}'
                                    '${_currentStop == null || _currentStop!.isEmpty ? '' : ' • $_currentStop'}',
                            style: const TextStyle(
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

                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (_busLocation != null)
                          const _LegendItem(
                            color: AppColors.secondary,
                            icon: Icons.directions_bus_rounded,
                            label: 'Bus Location',
                          ),
                        if (_busLocation != null) const SizedBox(width: 20),
                        const _LegendItem(
                          color: AppColors.accent,
                          icon: Icons.school_rounded,
                          label: 'School',
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 6),
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
