import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/encoded_path_model.dart';
import '../models/path_model.dart';
import 'distance_utils.dart';

/// The intermediate and final outputs of a path compression run.
class PathCompressionResult {
  /// Path after applying minimum-distance filtering.
  final List<LatLng> filteredPath;

  /// Path after Douglas-Peucker simplification.
  final List<LatLng> simplifiedPath;

  /// Final coordinate list after precision reduction.
  final List<LatLng> compressedPath;

  /// Encoded polyline representation of [compressedPath].
  final String encodedPath;

  /// Creates a result container for path compression stages.
  const PathCompressionResult({
    required this.filteredPath,
    required this.simplifiedPath,
    required this.compressedPath,
    required this.encodedPath,
  });
}

/// Utility methods for optional path compression and polyline conversion.
class PathCompressionUtils {
  /// Creates a path compression utility instance.
  const PathCompressionUtils();

  static const Distance _distance = Distance();
  static const double _earthRadiusMeters = 6371000;

  /// Filters, simplifies, rounds, and encodes a raw list of path coordinates.
  static PathCompressionResult compressPath(
    List<LatLng> path, {
    required double minimumDistanceMeters,
    required double simplificationToleranceMeters,
    required int precision,
    List<LatLng> preservePoints = const [],
  }) {
    _validateCompressionSettings(
      minimumDistanceMeters: minimumDistanceMeters,
      simplificationToleranceMeters: simplificationToleranceMeters,
      precision: precision,
    );

    if (path.isEmpty) {
      return const PathCompressionResult(
        filteredPath: [],
        simplifiedPath: [],
        compressedPath: [],
        encodedPath: '',
      );
    }

    final filteredPath = _filterByDistance(
      path,
      minimumDistanceMeters: minimumDistanceMeters,
      preservePoints: preservePoints,
    );
    final simplifiedPath = _simplifyWithDouglasPeucker(
      filteredPath,
      toleranceMeters: simplificationToleranceMeters,
      preservePoints: preservePoints,
    );
    final compressedPath = _reducePrecision(
      simplifiedPath,
      precision: precision,
    );

    return PathCompressionResult(
      filteredPath: filteredPath,
      simplifiedPath: simplifiedPath,
      compressedPath: compressedPath,
      encodedPath: encodePolyline(compressedPath, precision: precision),
    );
  }

  /// Compresses a saved [PathModel] and returns an [EncodedPathModel].
  static EncodedPathModel compressPathModel(
    PathModel pathModel, {
    required double minimumDistanceMeters,
    required double simplificationToleranceMeters,
    required int precision,
  }) {
    final result = compressPath(
      pathModel.path,
      minimumDistanceMeters: minimumDistanceMeters,
      simplificationToleranceMeters: simplificationToleranceMeters,
      precision: precision,
      preservePoints: pathModel.customPoints,
    );

    return EncodedPathModel(
      pathModel: pathModel,
      encodedPath: result.encodedPath,
      polylinePrecision: precision,
      originalPointCount: pathModel.path.length,
      compressedPointCount: result.compressedPath.length,
      compressedDistance: DistanceUtils.calculateDistance(result.filteredPath),
    );
  }

  static void _validateCompressionSettings({
    required double minimumDistanceMeters,
    required double simplificationToleranceMeters,
    required int precision,
  }) {
    if (minimumDistanceMeters < 0) {
      throw ArgumentError.value(
        minimumDistanceMeters,
        'minimumDistanceMeters',
        'must be greater than or equal to 0',
      );
    }

    if (simplificationToleranceMeters < 0) {
      throw ArgumentError.value(
        simplificationToleranceMeters,
        'simplificationToleranceMeters',
        'must be greater than or equal to 0',
      );
    }

    if (precision < 0) {
      throw ArgumentError.value(
        precision,
        'precision',
        'must be greater than or equal to 0',
      );
    }
  }

  /// Decodes the route inside [encodedPathModel] back into a coordinate list.
  static List<LatLng> resolvePath(EncodedPathModel encodedPathModel) {
    if (encodedPathModel.encodedPath.isEmpty) {
      return List<LatLng>.from(encodedPathModel.pathModel.path);
    }

    final decoded = decodePolyline(
      encodedPathModel.encodedPath,
      precision: encodedPathModel.polylinePrecision,
    );

    return decoded.isEmpty
        ? List<LatLng>.from(encodedPathModel.pathModel.path)
        : decoded;
  }

  /// Encodes [path] into a Google-style polyline string.
  static String encodePolyline(List<LatLng> path, {int precision = 5}) {
    if (path.isEmpty) {
      return '';
    }

    final factor = math.pow(10, precision).toDouble();
    final buffer = StringBuffer();
    var lastLat = 0;
    var lastLng = 0;

    for (final point in path) {
      final lat = (point.latitude * factor).round();
      final lng = (point.longitude * factor).round();

      _encodeValue(lat - lastLat, buffer);
      _encodeValue(lng - lastLng, buffer);

      lastLat = lat;
      lastLng = lng;
    }

    return buffer.toString();
  }

  /// Decodes a polyline string back into path coordinates.
  static List<LatLng> decodePolyline(String encodedPath, {int precision = 5}) {
    if (encodedPath.isEmpty) {
      return const [];
    }

    final factor = math.pow(10, precision).toDouble();
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encodedPath.length) {
      lat += _decodeValue(encodedPath, () => index++);
      lng += _decodeValue(encodedPath, () => index++);
      points.add(LatLng(lat / factor, lng / factor));
    }

