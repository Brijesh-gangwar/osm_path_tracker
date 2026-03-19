# OSM Path Tracker

A Flutter package for live GPS tracking, path saving, optional path compression, and path navigation on OpenStreetMap using `flutter_map`.

`osm_path_tracker` helps you:
- track a route in real time,
- save a clean reusable `PathModel`,
- optionally compress that route into an `EncodedPathModel`,
- and render either raw or encoded paths in the navigation screen.

It is built for apps that need more than a simple A-to-B route. Use it to capture real movement, store journeys in your own backend, and visualize them later on OpenStreetMap.

## Features

- Real-time GPS tracking with `geolocator`
- OpenStreetMap integration with `flutter_map`
- Reusable `PathModel` for raw saved paths
- Optional `PathCompressionUtils` for distance-threshold filtering, Douglas-Peucker simplification, precision reduction, and Google-style polyline encoding
- Separate `EncodedPathModel` for encoded path workflows
- Path navigation from either raw or encoded route data
- Custom saved points via `customPoints`

## Why Use It?

Use it when you want to:
- build fitness, delivery, travel, GIS, patrol, or field-service apps
- save full user movement paths instead of just source and destination
- store path data in Firebase, SQLite, REST APIs, or your own backend
- optionally compress paths before sending or storing them
- navigate with either raw coordinates or encoded route data

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  osm_path_tracker: ^0.0.5
```

Then run:

```bash
flutter pub get
```

## Models

### `PathModel`

The base model returned by `LiveTrackingScreen`.

```dart
class PathModel {
  final List<LatLng> path;
  final double distance;
  final DateTime timestamp;
  final List<LatLng> customPoints;
}
```

### `EncodedPathModel`

Use this when you want an encoded/compressed representation of a saved route.

```dart
class EncodedPathModel {
  final PathModel pathModel;
  final String encodedPath;
  final int polylinePrecision;
  final int originalPointCount;
  final int compressedPointCount;
  final double compressedDistance;
}
```

## How It Works

### Live Tracking

`LiveTrackingScreen` listens to GPS updates, draws the route on OpenStreetMap, and returns a `PathModel` containing:
- `path`
- `distance`
- `timestamp`
- `customPoints`

### Optional Compression

If your app needs a smaller transferable representation, you can pass the saved `PathModel` into `PathCompressionUtils`. That utility can:
- filter noisy points using minimum-distance thresholding
- simplify the route using the Douglas-Peucker algorithm
- reduce coordinate precision
- encode the result as a polyline string

### Navigation

`PathNavigationScreen` can render either:
- a raw `PathModel`
- an `EncodedPathModel`

## Usage

Import the package:

```dart
import 'package:osm_path_tracker/osm_path_tracker.dart';
```

### Track and Save a Raw Path

```dart
final rawPath = await Navigator.push<PathModel>(
  context,
  MaterialPageRoute(
    builder: (_) => const LiveTrackingScreen(),
  ),
);

if (rawPath == null) return;
```

### Optionally Compress the Saved Path

```dart
final encodedPath = PathCompressionUtils.compressPathModel(
  rawPath,
  minimumDistanceMeters: 10,
  simplificationToleranceMeters: 15,
  precision: 5,
);
```

### Navigate with a Raw Path

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PathNavigationScreen(pathModel: rawPath),
  ),
);
```

### Navigate with an Encoded Path

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PathNavigationScreen(
      encodedPathModel: encodedPath,
    ),
  ),
);
```

## Path Compression

`PathCompressionUtils` supports this pipeline:

```text
GPS Stream
  -> Minimum-Distance Noise Filtering
  -> Douglas-Peucker Simplification
  -> Precision Reduction
  -> Polyline Encoding
```

Available controls:
- `minimumDistanceMeters`
- `simplificationToleranceMeters`
- `precision`

Example:

```dart
final result = PathCompressionUtils.compressPath(
  rawPath.path,
  minimumDistanceMeters: 10,
  simplificationToleranceMeters: 15,
  precision: 5,
  preservePoints: rawPath.customPoints,
);
```

## Android Permissions

Add these permissions to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Example Storage Helpers

### Firestore

```dart
Future<void> uploadPathToFirestore(PathModel path) async {
  final firestore = FirebaseFirestore.instance;
  await firestore.collection('paths').add(path.toJson());
}
```

### HTTP API

```dart
Future<void> uploadPathToHttp(PathModel path, String apiUrl) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(path.toJson()),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to upload path: ${response.statusCode}');
  }
}
```

## Notes

- `LiveTrackingScreen` returns the raw tracked path.
- Compression is opt-in and should be called explicitly by your app.
- `PathNavigationScreen` accepts exactly one of `pathModel` or `encodedPathModel`.

## Documentation

- [API Reference](https://pub.dev/documentation/osm_path_tracker/latest/)
- [Example App](example/)
- [Changelog](CHANGELOG.md)

## Contributions

Contributions and issues are welcome.

If you want to improve the package:
- open an issue for bugs or feature requests
- submit a pull request with improvements
- update tests and docs when you add new functionality

## License

This project is licensed under the MIT License.
