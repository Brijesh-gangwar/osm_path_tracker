// lib/live_tracking.dart

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
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
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
    _positionStream?.cancel();
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
        timeLimit: const Duration(seconds: 20),
      );
      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location: $e")),
      );
      Navigator.pop(context, null);
    }
  }

  void _startTracking() {
    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      final newLoc = LatLng(pos.latitude, pos.longitude);

      if (_trackedPath.isNotEmpty &&
          _trackedPath.last.latitude == newLoc.latitude &&
          _trackedPath.last.longitude == newLoc.longitude) {
        return;
      }

      setState(() {
        _trackedPath.add(newLoc);
        _currentLocation = newLoc;
      });

      _mapController.move(newLoc, _currentZoom);
    });
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

  // double _calculateDistance(List<LatLng> path) {
  //   const Distance distance = Distance();
  //   double totalDistance = 0;
  //   for (int i = 0; i < path.length - 1; i++) {
  //     totalDistance += distance(path[i], path[i + 1]);
  //   }
  //   return totalDistance / 1000; // km
  // }

// Inside your LiveTrackingScreen:
Future<void> _savePath() async {
  if (_trackedPath.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No path to save!")),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  await Future.delayed(const Duration(seconds: 1));

  if (mounted) {
    setState(() => _isSaving = false);

    final distance = DistanceUtils.calculateDistance(_trackedPath);
    final pathModel = PathModel(
      path: _trackedPath,
      distance: distance,
      timestamp: DateTime.now(),
    );

    Navigator.pop(context, pathModel);
  }
}

  @override
  Widget build(BuildContext context) {
    final LatLng mapCenter = _currentLocation ?? _defaultCenter;

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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: _currentZoom,
              maxZoom: 19.0,
              minZoom: 5.0,
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
                    point: mapCenter,
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
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

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
