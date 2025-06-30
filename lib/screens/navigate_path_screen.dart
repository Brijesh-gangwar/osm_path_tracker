// lib/navigate_path.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PathNavigationScreen extends StatelessWidget {
  final List<LatLng> path;

  const PathNavigationScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No path provided.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Navigate Path")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: path.first,
          initialZoom: 15,
          maxZoom: 18,
          minZoom: 5,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: path,
                strokeWidth: 8,
                color: Colors.red,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: path.first,
                width: 40,
                height: 40,
                child: const Icon(Icons.flag, color: Colors.green, size: 40),
              ),
              Marker(
                point: path.last,
                width: 40,
                height: 40,
                child: const Icon(Icons.check_circle, color: Colors.blue, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
