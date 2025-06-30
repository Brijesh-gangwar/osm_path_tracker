# 🗺️ OSM Path Tracker

A simple Flutter package for **live GPS tracking** , **path drawing**, and **navigation** on **OpenStreetMap (OSM)** using `flutter_map`.  

`osm_path_tracker` helps you track a path in real-time, visualize it, and output a reusable model (`PathModel`) so you can store the tracked path **wherever you want** — Firebase, SQLite, REST APIs, or files.

---


## ✨ Features
 
- 📍 Real-time GPS tracking with `geolocator` 
- 🗺️ OpenStreetMap (OSM) integration using `flutter_map`
✅ Get distance, timestamp, and coordinates in a clean model (`PathModel`) 
- 📏 Automatic distance calculation (in kilometers)
- 🔄 Navigate a saved path visually on the OSM map 
- 💾 You decide how to store: local DB, Firebase, or any backend!

---

## ✨ Why Use It?


`osm_path_tracker` makes **live path tracking** easy: capture the full journey, **visualize** it on **OpenStreetMap**, and **store** it anywhere — local database, Firebase, or your own server.
 Track, draw, and save **complete GPS paths** — not just **A-to-B routes**. Own your data and **build powerful location features** on your terms, with no vendor lock-in.

---

## ⚙️ How It Works

 1️⃣ Live Tracking:
- Use LiveTrackingScreen to track user location in real time. 
- It returns a PathModel which contains a tracked path (list of coordinates in form of latitudes and longitudes) with distance and timestamp.

```dart

import 'package:latlong2/latlong.dart';

class PathModel {
  final List<LatLng> path;
  final double distance; // in kilometers
  final DateTime timestamp;
}

```


2️⃣ Path Storage:
- The returned PathModel can be stored wherever you like — Firebase, SQLite, or a custom API.

3️⃣ Path Navigation:
- Display any saved ( or tracked ) path using PathNavigationScreen.

---

## 🚀 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
    osm_path_tracker: ^<latest_version>
```

Then run in your terminal :

```bash
flutter pub get
```

Check your `pubspec.yaml` file whether package is installed properly.

---

## 🛠️ Usage

Import the package:

```dart
import 'package:osm_path_tracker/osm_path_tracker.dart';

```

### Add Android Permissions

Add these lines to your AndroidManifest.xml:

```dart


    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    // add this to enable background location
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

    // add this to enable internet
    <uses-permission android:name="android.permission.INTERNET"/>

```

### Basic Usage

```dart

// Use in your screen and stores path as savedpath from live tracking screen

final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
);

if (result is PathModel) {
  setState(() {
    savedPath = result;
  });
}

  // upload to Firestore
  await uploadPathToFirestore(savedPath!);

// upload to Http Server
   await uploadPathToHttp(savedPath!, 'https://your-api.com/upload');


```

#### Upload to Firestore (Firebase)
Add this helper to your project :

```dart

Future<void> uploadPathToFirestore(PathModel path) async {
  final firestore = FirebaseFirestore.instance;

  final pathData = path.toJson();

  await firestore
      .collection('paths') 
      .add(pathData);

  print('✅ Path uploaded to Firestore!');
}

```

#### Upload to HTTP server
Add this helper to your project :

```dart

Future<void> uploadPathToHttp(PathModel path, String apiUrl) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(path.toJson()),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('✅ Path uploaded successfully!');
  } else {
    throw Exception('❌ Failed to upload path: ${response.statusCode}');
  }
}

```

See the [example app](example/) for a complete implementation.

---


## 📚 Documentation

- [API Reference](https://pub.dev/documentation/osm_path_tracker/latest/)
- [Example Usage](example/)

---

## 💡 Contributions

Contributions and issues are welcome!  
Please open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.
