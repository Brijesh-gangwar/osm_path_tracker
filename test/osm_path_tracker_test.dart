import 'package:flutter_test/flutter_test.dart';
import 'package:osm_path_tracker/osm_path_tracker.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('PathModel serializes and deserializes correctly', () {
    final fixedTime = DateTime.parse("2025-01-01T12:00:00Z");

    final original = PathModel(
      path: const [LatLng(10, 20), LatLng(30, 40)],
      distance: 12.34,
      timestamp: fixedTime,
      customPoints: const [LatLng(15, 25), LatLng(35, 45)],
    );

    final json = original.toJson();
    final fromJson = PathModel.fromJson(json);

    expect(fromJson.path.length, 2);
    expect(fromJson.path[0].latitude, 10);
    expect(fromJson.path[0].longitude, 20);
    expect(fromJson.customPoints.length, 2);
    expect(fromJson.customPoints[0].latitude, 15);
    expect(fromJson.customPoints[0].longitude, 25);
    expect(fromJson.distance, 12.34);
    expect(fromJson.timestamp, fixedTime);
  });

  test('EncodedPathModel serializes and deserializes correctly', () {
    final encodedPathModel = EncodedPathModel(
      pathModel: PathModel(
        path: const [LatLng(10, 20), LatLng(30, 40)],
        distance: 12.34,
        timestamp: DateTime.parse("2025-01-01T12:00:00Z"),
        customPoints: const [LatLng(15, 25)],
      ),
      encodedPath: 'encoded-polyline',
      polylinePrecision: 5,
      originalPointCount: 12,
      compressedPointCount: 4,
      compressedDistance: 10.25,
    );

    final json = encodedPathModel.toJson();
    final fromJson = EncodedPathModel.fromJson(json);

    expect(fromJson.encodedPath, 'encoded-polyline');
    expect(fromJson.polylinePrecision, 5);
    expect(fromJson.originalPointCount, 12);
    expect(fromJson.compressedPointCount, 4);
    expect(fromJson.compressedDistance, 10.25);
    expect(fromJson.pathModel.customPoints.length, 1);
    expect(fromJson.pathModel.path.length, 2);
  });

  test(
    'PathCompressionUtils compresses path model and resolves encoded path',
    () {
      final trackedPath = <LatLng>[
        const LatLng(28.6139000, 77.2090000),
        const LatLng(28.6139002, 77.2090001),
        const LatLng(28.6139004, 77.2090002),
        const LatLng(28.6145000, 77.2096000),
        const LatLng(28.6150000, 77.2101000),
      ];
      final customPoint = trackedPath[3];

      final encodedPathModel = PathCompressionUtils.compressPathModel(
        PathModel(
          path: trackedPath,
          distance: 0,
          timestamp: DateTime.parse("2025-01-01T12:00:00Z"),
          customPoints: [customPoint],
        ),
        minimumDistanceMeters: 20,
        simplificationToleranceMeters: 5,
        precision: 5,
      );

      expect(encodedPathModel.encodedPath, isNotEmpty);
      expect(encodedPathModel.originalPointCount, trackedPath.length);
      expect(
        encodedPathModel.compressedPointCount,
        lessThan(trackedPath.length),
      );
      expect(encodedPathModel.compressedDistance, greaterThan(0));
      expect(encodedPathModel.pathModel.path, contains(customPoint));

      final resolvedPath = PathCompressionUtils.resolvePath(encodedPathModel);
      expect(resolvedPath.length, encodedPathModel.compressedPointCount);
      expect(resolvedPath, isNot(contains(trackedPath[1])));
      expect(resolvedPath, contains(customPoint));
    },
  );

  test('PathCompressionUtils rejects invalid compression settings', () {
    expect(
      () => PathCompressionUtils.compressPath(
        const [LatLng(10, 20), LatLng(10.001, 20.001)],
        minimumDistanceMeters: -1,
        simplificationToleranceMeters: 5,
        precision: 5,
      ),
      throwsArgumentError,
    );
  });

  test('PathNavigationScreen accepts raw path model', () {
    final screen = PathNavigationScreen(
      pathModel: PathModel(
        path: const [LatLng(10, 20), LatLng(10.1, 20.1)],
        distance: 1,
        timestamp: DateTime.parse("2025-01-01T12:00:00Z"),
        customPoints: const [],
      ),
    );

    expect(screen.pathModel, isNotNull);
    expect(screen.encodedPathModel, isNull);
  });

  test(
    'PathNavigationScreen accepts encoded path model without raw parameter',
    () {
      final encodedPathModel = EncodedPathModel(
        pathModel: PathModel(
          path: const [LatLng(10, 20), LatLng(10.1, 20.1)],
          distance: 1,
          timestamp: DateTime.parse("2025-01-01T12:00:00Z"),
          customPoints: const [],
        ),
        encodedPath: '_p~iF~ps|U_ulLnnqC',
        polylinePrecision: 5,
        originalPointCount: 2,
        compressedPointCount: 2,
        compressedDistance: 1,
      );

      final screen = PathNavigationScreen(encodedPathModel: encodedPathModel);

      expect(screen.pathModel, isNull);
      expect(screen.encodedPathModel, isNotNull);
    },
  );
}
