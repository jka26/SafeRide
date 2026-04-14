import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/session_store.dart';
import '../models/bus_model.dart';
import '../theme/app_theme.dart';

class RouteMapScreen extends StatefulWidget {
  final String title;
  final Color color;
  final String tripId;
  final BusModel? bus;

  const RouteMapScreen({
    super.key,
    required this.title,
    required this.tripId,
    this.color = AppColors.secondary,
    this.bus,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  static const _pollInterval = Duration(seconds: 15);
  static const _schoolLocation = LatLng(5.5900, -0.1800);
  static const _fallbackCenter = LatLng(5.6030, -0.1875);

  final ApiClient _apiClient = ApiClient();
  Timer? _pollTimer;
  io.Socket? _socket;

  bool _isLoading = true;
  String? _error;
  String _tripStatus = 'idle';
  String? _currentStop;
  int? _etaMinutes;
  String? _driverName;
  String? _tripName;
  final List<LatLng> _trail = [];

  @override
  void initState() {
    super.initState();
    _connectToLiveUpdates();
    _refresh();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _connectToLiveUpdates() {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) {
      return;
    }
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final socketBaseUri = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
    );
    final socket = io.io(
      '${socketBaseUri.toString()}/tracking',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      socket.emit('subscribe', {'tripId': widget.tripId});
    });

    socket.on('location', (payload) {
      if (!mounted || payload is! Map<String, dynamic>) {
        return;
      }
      final eventTripId = (payload['tripId'] ?? '').toString();
      if (eventTripId != widget.tripId) {
        return;
      }
      final latitude = (payload['latitude'] as num?)?.toDouble();
      final longitude = (payload['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) {
        return;
      }
      setState(() {
        _pushTrailPoint(LatLng(latitude, longitude));
        _isLoading = false;
        _error = null;
      });
    });

    socket.connect();
    _socket = socket;
  }

  Future<void> _refresh() async {
    try {
      final response =
          await _apiClient.get('/driver/trips/${widget.tripId}/live')
              as Map<String, dynamic>;
      final trip = (response['trip'] ?? const <String, dynamic>{})
          as Map<String, dynamic>;
      final latestLocation =
          (response['latestLocation'] ?? const <String, dynamic>{})
              as Map<String, dynamic>;
      final recentLocations =
          (response['recentLocations'] as List<dynamic>? ?? const <dynamic>[])
              .cast<Map<String, dynamic>>();

      final nextTrail = <LatLng>[];
      for (final row in recentLocations) {
        final latitude = (row['latitude'] as num?)?.toDouble();
        final longitude = (row['longitude'] as num?)?.toDouble();
        if (latitude == null || longitude == null) continue;
        nextTrail.add(LatLng(latitude, longitude));
      }
      if (nextTrail.isEmpty && latestLocation.isNotEmpty) {
        final latitude = (latestLocation['latitude'] as num?)?.toDouble();
        final longitude = (latestLocation['longitude'] as num?)?.toDouble();
        if (latitude != null && longitude != null) {
          nextTrail.add(LatLng(latitude, longitude));
        }
      }

      setState(() {
        _tripName = (trip['name'] ?? widget.title).toString();
        _tripStatus = (trip['status'] ?? 'idle').toString().toUpperCase();
        _currentStop = (trip['currentStopName'] as String?)?.trim();
        _etaMinutes = (trip['etaMinutes'] as num?)?.toInt();
        _driverName = (trip['driverName'] as String?)?.trim();
        _trail
          ..clear()
          ..addAll(nextTrail);
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

  void _pushTrailPoint(LatLng point) {
    if (_trail.isNotEmpty) {
      final last = _trail.last;
      if (last.latitude == point.latitude && last.longitude == point.longitude) {
        return;
      }
    }
    _trail.add(point);
    if (_trail.length > 120) {
      _trail.removeAt(0);
    }
  }

  LatLng get _busLocation => _trail.isNotEmpty ? _trail.last : _fallbackCenter;

  @override
  Widget build(BuildContext context) {
    final hasTrail = _trail.isNotEmpty;
    final hasLiveLocation = hasTrail && _busLocation != _fallbackCenter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
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
                    initialCenter: _busLocation,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.saferide.app',
                    ),
                    if (_trail.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _trail,
                            color: widget.color,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    if (hasLiveLocation)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_busLocation, _schoolLocation],
                            color: AppColors.primary.withValues(alpha: 0.5),
                            strokeWidth: 2,
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
                                BoxShadow(color: Colors.black12, blurRadius: 5),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        if (hasLiveLocation)
                          Marker(
                            point: _busLocation,
                            width: 52,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.color.withValues(alpha: 0.5),
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
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_error == null ? widget.color : AppColors.error)
                          .withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error ??
                                '${_tripName ?? widget.title} • $_tripStatus'
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
                                color: widget.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Live Route Tracking',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_trail.length} point${_trail.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bus: ${widget.bus?.busNumber ?? '--'} • Route: ${widget.bus?.routeName ?? '--'}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_driverName != null && _driverName!.isNotEmpty)
                          Text(
                            'Driver: $_driverName',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