    return points;
  }

  static List<LatLng> _filterByDistance(
    List<LatLng> path, {
    required double minimumDistanceMeters,
    required List<LatLng> preservePoints,
  }) {
    if (path.length <= 2 || minimumDistanceMeters <= 0) {
      return List<LatLng>.from(path);
    }

    final filtered = <LatLng>[path.first];
    var lastKept = path.first;

    for (var i = 1; i < path.length - 1; i++) {
      final point = path[i];
      final isPreserved = _containsPoint(preservePoints, point);
      final isFarEnough = _distance(lastKept, point) >= minimumDistanceMeters;

      if (isPreserved || isFarEnough) {
        filtered.add(point);
        lastKept = point;
      }
    }

    final lastPoint = path.last;
    if (!_samePoint(filtered.last, lastPoint)) {
      filtered.add(lastPoint);
    }

    return filtered;
  }

  static List<LatLng> _simplifyWithDouglasPeucker(
    List<LatLng> path, {
    required double toleranceMeters,
    required List<LatLng> preservePoints,
  }) {
    if (path.length <= 2 || toleranceMeters <= 0) {
      return List<LatLng>.from(path);
    }

    final protectedIndices = <int>{0, path.length - 1};
    for (var i = 1; i < path.length - 1; i++) {
      if (_containsPoint(preservePoints, path[i])) {
        protectedIndices.add(i);
      }
    }

    final boundaries = protectedIndices.toList()..sort();
    final simplified = <LatLng>[];

    for (var i = 0; i < boundaries.length - 1; i++) {
      final segment = _simplifySegment(
        path,
        startIndex: boundaries[i],
        endIndex: boundaries[i + 1],
        toleranceMeters: toleranceMeters,
      );

      if (simplified.isEmpty) {
        simplified.addAll(segment);
      } else {
        simplified.addAll(segment.skip(1));
      }
    }

    return simplified;
  }

  static List<LatLng> _simplifySegment(
    List<LatLng> path, {
    required int startIndex,
    required int endIndex,
    required double toleranceMeters,
  }) {
    if (endIndex <= startIndex) {
      return [path[startIndex]];
    }

    if (endIndex - startIndex == 1) {
      return [path[startIndex], path[endIndex]];
    }

    var maxDistance = 0.0;
    var splitIndex = -1;

    for (var i = startIndex + 1; i < endIndex; i++) {
      final distance = _distanceToSegmentMeters(
        path[i],
        path[startIndex],
        path[endIndex],
      );

      if (distance > maxDistance) {
        maxDistance = distance;
        splitIndex = i;
      }
    }

    if (splitIndex == -1 || maxDistance <= toleranceMeters) {
      return [path[startIndex], path[endIndex]];
    }

    final left = _simplifySegment(
      path,
      startIndex: startIndex,
      endIndex: splitIndex,
      toleranceMeters: toleranceMeters,
    );
    final right = _simplifySegment(
      path,
      startIndex: splitIndex,
      endIndex: endIndex,
      toleranceMeters: toleranceMeters,
    );

    return [...left, ...right.skip(1)];
  }

  static List<LatLng> _reducePrecision(
    List<LatLng> path, {
    required int precision,
  }) {
    if (path.isEmpty) {
      return const [];
    }

    final factor = math.pow(10, precision).toDouble();
    final reduced = <LatLng>[];

    for (final point in path) {
      final roundedPoint = LatLng(
        _round(point.latitude, factor),
        _round(point.longitude, factor),
      );

      if (reduced.isEmpty || !_samePoint(reduced.last, roundedPoint)) {
        reduced.add(roundedPoint);
      }
    }

    return reduced;
  }

  static double _distanceToSegmentMeters(
    LatLng point,
    LatLng start,
    LatLng end,
  ) {
    if (_samePoint(start, end)) {
      return _distance(start, point);
    }

    final averageLatitudeRad =
        ((start.latitude + end.latitude + point.latitude) / 3) * math.pi / 180;

    final startX = _projectX(start.longitude, averageLatitudeRad);
    final startY = _projectY(start.latitude);
    final endX = _projectX(end.longitude, averageLatitudeRad);
    final endY = _projectY(end.latitude);
    final pointX = _projectX(point.longitude, averageLatitudeRad);
    final pointY = _projectY(point.latitude);

    final deltaX = endX - startX;
    final deltaY = endY - startY;
    final lengthSquared = deltaX * deltaX + deltaY * deltaY;
    final projection =
        (((pointX - startX) * deltaX) + ((pointY - startY) * deltaY)) /
        lengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0);
    final closestX = startX + deltaX * clampedProjection;
    final closestY = startY + deltaY * clampedProjection;

    return math.sqrt(
      math.pow(pointX - closestX, 2) + math.pow(pointY - closestY, 2),
    );
  }

  static double _projectX(double longitude, double averageLatitudeRad) {
    return longitude *
        math.pi /
        180 *
        _earthRadiusMeters *
        math.cos(averageLatitudeRad);
  }

  static double _projectY(double latitude) {
    return latitude * math.pi / 180 * _earthRadiusMeters;
  }

  static double _round(double value, double factor) {
    return (value * factor).round() / factor;
  }

  static bool _containsPoint(List<LatLng> points, LatLng target) {
    return points.any((point) => _samePoint(point, target));
  }

  static bool _samePoint(LatLng a, LatLng b) {
    return a.latitude == b.latitude && a.longitude == b.longitude;
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    var encoded = value < 0 ? ~(value << 1) : value << 1;

    while (encoded >= 0x20) {
      buffer.writeCharCode((0x20 | (encoded & 0x1f)) + 63);
      encoded >>= 5;
    }

    buffer.writeCharCode(encoded + 63);
  }

  static int _decodeValue(String encodedPath, int Function() nextIndex) {
    var result = 0;
    var shift = 0;
    int value;

    do {
      value = encodedPath.codeUnitAt(nextIndex()) - 63;
      result |= (value & 0x1f) << shift;
      shift += 5;
    } while (value >= 0x20);

    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }
}
