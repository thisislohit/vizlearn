class CmsContentResponse {
  final String message;
  final Map<String, CmsContentData> entries;

  CmsContentResponse({
    required this.message,
    required this.entries,
  });

  factory CmsContentResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, CmsContentData> map = {};
    final dynamic data = json['data'];

    if (data is Map<String, dynamic>) {
      if (_looksLikeEntry(data)) {
        final entry = CmsContentData.fromJson(data);
        map[(entry.contentType.isNotEmpty ? entry.contentType : 'about_us').toLowerCase()] = entry;
      } else {
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final entry = CmsContentData.fromJson(value);
            map[key.toLowerCase()] = entry;
          }
        });
      }
    } else if (data is List) {
      for (final entry in data) {
        if (entry is Map<String, dynamic>) {
          final content = CmsContentData.fromJson(entry);
          map[content.contentType.toLowerCase()] = content;
        }
      }
    }

    return CmsContentResponse(
      message: (json['message'] ?? '').toString(),
      entries: map,
    );
  }

  static bool _looksLikeEntry(Map<String, dynamic> json) {
    return json.containsKey('contentType') && json.containsKey('content');
  }
}

class CmsContentData {
  final int id;
  final String contentType;
  final String content;
  final String createdAt;
  final String updatedAt;

  CmsContentData({
    required this.id,
    required this.contentType,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CmsContentData.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    final dynamic rawId = json['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    }

    return CmsContentData(
      id: parsedId,
      contentType: (json['contentType'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}

