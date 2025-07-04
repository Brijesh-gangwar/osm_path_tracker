# Changelog

All notable changes to this project will be documented in this file.

## [0.0.3] - 2025-07-05

### Added
- Introduced real **Streams** for live location updates: using `StreamController` and `StreamSubscription` to listen for GPS positions in real time.
- Integrated `StreamBuilder` in the UI to redraw the map marker and polyline automatically when new location data arrives.
- Added a **timeout** (`20s`) to `getCurrentPosition()` to prevent waiting forever for GPS lock.
- Added **accuracy filter**: ignores updates with GPS accuracy worse than 20 meters.
- Added **minimum distance filter** (`2 meters`) to reduce small GPS jitter that causes false path points.
- Added debug logs to show how Streams accept or discard new points.
- Improved resource handling: **cancels Streams** properly when closing the screen to avoid battery drain or leaks.


## [0.0.2] - 2025-07-01

### Changed
- Improved README.md with clearer usage instructions and stronger unique value statement.
- Added better function examples for uploading PathModel to Firestore or any custom HTTP server.
- Improved developer documentation for easier integration.

## [0.0.1] - 2025-06-30

### Added
- Initial release of `osm_path_tracker`.
- Added live tracking screen using OpenStreetMap tiles and `flutter_map`.
- Added path saving feature with distance calculation.
- Added reusable `PathModel` to output tracked path data.
- Added path navigation screen to view saved paths on OSM.
- Example app included to demonstrate live tracking and path navigation.

### Notes
- Users can integrate the tracked path with their own storage: local database, Firebase, or any backend.
- Designed to be flexible for GIS/path-based Flutter apps.

---

