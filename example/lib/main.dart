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
  PathModel? savedPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OSM Path Tracker Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start Live Tracking
            ElevatedButton(
              child: const Text('Track New Path'),
              onPressed: () async {
                final result = await Navigator.push<PathModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LiveTrackingScreen(),
                  ),
                );

                if (result != null) {
                  setState(() {
                    savedPath = result;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // Navigate Path
            ElevatedButton(
              onPressed: savedPath == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PathNavigationScreen( pathModel: savedPath!),
                        ),
                      );
                    },
              child: const Text('Navigate Saved Path'),
            ),

            const SizedBox(height: 30),

            // Summary info
            if (savedPath != null) ...[
              Text('Distance: ${savedPath!.distance.toStringAsFixed(2)} km'),
              Text('Time: ${savedPath!.timestamp}'),
              Text('Points: ${savedPath!.path.length}'),
            ],
          ],
        ),
      ),
    );
  }
}
