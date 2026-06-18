import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/ar_load_progress.dart';
import '../models/ar_sync_meta.dart';
import '../services/ar_api_service.dart';

export '../models/ar_sync_meta.dart';

class ArMarkerEntry {
  ArMarkerEntry({
    required this.id,
    required this.title,
    required this.markerImageLocalPath,
    required this.modelLocalPath,
    this.audioLocalPath,
    this.contentVersion,
    this.displayScale = 1.0,
  });

  final int id;
  final String title;
  final String markerImageLocalPath;
  final String modelLocalPath;
  final String? audioLocalPath;
  final String? contentVersion;
  final double displayScale;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'markerImageLocalPath': markerImageLocalPath,
        'modelLocalPath': modelLocalPath,
        'audioLocalPath': audioLocalPath,
        'contentVersion': contentVersion,
        'displayScale': displayScale,
      };

  factory ArMarkerEntry.fromJson(Map<String, dynamic> json) {
    return ArMarkerEntry(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '') as String,
      markerImageLocalPath:
          (json['markerImageLocalPath'] ?? json['marker_image_local_path'] ?? '') as String,
      modelLocalPath:
          (json['modelLocalPath'] ?? json['model_local_path'] ?? '') as String,
      audioLocalPath: (json['audioLocalPath'] ?? json['audio_local_path']) as String?,
      contentVersion: (json['contentVersion'] ?? json['content_version']) as String?,
      displayScale: _parseDouble(json['displayScale'] ?? json['display_scale']) ?? 1.0,
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse('$v');
  }
}

/// Repository responsible for fetching AR markers and caching their assets locally.
class ArRepository {
  ArRepository(this._apiService);

  final ArApiService _apiService;

  static const String _boxName = 'ar_markers';
  static const String _metaKey = '__ar_sync_meta__';
  static const String _fingerprintKey = '__ar_fingerprint__';
  static const int pageSize = 100;

  Box<String>? _box;
  bool _prefetchRunning = false;

