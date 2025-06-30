// lib/utils/distance_utils.dart

import 'package:latlong2/latlong.dart';

class DistanceUtils {
  static double calculateDistance(List<LatLng> path) {
    const Distance distance = Distance();
    double total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      total += distance(path[i], path[i + 1]);
    }
    return total / 1000; // meters to km
  }
}
