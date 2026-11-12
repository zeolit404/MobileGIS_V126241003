class DigitizationResult {
  final int? id;
  final String imagePath;
  final double distanceMeters;
  final int vertexCount;
  final String waktu;

  const DigitizationResult({
    this.id,
    required this.imagePath,
    required this.distanceMeters,
    required this.vertexCount,
    required this.waktu,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'distance_meters': distanceMeters,
      'vertex_count': vertexCount,
      'waktu': waktu,
    };
  }

  factory DigitizationResult.fromMap(Map<String, dynamic> map) {
    return DigitizationResult(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      distanceMeters: (map['distance_meters'] as num).toDouble(),
      vertexCount: map['vertex_count'] as int,
      waktu: map['waktu'] as String,
    );
  }
}
