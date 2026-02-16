import 'package:latlong2/latlong.dart';

class PathModel {
  final List<LatLng> path;
  final double distance; // in kilometers
  final DateTime timestamp;
  final List<LatLng> customPoints; // important user-defined points

  PathModel({
    required this.path,
    required this.distance,
    required this.timestamp,
    required this.customPoints,
  });

  Map<String, dynamic> toJson() => {
        'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'distance': distance,
        'timestamp': timestamp.toIso8601String(),
        'customPoints':
            customPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      };

  factory PathModel.fromJson(Map<String, dynamic> json) {
    return PathModel(
      path: (json['path'] as List)
          .map((e) => LatLng(e['lat'], e['lng']))
          .toList(),
      distance: (json['distance'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      customPoints: (json['customPoints'] as List)
          .map((e) => LatLng(e['lat'], e['lng']))
          .toList(),
    );
  }
}
