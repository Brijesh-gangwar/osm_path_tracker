import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/path_model.dart';
import '../utils/distance_utils.dart';

/// A screen that records GPS updates and returns a saved [PathModel].
class LiveTrackingScreen extends StatefulWidget {
  /// Creates a live tracking screen that saves a raw path when the user taps save.
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final List<LatLng> _trackedPath = [];
  final List<LatLng> _customPoints = [];
  final MapController _mapController = MapController();
  StreamController<LatLng>? _locationController;

  LatLng? _lastLocation;
  StreamSubscription<Position>? _positionStream;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;

    _locationController?.close();
    _locationController = null;
  }

  void _startTracking() async {
    _stopTracking();

    _locationController = StreamController<LatLng>.broadcast();

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
      }
      return;
    }

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position pos) {
      final newLoc = LatLng(pos.latitude, pos.longitude);
      _lastLocation = newLoc;

      setState(() {
        _trackedPath.add(newLoc);
      });

      _locationController?.add(newLoc);
      _mapController.move(newLoc, _mapController.camera.zoom);
    });
  }

  void _addCustomMarker() {
    if (_lastLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Waiting for current location...")),
      );
      return;
    }

    final exists = _customPoints.any(
      (p) =>
          p.latitude == _lastLocation!.latitude &&
          p.longitude == _lastLocation!.longitude,
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marker already exists here!")),
      );
      return;
    }

    setState(() {
      _customPoints.add(_lastLocation!);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Custom marker added")));
  }

  Future<void> _savePath() async {
    if (_trackedPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No path to save!")));
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));

    final rawPathModel = PathModel(
      path: _trackedPath,
      distance: DistanceUtils.calculateDistance(_trackedPath),
      timestamp: DateTime.now(),
      customPoints: _customPoints,
    );

    _stopTracking();

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, rawPathModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
        actions: [
          IconButton(
            icon:
                _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
            onPressed: _isSaving ? null : _savePath,
          ),
        ],
      ),
      body:
          _locationController == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<LatLng>(
                stream: _locationController!.stream,
                builder: (context, snapshot) {
                  final center =
                      _lastLocation ??
                      (_trackedPath.isNotEmpty ? _trackedPath.last : null);

                  if (center == null) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Fetching location..."),
                        ],
                      ),
                    );
                  }

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: center, initialZoom: 15),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: "com.example.osm_path_tracker",
                      ),
                      if (_trackedPath.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _trackedPath,
                              strokeWidth: 4,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (_trackedPath.isNotEmpty)
                            Marker(
                              point: _trackedPath.first,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          if (_lastLocation != null)
                            Marker(
                              point: _lastLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.circle,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                          ..._customPoints.map(
                            (point) => Marker(
                              point: point,
                              width: 30,
                              height: 30,
                              child: const Icon(
                                Icons.push_pin,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomMarker,
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
