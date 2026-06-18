class ArSyncMeta {
  const ArSyncMeta({
    required this.lastLoadedPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalItems,
  });

  final int lastLoadedPage;
  final int totalPages;
  final int pageSize;
  final int totalItems;

  bool get hasMorePages => lastLoadedPage < totalPages;

  Map<String, dynamic> toJson() => {
        'lastLoadedPage': lastLoadedPage,
        'totalPages': totalPages,
        'pageSize': pageSize,
        'totalItems': totalItems,
      };

  factory ArSyncMeta.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) =>
        v is int ? v : int.tryParse('$v') ?? fallback;
    return ArSyncMeta(
      lastLoadedPage: asInt(json['lastLoadedPage'], 1),
      totalPages: asInt(json['totalPages'], 1),
      pageSize: asInt(json['pageSize'], 100),
      totalItems: asInt(json['totalItems'], 0),
    );
  }
}
