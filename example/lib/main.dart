import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:osm_path_tracker/osm_path_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSM Path Tracker Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  // These settings control the optional compression step in this example.
  static const double _minimumDistanceMeters = 10;
  static const double _simplificationToleranceMeters = 15;
  static const int _polylinePrecision = 5;

  PathModel? _savedPath;
  EncodedPathModel? _encodedPath;

  Future<void> _trackNewPath() async {
    // LiveTrackingScreen returns the raw recorded path when the user saves it.
    final result = await Navigator.push<PathModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const LiveTrackingScreen(),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _savedPath = result;
      _encodedPath = null;
    });
  }

  void _compressSavedPath() {
    final savedPath = _savedPath;
    if (savedPath == null) {
      return;
    }

    // Compression is opt-in, so we convert the saved raw path only when
    // the user taps the example button.
    final encodedPath = PathCompressionUtils.compressPathModel(
      savedPath,
      minimumDistanceMeters: _minimumDistanceMeters,
      simplificationToleranceMeters: _simplificationToleranceMeters,
      precision: _polylinePrecision,
    );

    setState(() {
      _encodedPath = encodedPath;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compressed ${encodedPath.originalPointCount} points to '
          '${encodedPath.compressedPointCount}',
        ),
      ),
    );
  }

  void _openRawNavigation() {
    final savedPath = _savedPath;
    if (savedPath == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PathNavigationScreen(pathModel: savedPath),
      ),
    );
  }

  void _openEncodedNavigation() {
    final encodedPath = _encodedPath;
    if (encodedPath == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PathNavigationScreen(encodedPathModel: encodedPath),
      ),
    );
  }

  int _jsonSizeInBytes(Map<String, dynamic> json) {
    return utf8.encode(jsonEncode(json)).length;
  }

  int _stringSizeInBytes(String value) {
    return utf8.encode(value).length;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes bytes';
    }

    final kilobytes = bytes / 1024;
    return '${kilobytes.toStringAsFixed(2)} KB ($bytes bytes)';
  }

  @override
  Widget build(BuildContext context) {
    final savedPath = _savedPath;
    final encodedPath = _encodedPath;
    final savedPathSize = savedPath == null
        ? null
        : _formatSize(_jsonSizeInBytes(savedPath.toJson()));
    final encodedPolylineSize = encodedPath == null
        ? null
        : _formatSize(_stringSizeInBytes(encodedPath.encodedPath));

    return Scaffold(
      appBar: AppBar(title: const Text('OSM Path Tracker Example')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Track a raw path, compress it optionally, and navigate with either model.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          // Step 1: record and save a raw path from the tracking screen.
          ElevatedButton(
            onPressed: _trackNewPath,
            child: const Text('Track New Path'),
          ),
          const SizedBox(height: 12),
          // Step 2: create an encoded version from the saved raw path.
          ElevatedButton(
            onPressed: savedPath == null ? null : _compressSavedPath,
            child: const Text('Compress Saved Path'),
          ),
          const SizedBox(height: 12),
          // Raw navigation uses the original point list directly.
          ElevatedButton(
            onPressed: savedPath == null ? null : _openRawNavigation,
            child: const Text('Navigate Raw Path'),
          ),
          const SizedBox(height: 12),
          // Encoded navigation resolves the decoded points from EncodedPathModel.
          ElevatedButton(
            onPressed: encodedPath == null ? null : _openEncodedNavigation,
            child: const Text('Navigate Encoded Path'),
          ),
          const SizedBox(height: 32),
          if (savedPath != null) ...[
            const Text(
              'Raw Path Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Distance: ${savedPath.distance.toStringAsFixed(2)} km'),
            Text('Saved At: ${savedPath.timestamp}'),
            Text('Path Points: ${savedPath.path.length}'),
            Text('Custom Points: ${savedPath.customPoints.length}'),
            Text('Path Model Size: $savedPathSize'),
            const SizedBox(height: 24),
          ],
          if (encodedPath != null) ...[
            const Text(
              'Encoded Path Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Original Points: ${encodedPath.originalPointCount}'),
            Text('Compressed Points: ${encodedPath.compressedPointCount}'),
            Text(
              'Compressed Distance: '
              '${encodedPath.compressedDistance.toStringAsFixed(2)} km',
            ),
            Text('Polyline Precision: ${encodedPath.polylinePrecision}'),
            Text('Encoded Length: ${encodedPath.encodedPath.length} chars'),
            Text('Encoded Polyline Size: $encodedPolylineSize'),
          ],
        ],
      ),
    );
  }
}
