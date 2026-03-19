import 'package:latlong2/latlong.dart';

/// A saved raw route captured from live tracking.
class PathModel {
  /// Ordered coordinates that make up the tracked path.
  final List<LatLng> path;

  /// Total path distance in kilometers.
  final double distance;

  /// Time at which this path model was saved.
  final DateTime timestamp;

  /// Important user-defined points such as checkpoints or favorites.
  final List<LatLng> customPoints;

  /// Creates a raw path model for storage or later navigation.
  PathModel({
    required this.path,
    required this.distance,
    required this.timestamp,
    required this.customPoints,
  });

  /// Serializes this model into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    'distance': distance,
    'timestamp': timestamp.toIso8601String(),
    'customPoints':
        customPoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
  };

  /// Creates a [PathModel] from previously serialized JSON data.
  factory PathModel.fromJson(Map<String, dynamic> json) {
    return PathModel(
      path:
          (json['path'] as List)
              .map((e) => LatLng(e['lat'], e['lng']))
              .toList(),
      distance: (json['distance'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      customPoints:
          (json['customPoints'] as List)
              .map((e) => LatLng(e['lat'], e['lng']))
              .toList(),
    );
  }
}
