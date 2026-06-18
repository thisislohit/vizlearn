import '../../../services/api_service.dart';
import '../../../utils/api/api_url.dart';
import '../../../injectors/dependencies/core_dependencies.dart';

class ArMarkerDto {
  ArMarkerDto({
    required this.id,
    required this.title,
    required this.markerImageUrl,
    required this.model3dUrl,
    this.audioUrl,
    this.updatedAt,
    this.displayScale = 1.0,
  });

  final int id;
  final String title;
  final String markerImageUrl;
  final String model3dUrl;
  final String? audioUrl;
  final String? updatedAt;
  final double displayScale;

  factory ArMarkerDto.fromJson(Map<String, dynamic> json) {
    return ArMarkerDto(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '') as String,
      markerImageUrl:
          (json['marker_image_url'] ?? json['markerImageUrl'] ?? '') as String,
      model3dUrl:
          (json['model_3d_url'] ?? json['model3d_url'] ?? json['model_url'] ?? '') as String,
      audioUrl: (json['audio_url'] ?? json['audioUrl']) as String?,
      updatedAt: (json['updated_at'] ?? json['updatedAt']) as String?,
      displayScale: _parseDouble(json['display_scale'] ?? json['displayScale']) ?? 1.0,
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse('$v');
  }
}

class ArSyncMetaDto {
  ArSyncMetaDto({
    required this.total,
    this.maxUpdatedAt,
    required this.fingerprint,
  });

  final int total;
  final String? maxUpdatedAt;
  final String fingerprint;

  factory ArSyncMetaDto.fromJson(Map<String, dynamic> json) {
    return ArSyncMetaDto(
      total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? 0,
      maxUpdatedAt: json['maxUpdatedAt'] as String? ?? json['max_updated_at'] as String?,
      fingerprint: (json['fingerprint'] ?? '') as String,
    );
  }
}

class ArMarkersResponse {
  ArMarkersResponse({
    required this.data,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.limit,
  });

  final List<ArMarkerDto> data;
  final int total;
  final int totalPages;
  final int page;
  final int limit;
}

class ArApiService {
  ArApiService([APIService? apiService])
      : _apiService = apiService ?? getIt<APIService>();

  final APIService _apiService;

  Future<ArSyncMetaDto?> fetchSyncMeta() async {
    try {
      final response = await _apiService.execute(
        method: Method.get,
        url: ApiUrl.arSyncMeta,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return ArSyncMetaDto.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ArMarkersResponse> fetchMarkersPage({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.execute(
      method: Method.get,
      url: ApiUrl.arMarkers,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
      },
    );

    final data = response['data'];
    final list = data is List
        ? data
            .map((raw) => ArMarkerDto.fromJson(raw as Map<String, dynamic>))
            .toList()
        : <ArMarkerDto>[];

    return ArMarkersResponse(
      data: list,
      total: response['total'] is int ? response['total'] as int : list.length,
      totalPages: response['totalPages'] is int ? response['totalPages'] as int : 1,
      page: response['page'] is int ? response['page'] as int : page,
      limit: response['limit'] is int ? response['limit'] as int : limit,
    );
  }

  Future<List<ArMarkerDto>> fetchMarkers({int limit = 100}) async {
    final res = await fetchMarkersPage(page: 1, limit: limit);
    return res.data;
  }
}
