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

class FleetMapScreen extends StatefulWidget {
  final List<BusModel> buses;
  const FleetMapScreen({super.key, required this.buses});

  @override
  State<FleetMapScreen> createState() => _FleetMapScreenState();
}

class _FleetMapScreenState extends State<FleetMapScreen> {
  static const _mapCenter = LatLng(5.6030, -0.1875);
  static const _schoolLocation = LatLng(5.5900, -0.1800);
  static const _pollInterval = Duration(seconds: 20);

  final ApiClient _apiClient = ApiClient();
  final Map<String, LatLng> _livePositions = {};
  Timer? _pollTimer;
  io.Socket? _socket;

  List<BusModel> _buses = const [];
  BusModel? _selectedBus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buses = widget.buses;
    for (final bus in _buses) {
      if (bus.latitude != null && bus.longitude != null) {
        _livePositions[bus.tripId] = LatLng(bus.latitude!, bus.longitude!);
      }
    }
    _connectToLiveUpdates();
    _refreshFleet();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshFleet());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

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
      for (final bus in _buses) {
        if (bus.tripId.isNotEmpty) {
          socket.emit('subscribe', {'tripId': bus.tripId});
        }
      }
    });

    socket.on('location', (payload) {
      if (!mounted || payload is! Map<String, dynamic>) return;
      final tripId = (payload['tripId'] ?? '').toString();
      final latitude = (payload['latitude'] as num?)?.toDouble();
      final longitude = (payload['longitude'] as num?)?.toDouble();
      if (tripId.isEmpty || latitude == null || longitude == null) return;
      setState(() {
        _livePositions[tripId] = LatLng(latitude, longitude);
      });
    });

    socket.connect();
    _socket = socket;
  }

  Future<void> _refreshFleet() async {
    try {
      final response = await _apiClient.get('/dashboard/admin') as Map<String, dynamic>;
      final todaysTrips = (response['todaysTrips'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      final inProgressTrips =
          (response['inProgressTrips'] as List<dynamic>? ?? const <dynamic>[])
              .cast<Map<String, dynamic>>();

      final locationByTrip = <String, Map<String, dynamic>>{};
      for (final trip in inProgressTrips) {
        final tripId = (trip['id'] ?? '').toString();
        if (tripId.isEmpty) continue;
        final latest =
            ((trip['locations'] as List<dynamic>?) ?? const <dynamic>[])
                .cast<Map<String, dynamic>>();
        final latestPoint = latest.isNotEmpty ? latest.first : null;
        locationByTrip[tripId] = {
          'latitude': (latestPoint?['latitude'] as num?)?.toDouble(),
          'longitude': (latestPoint?['longitude'] as num?)?.toDouble(),
          'currentStopName': (trip['currentStopName'] as String?)?.trim(),
          'etaMinutes': (trip['etaMinutes'] as num?)?.toInt(),
        };
      }

      final buses = todaysTrips.map((trip) {
        final tripId = (trip['id'] ?? '').toString();
        final loc = locationByTrip[tripId] ?? const <String, dynamic>{};
        return BusModel.fromAdminTrip(
          trip,
          latitude: loc['latitude'] as double?,
          longitude: loc['longitude'] as double?,
          currentStopName: loc['currentStopName'] as String?,
          etaMinutes: loc['etaMinutes'] as int?,
        );
      }).toList();

      setState(() {
        _buses = buses;
        for (final bus in buses) {
          if (bus.latitude != null && bus.longitude != null) {
            _livePositions[bus.tripId] = LatLng(bus.latitude!, bus.longitude!);
          }
        }
        if (_selectedBus != null) {
          BusModel? nextSelected;
          for (final bus in buses) {
            if (bus.tripId == _selectedBus!.tripId) {
              nextSelected = bus;
              break;
            }
          }
          _selectedBus = nextSelected;
        }
        _isLoading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mappedBuses = _buses.where((bus) => _livePositions.containsKey(bus.tripId)).toList();
    final mapCenter = mappedBuses.isNotEmpty
        ? _livePositions[mappedBuses.first.tripId]!
        : _mapCenter;

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
                  '${mappedBuses.length}/${_buses.length} live',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 12.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.saferide.app',
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
                        ...mappedBuses.map((bus) {
                          final pos = _livePositions[bus.tripId]!;
                          final isSelected = _selectedBus?.tripId == bus.tripId;
                          final busColor = _busColor(bus.status);
                          return Marker(
                            point: pos,
                            width: isSelected ? 54 : 44,
                            height: isSelected ? 54 : 44,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (_selectedBus?.tripId == bus.tripId) {
                                  _selectedBus = null;
                                } else {
                                  _selectedBus = bus;
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
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_error == null ? AppColors.primary : AppColors.error)
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
                                (mappedBuses.isEmpty
                                    ? 'No active buses reporting live GPS yet'
                                    : 'Live fleet GPS updates connected'),
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
                  child: _selectedBus != null
                      ? GestureDetector(
                          onTap: () => setState(() => _selectedBus = null),
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
                                      if (_selectedBus!.currentStopName != null &&
                                          _selectedBus!
                                              .currentStopName!.isNotEmpty)
                                        Text(
                                          'Current stop: ${_selectedBus!.currentStopName!}'
                                          '${_selectedBus!.etaMinutes == null ? '' : ' • ETA ${_selectedBus!.etaMinutes} min'}',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 11,
                                            color: AppColors.textHint,
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
                                'Tap a live bus for details',
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
