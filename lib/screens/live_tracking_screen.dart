import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/path_model.dart';
import '../utils/distance_utils.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final List<LatLng> _trackedPath = [];
  final MapController _mapController = MapController();
  final StreamController<LatLng> _locationController = StreamController.broadcast();

  StreamSubscription<Position>? _positionStream;

  bool _isLoading = true;
  bool _isSaving = false;

  final double _currentZoom = 17.0;
  final LatLng _defaultCenter = const LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    debugPrint("🔴 Disposing LiveTrackingScreen: cancelling position stream.");
    _positionStream?.cancel();
    _locationController.close();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showError("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Permission denied.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError("Permission permanently denied.");
      return;
    }

    await _getCurrentLocation();
    _startTracking();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      if (!mounted) return;

      final LatLng initialLoc = LatLng(pos.latitude, pos.longitude);
      _locationController.add(initialLoc);

      setState(() {
        _trackedPath.add(initialLoc);
        _isLoading = false;
      });

      _mapController.move(initialLoc, _currentZoom);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location request timed out.")),
      );
      Navigator.pop(context, null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError("Failed to get location: $e");
      Navigator.pop(context, null);
    }
  }

  void _startTracking() {
    _positionStream?.cancel();

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      final LatLng newLoc = LatLng(pos.latitude, pos.longitude);

      if (pos.accuracy > 20) {
        debugPrint("🚫 Ignored point: poor accuracy ${pos.accuracy}m");
        return;
      }

      if (_trackedPath.isEmpty || _hasMovedSignificantly(_trackedPath.last, newLoc, minDistanceMeters: 2)) {
        _trackedPath.add(newLoc);
        _locationController.add(newLoc);
        _mapController.move(newLoc, _currentZoom);

        debugPrint("✅ Added point: ${newLoc.latitude}, ${newLoc.longitude}");
      } else {
        debugPrint("🟡 Ignored: move < 2m (jitter)");
      }
    });

    debugPrint("✅ Started new position stream.");
  }

  bool _hasMovedSignificantly(LatLng last, LatLng current, {double minDistanceMeters = 2}) {
    final Distance distance = const Distance();
    final meters = distance.as(LengthUnit.Meter, last, current);
    debugPrint("📏 Distance to last: ${meters.toStringAsFixed(2)} meters");
    return meters >= minDistanceMeters;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _savePath() async {
    if (_trackedPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No path to save!")),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));

    final distance = DistanceUtils.calculateDistance(_trackedPath);
    final pathModel = PathModel(
      path: _trackedPath,
      distance: distance,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, pathModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _savePath,
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<LatLng>(
            stream: _locationController.stream,
            builder: (context, snapshot) {
              final LatLng center = snapshot.data ?? _defaultCenter;

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _currentZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  if (_trackedPath.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _trackedPath,
                          strokeWidth: 6,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_isSaving)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
