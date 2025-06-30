// lib/models/path_model.dart

import 'package:latlong2/latlong.dart';

class PathModel {
  final List<LatLng> path;
  final double distance; // in kilometers
  final DateTime timestamp;

  PathModel({
    required this.path,
    required this.distance,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'distance': distance,
        'timestamp': timestamp.toIso8601String(),
      };

  static PathModel fromJson(Map<String, dynamic> json) {
    final path = (json['path'] as List)
        .map((e) => LatLng(e['lat'], e['lng']))
        .toList();

    return PathModel(
      path: path,
      distance: json['distance']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