  Future<Box<String>> _openBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<String>(_boxName);
    } else {
      _box = await Hive.openBox<String>(_boxName);
    }
    return _box!;
  }

  Future<ArSyncMeta?> _readMeta() async {
    final box = await _openBox();
    final raw = box.get(_metaKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ArSyncMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeMeta(ArSyncMeta meta) async {
    final box = await _openBox();
    await box.put(_metaKey, jsonEncode(meta.toJson()));
  }

  Future<void> _clearMeta() async {
    final box = await _openBox();
    await box.delete(_metaKey);
  }

  Future<List<ArMarkerEntry>> loadMarkersFromCache() async {
    final box = await _openBox();
    final entries = <ArMarkerEntry>[];
    for (final key in box.keys) {
      if (key.toString().startsWith('__')) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        entries.add(ArMarkerEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    return entries;
  }

  /// Returns markers from cache if available; otherwise fetches page 1 from API,
  /// downloads assets, and caches. Uses fingerprint to detect server-side changes.
  Future<List<ArMarkerEntry>> getOrFetchMarkers({
    bool forceRefresh = false,
    int limit = pageSize,
    ArLoadProgressCallback? onLoadProgress,
  }) async {
    void report(int pct, {String? stage, int? completed, int? total}) {
      onLoadProgress?.call(ArLoadProgress(
        percent: pct.clamp(0, 100),
        stage: stage ?? 'Downloading AR markers',
        completed: completed,
        total: total,
      ));
    }

    var needsFullReload = forceRefresh;
    if (!needsFullReload) {
      try {
        final remote = await _apiService.fetchSyncMeta();
        if (remote != null && remote.fingerprint.isNotEmpty) {
          final box = await _openBox();
          final stored = box.get(_fingerprintKey);
          if (stored != remote.fingerprint) needsFullReload = true;
        }
      } catch (_) {}
    }

    if (!needsFullReload) {
      final cached = await loadMarkersFromCache();
      if (cached.isNotEmpty) return _ensureLocalFiles(cached);
    }

    if (needsFullReload) {
      final box = await _openBox();
      await box.clear();
      await _clearMeta();
      await _deleteArAssetDirs();
    }

    report(2, stage: 'Connecting to server');
    final first = await _apiService.fetchMarkersPage(page: 1, limit: limit.clamp(1, 500));
    final totalPages = first.totalPages < 1 ? 1 : first.totalPages;
    final markerTotal = first.data.length;

    report(8, stage: 'Downloading & saving markers', completed: 0, total: markerTotal);
    await _persistDtos(first.data, onProgress: (completed, total) {
      if (total <= 0) return;
      final v = 8 + ((completed * 82) / total).round();
      report(
        v.clamp(8, 90),
        stage: 'Downloading & saving markers',
        completed: completed,
        total: total,
      );
    });

    report(92, stage: 'Finalizing storage');
    await _writeMeta(ArSyncMeta(
      lastLoadedPage: 1,
      totalPages: totalPages,
      pageSize: limit,
      totalItems: first.total,
    ));

    try {
      final fp = await _apiService.fetchSyncMeta();
      if (fp != null && fp.fingerprint.isNotEmpty) {
        final box = await _openBox();
        await box.put(_fingerprintKey, fp.fingerprint);
      }
    } catch (_) {}

    report(96, stage: 'Saving to device');
    final result = await loadMarkersFromCache();
    report(100, stage: 'Download complete', completed: result.length, total: result.length);
    return result;
  }

  Future<bool> prefetchNextPagesInBackground({
    int maxPages = 2,
    ArLoadProgressCallback? onLoadProgress,
  }) async {
    if (_prefetchRunning) return false;
    _prefetchRunning = true;
    try {
      var meta = await _readMeta();
      if (meta == null || !meta.hasMorePages) return false;

      final box = await _openBox();
      var last = meta.lastLoadedPage;
      final total = meta.totalPages;
      var didWork = false;

      for (var i = 0; i < maxPages; i++) {
        if (last >= total) break;
        final response =
            await _apiService.fetchMarkersPage(page: last + 1, limit: meta.pageSize);
        if (response.data.isEmpty) break;

        for (final marker in response.data) {
          try {
            final entry = await _downloadAndPersistMarker(marker);
            if (entry != null) {
              await box.put(marker.id.toString(), jsonEncode(entry.toJson()));
              didWork = true;
            }
          } catch (_) {}
        }

        last++;
        await _writeMeta(ArSyncMeta(
          lastLoadedPage: last,
          totalPages: response.totalPages < 1 ? total : response.totalPages,
          pageSize: meta.pageSize,
          totalItems: response.total,
        ));
      }
      return didWork;
    } catch (_) {
      return false;
    } finally {
      _prefetchRunning = false;
    }
  }

  Future<bool> hasMorePagesToPrefetch() async {
    final meta = await _readMeta();
    return meta?.hasMorePages ?? false;
  }

  Future<void> _persistDtos(
    List<ArMarkerDto> markers, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final box = await _openBox();
    final total = markers.length;
    var completed = 0;
    for (final marker in markers) {
      try {
        final entry = await _downloadAndPersistMarker(marker);
        if (entry != null) {
          await box.put(marker.id.toString(), jsonEncode(entry.toJson()));
        }
      } catch (_) {}
      completed++;
      onProgress?.call(completed, total);
    }
  }

  Future<List<ArMarkerEntry>> _ensureLocalFiles(
    List<ArMarkerEntry> cachedEntries, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final result = <ArMarkerEntry>[];
    final box = await _openBox();
    final total = cachedEntries.length;
    var completed = 0;

    for (final entry in cachedEntries) {
      var markerPath = entry.markerImageLocalPath;
      var modelPath = entry.modelLocalPath;
      var audioPath = entry.audioLocalPath;

      if (Platform.isIOS) {
        markerPath = _rebuildIosPath(markerPath, docsDir.path, 'ar/markers');
        modelPath = _rebuildIosPath(modelPath, docsDir.path, null);
        if (audioPath != null) {
          audioPath = _rebuildIosPath(audioPath, docsDir.path, 'ar/audio');
        }
      }

      var updated = ArMarkerEntry(
        id: entry.id,
        title: entry.title,
        markerImageLocalPath: markerPath,
        modelLocalPath: modelPath,
        audioLocalPath: audioPath,
        contentVersion: entry.contentVersion,
        displayScale: entry.displayScale,
      );

      final changed = updated.markerImageLocalPath != entry.markerImageLocalPath ||
          updated.modelLocalPath != entry.modelLocalPath ||
          updated.audioLocalPath != entry.audioLocalPath;

      if (!_fileExists(updated.markerImageLocalPath) || !_fileExists(updated.modelLocalPath)) {
        completed++;
        onProgress?.call(completed, total);
        continue;
      }

      if (updated.audioLocalPath != null &&
          updated.audioLocalPath!.isNotEmpty &&
          !_fileExists(updated.audioLocalPath!)) {
        updated = ArMarkerEntry(
          id: updated.id,
          title: updated.title,
          markerImageLocalPath: updated.markerImageLocalPath,
          modelLocalPath: updated.modelLocalPath,
          audioLocalPath: null,
          contentVersion: updated.contentVersion,
          displayScale: updated.displayScale,
        );
      }

      if (changed) {
        await box.put(entry.id.toString(), jsonEncode(updated.toJson()));
      }

      result.add(updated);
      completed++;
      onProgress?.call(completed, total);
    }
    return result;
  }

  String _rebuildIosPath(String oldPath, String currentDocsPath, String? subDir) {
    if (oldPath.isEmpty) return oldPath;
    final fileName = p.basename(oldPath);
    return subDir != null
        ? p.join(currentDocsPath, subDir, fileName)
        : p.join(currentDocsPath, fileName);
  }

  Future<void> _deleteArAssetDirs() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final arRoot = Directory(p.join(docsDir.path, 'ar'));
      if (arRoot.existsSync()) await arRoot.delete(recursive: true);
    } catch (_) {}
    if (Platform.isAndroid) {
      try {
        final supportDir = await getApplicationSupportDirectory();
        for (final entity in supportDir.listSync()) {
          if (entity is File &&
              entity.path.endsWith('.glb') &&
              p.basename(entity.path).startsWith('model_')) {
            await entity.delete();
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _deleteFilesForEntry(ArMarkerEntry entry) async {
    try {
      for (final path in [
        entry.markerImageLocalPath,
        entry.modelLocalPath,
        if (entry.audioLocalPath != null) entry.audioLocalPath!,
      ]) {
        if (path.isEmpty) continue;
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
  }

  bool _fileExists(String path) => path.isNotEmpty && File(path).existsSync();

  Future<ArMarkerEntry?> _downloadAndPersistMarker(ArMarkerDto marker) async {
    final box = await _openBox();
    var forceRedownload = false;
    final raw = box.get(marker.id.toString());
    if (raw != null && raw.isNotEmpty) {
      try {
        final old = ArMarkerEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        final newV = marker.updatedAt ?? '';
        final oldV = old.contentVersion ?? '';
        if (oldV.isNotEmpty && newV.isNotEmpty && oldV != newV) {
          await _deleteFilesForEntry(old);
          forceRedownload = true;
        }
      } catch (_) {}
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final markersDir = Directory(p.join(docsDir.path, 'ar', 'markers'));
    final audioDir = Directory(p.join(docsDir.path, 'ar', 'audio'));
    if (!markersDir.existsSync()) markersDir.createSync(recursive: true);
    if (!audioDir.existsSync()) audioDir.createSync(recursive: true);

    final sid = marker.id.toString();

    final markerImageLocalPath = await _downloadIfNeeded(
      uri: Uri.parse(marker.markerImageUrl),
      directory: markersDir,
      fileName: 'marker_$sid.png',
      forceRedownload: forceRedownload,
    );

    final Directory modelDir;
    if (Platform.isAndroid) {
      modelDir = await getApplicationSupportDirectory();
    } else {
      modelDir = docsDir;
    }

    final modelLocalPath = await _downloadIfNeeded(
      uri: Uri.parse(marker.model3dUrl),
      directory: modelDir,
      fileName: 'model_$sid.glb',
      forceRedownload: forceRedownload,
    );

    if (markerImageLocalPath == null || modelLocalPath == null) return null;

    String? audioLocalPath;
    if (marker.audioUrl != null && marker.audioUrl!.isNotEmpty) {
      audioLocalPath = await _downloadIfNeeded(
        uri: Uri.parse(marker.audioUrl!),
        directory: audioDir,
        fileName: 'audio_$sid.mp3',
        forceRedownload: forceRedownload,
      );
    }

    return ArMarkerEntry(
      id: marker.id,
      title: marker.title,
      markerImageLocalPath: markerImageLocalPath,
      modelLocalPath: modelLocalPath,
      audioLocalPath: audioLocalPath,
      contentVersion: marker.updatedAt,
      displayScale: marker.displayScale,
    );
  }

  Future<String?> _downloadIfNeeded({
    required Uri uri,
    required Directory directory,
    required String fileName,
    bool forceRedownload = false,
  }) async {
    if (!directory.existsSync()) directory.createSync(recursive: true);
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);

    if (forceRedownload && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }

    if (await file.exists()) return filePath;

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (_) {}
    return null;
  }
}
