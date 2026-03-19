# Changelog

All notable changes to this project will be documented in this file.

## [0.0.5] - 2026-03-19

### Added
- Added `PathCompressionUtils` for optional path filtering, Douglas-Peucker simplification, precision reduction, and polyline encoding/decoding.
- Added `EncodedPathModel` to store encoded route data separately from the base `PathModel`.
- Added tests for compression, encoded model serialization, and `PathNavigationScreen` input handling.

### Changed
- Restored `PathModel` as the original raw path model containing only `path`, `distance`, `timestamp`, and `customPoints`.
- Updated `PathNavigationScreen` so it accepts either a raw `PathModel` or an `EncodedPathModel`.
- Kept `LiveTrackingScreen` focused on raw GPS capture and path saving without automatic compression.
- Refreshed the README with the current API, package version, and optional compression workflow.

## [0.0.4] - 2026-02-16

### Changed
- Added `customPoints` list in `PathModel` to store user-defined points along with path.
- Updated `LiveTrackingScreen` and `PathNavigationScreen` implementation.
- Updated `main.dart` file in example.

## [0.0.3] - 2025-07-05

### Added
- Introduced real streams for live location updates using `StreamController` and `StreamSubscription`.
- Integrated `StreamBuilder` in the UI to redraw the map marker and polyline automatically when new location data arrives.
- Added a timeout (`20s`) to `getCurrentPosition()` to prevent waiting forever for GPS lock.
- Added an accuracy filter to ignore updates with GPS accuracy worse than 20 meters.
- Added a minimum distance filter (`2 meters`) to reduce small GPS jitter that causes false path points.
- Improved resource handling by cancelling streams properly when closing the screen.

## [0.0.2] - 2025-07-01

### Changed
- Improved `README.md` with clearer usage instructions and stronger unique value statement.
- Added better function examples for uploading `PathModel` to Firestore or any custom HTTP server.
- Improved developer documentation for easier integration.

## [0.0.1] - 2025-06-30

### Added
- Initial release of `osm_path_tracker`.
- Added live tracking screen using OpenStreetMap tiles and `flutter_map`.
- Added path saving feature with distance calculation.
- Added reusable `PathModel` to output tracked path data.
- Added path navigation screen to view saved paths on OSM.
- Included an example app demonstrating live tracking and path navigation.
