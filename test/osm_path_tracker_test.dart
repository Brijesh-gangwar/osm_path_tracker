import 'package:flutter_test/flutter_test.dart';
import 'package:osm_path_tracker/osm_path_tracker.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('PathModel serializes and deserializes correctly', () {
    final original = PathModel(
      path: [
        const LatLng(10, 20),
        const LatLng(30, 40),
      ],
      distance: 12.34,
      timestamp: DateTime.now(),
    );

    final json = original.toJson();
    final fromJson = PathModel.fromJson(json);

    expect(fromJson.path.length, 2);
    expect(fromJson.distance, original.distance);
    expect(fromJson.timestamp.toIso8601String(),
        original.timestamp.toIso8601String());
  });
}
