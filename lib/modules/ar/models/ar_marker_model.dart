import 'dart:io';

class ArMarkerModel {
  final int id;
  final String title;
  final String markerImageUrl;
  final String model3dUrl;
  final String? audioUrl;
  final double displayScale;

  String? markerImageLocalPath;
  String? modelLocalPath;
  String? audioLocalPath;

  ArMarkerModel({
    required this.id,
    required this.title,
    required this.markerImageUrl,
    required this.model3dUrl,
    this.audioUrl,
    this.markerImageLocalPath,
    this.modelLocalPath,
    this.audioLocalPath,
    this.displayScale = 1.0,
  });

  // Human-readable name used as the AR reference image identifier
  String get markerName => 'ar_marker_$id';

  bool get isFullyDownloaded {
    final markerOk = markerImageLocalPath != null &&
        markerImageLocalPath!.isNotEmpty &&
        File(markerImageLocalPath!).existsSync();
    final modelOk = modelLocalPath != null &&
        modelLocalPath!.isNotEmpty &&
        File(modelLocalPath!).existsSync();
    return markerOk && modelOk;
  }

  factory ArMarkerModel.fromApiJson(Map<String, dynamic> json) {
    return ArMarkerModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      markerImageUrl: json['marker_image_url']?.toString() ?? '',
      model3dUrl: json['model_3d_url']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString(),
      displayScale: (json['display_scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'markerImageUrl': markerImageUrl,
      'model3dUrl': model3dUrl,
      'audioUrl': audioUrl,
      'markerImageLocalPath': markerImageLocalPath,
      'modelLocalPath': modelLocalPath,
      'audioLocalPath': audioLocalPath,
      'displayScale': displayScale,
    };
  }

  factory ArMarkerModel.fromJson(Map<String, dynamic> json) {
    return ArMarkerModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      markerImageUrl: json['markerImageUrl']?.toString() ?? '',
      model3dUrl: json['model3dUrl']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString(),
      markerImageLocalPath: json['markerImageLocalPath']?.toString(),
      modelLocalPath: json['modelLocalPath']?.toString(),
      audioLocalPath: json['audioLocalPath']?.toString(),
      displayScale: (json['displayScale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  ArMarkerModel copyWith({
    String? markerImageLocalPath,
    String? modelLocalPath,
    String? audioLocalPath,
    double? displayScale,
  }) {
    return ArMarkerModel(
      id: id,
      title: title,
      markerImageUrl: markerImageUrl,
      model3dUrl: model3dUrl,
      audioUrl: audioUrl,
      markerImageLocalPath: markerImageLocalPath ?? this.markerImageLocalPath,
      modelLocalPath: modelLocalPath ?? this.modelLocalPath,
      audioLocalPath: audioLocalPath ?? this.audioLocalPath,
      displayScale: displayScale ?? this.displayScale,
    );
  }
}
