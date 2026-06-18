import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ApiCacheManager {
  static const String _boxName = 'api_cache_box';

  Future<Box<String>> get _box async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  Future<Map<String, dynamic>?> readMap(String key) async {
    final box = await _box;
    final raw = box.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // ignore malformed cache entry
    }
    return null;
  }

  Future<void> writeMap(String key, Map<String, dynamic> data) async {
    final box = await _box;
    await box.put(key, jsonEncode(data));
  }

  Future<void> delete(String key) async {
    final box = await _box;
    await box.delete(key);
  }
}
