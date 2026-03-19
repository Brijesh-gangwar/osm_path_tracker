import 'package:latlong2/latlong.dart';

/// Utility methods for calculating distances across a list of coordinates.
class DistanceUtils {
  /// Creates a distance utility instance.
  const DistanceUtils();

  /// Returns the total geodesic distance of [path] in kilometers.
  static double calculateDistance(List<LatLng> path) {
    const Distance distance = Distance();
    double total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      total += distance(path[i], path[i + 1]);
    }
    return total / 1000;
  }
}
