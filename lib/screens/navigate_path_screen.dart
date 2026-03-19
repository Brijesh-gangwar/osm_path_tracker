import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/encoded_path_model.dart';
import '../models/path_model.dart';
import '../utils/path_compression_utils.dart';

/// A screen that visualizes either a raw [PathModel] or an [EncodedPathModel].
class PathNavigationScreen extends StatefulWidget {
  /// The raw path to render when your app is not using encoded routes.
  final PathModel? pathModel;

  /// The encoded path to render when your app stores compressed route data.
  final EncodedPathModel? encodedPathModel;

  /// Creates a navigation screen for either [pathModel] or [encodedPathModel].
  ///
  /// Exactly one of the two inputs must be provided.
  const PathNavigationScreen({super.key, this.pathModel, this.encodedPathModel})
    : assert(
        (pathModel != null) != (encodedPathModel != null),
        'Provide exactly one of pathModel or encodedPathModel.',
      );

  /// Returns the underlying raw model regardless of which constructor input was used.
  PathModel get resolvedPathModel => encodedPathModel?.pathModel ?? pathModel!;

  @override
  State<PathNavigationScreen> createState() => _PathNavigationScreenState();
}

class _PathNavigationScreenState extends State<PathNavigationScreen> {
  final MapController _mapController = MapController();
  late final List<LatLng> _navigationPath;
  LatLng? _currentLocation;
  LatLng? _selectedCustomMarker;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _navigationPath =
        widget.encodedPathModel == null
            ? List<LatLng>.from(widget.pathModel!.path)
            : PathCompressionUtils.resolvePath(widget.encodedPathModel!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToCurrentLocation();
      _startLocationUpdates();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _goToPoint(LatLng point) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(point, 16);
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }
      setState(() => _currentLocation = currentLatLng);
      _goToPoint(currentLatLng);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error getting location: $e")));
    }
  }

  void _startLocationUpdates() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((pos) {
      final newLoc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) {
        return;
      }
      setState(() => _currentLocation = newLoc);
      _goToPoint(newLoc);
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = _navigationPath;
    final customPoints = widget.resolvedPathModel.customPoints.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigate Path"),
        actions: [
          if (customPoints.isNotEmpty)
            DropdownButton<LatLng>(
              value:
                  customPoints.contains(_selectedCustomMarker)
                      ? _selectedCustomMarker
                      : null,
              hint: const Text("Jump to marker"),
              underline: const SizedBox(),
              items:
                  customPoints.map((p) {
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
          initialCenter:
              path.isNotEmpty ? path.first : const LatLng(20.0, 77.0),
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
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 30,
                  ),
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
