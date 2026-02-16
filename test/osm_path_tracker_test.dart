import 'package:flutter_test/flutter_test.dart';
import 'package:osm_path_tracker/osm_path_tracker.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('PathModel serializes and deserializes correctly with custom points', () {
    final fixedTime = DateTime.parse("2025-01-01T12:00:00Z");

    final original = PathModel(
      path: const [
        LatLng(10, 20),
        LatLng(30, 40),
      ],
      distance: 12.34,
      timestamp: fixedTime,
      customPoints: const [
        LatLng(15, 25),
        LatLng(35, 45),
      ],
    );

    final json = original.toJson();
    final fromJson = PathModel.fromJson(json);

    // Path checks
    expect(fromJson.path.length, 2);
    expect(fromJson.path[0].latitude, 10);
    expect(fromJson.path[0].longitude, 20);

    // Custom points checks
    expect(fromJson.customPoints.length, 2);
    expect(fromJson.customPoints[0].latitude, 15);
    expect(fromJson.customPoints[0].longitude, 25);

    // Other fields
    expect(fromJson.distance, 12.34);
    expect(fromJson.timestamp, fixedTime);
  });
}
