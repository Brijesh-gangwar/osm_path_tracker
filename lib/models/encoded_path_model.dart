import 'path_model.dart';

/// Encoded and compressed route data produced from a raw [PathModel].
class EncodedPathModel {
  /// The original raw path model that the encoded path was derived from.
  final PathModel pathModel;

  /// Encoded polyline string representation of the compressed route.
  final String encodedPath;

  /// Precision used when encoding the polyline.
  final int polylinePrecision;

  /// Number of coordinates in the original raw path.
  final int originalPointCount;

  /// Number of coordinates remaining after compression.
  final int compressedPointCount;

  /// Distance in kilometers measured from the filtered route.
  final double compressedDistance;

  /// Creates an encoded path container for storage or transfer.
  const EncodedPathModel({
    required this.pathModel,
    required this.encodedPath,
    required this.polylinePrecision,
    required this.originalPointCount,
    required this.compressedPointCount,
    required this.compressedDistance,
  });

  /// Serializes this encoded path model into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'pathModel': pathModel.toJson(),
    'encodedPath': encodedPath,
    'polylinePrecision': polylinePrecision,
    'originalPointCount': originalPointCount,
    'compressedPointCount': compressedPointCount,
    'compressedDistance': compressedDistance,
  };

  /// Creates an [EncodedPathModel] from serialized JSON data.
  factory EncodedPathModel.fromJson(Map<String, dynamic> json) {
    return EncodedPathModel(
      pathModel: PathModel.fromJson(json['pathModel'] as Map<String, dynamic>),
      encodedPath: json['encodedPath'] as String,
      polylinePrecision: (json['polylinePrecision'] as num).toInt(),
      originalPointCount: (json['originalPointCount'] as num).toInt(),
      compressedPointCount: (json['compressedPointCount'] as num).toInt(),
      compressedDistance: (json['compressedDistance'] as num).toDouble(),
    );
  }
}
