import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/path_model.dart';

class PathNavigationScreen extends StatefulWidget {
  final PathModel pathModel;

  const PathNavigationScreen({super.key, required this.pathModel});

  @override
  State<PathNavigationScreen> createState() => _PathNavigationScreenState();
}

class _PathNavigationScreenState extends State<PathNavigationScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _selectedCustomMarker;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToCurrentLocation();
      _startLocationUpdates();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Stop location updates
    super.dispose();
  }

  /// Move map to a given LatLng safely
 void _goToPoint(LatLng point) {

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _mapController.move(point, 16);
  });
}


  /// Get and update current location once
  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _currentLocation = currentLatLng);
      _goToPoint(currentLatLng);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  /// Listen to location updates continuously
  void _startLocationUpdates() {
    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream?.cancel(); // cancel any existing stream
    _positionStream =
        Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
      final newLoc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _currentLocation = newLoc);
      _goToPoint(newLoc);
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.pathModel.path;
    final customPoints = widget.pathModel.customPoints.toSet().toList(); // ensure unique

    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigate Path"),
        actions: [
          if (customPoints.isNotEmpty)
            DropdownButton<LatLng>(
              value: customPoints.contains(_selectedCustomMarker)
                  ? _selectedCustomMarker
                  : null,
              hint: const Text("Jump to marker"),
              underline: const SizedBox(),
              items: customPoints.map((p) {
                final idx = customPoints.indexOf(p) + 1;
                return DropdownMenuItem<LatLng>(
                  value: p,
                  child: Text("Custom $idx"),
                );
              }).toList(),
              onChanged: (LatLng? point) {
                if (point != null) {
                  setState(() => _selectedCustomMarker = point);
                  _goToPoint(point);
                }
              },
            ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: path.isNotEmpty ? path.first : LatLng(20.0, 77.0),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.osm_path_tracker",
          ),
          if (path.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: path,
                  strokeWidth: 4,
                  color: Colors.greenAccent,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              if (path.isNotEmpty)
                Marker(
                  point: path.first,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.flag, color: Colors.green, size: 30),
                ),
              if (path.length > 1)
                Marker(
                  point: path.last,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
                ),
              ...customPoints.map(
                (p) => Marker(
                  point: p,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.star, color: Colors.orange, size: 28),
                ),
              ),
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.circle, color: Colors.blue, size: 18),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
