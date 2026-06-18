import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/library_model.dart';
import '../../services/api_service.dart';
import '../../utils/api/api_url.dart';
import '../../utils/cache/api_cache_manager.dart';
import '../../utils/cache/cache_keys.dart';
import '../../utils/encryption/encryption_service.dart';

class LibraryRepository {
  LibraryRepository(this._apiService, this._cacheManager)
    : _assetDownloader = Dio();

  final APIService _apiService;
  final ApiCacheManager _cacheManager;
  final Dio _assetDownloader;

  Future<Map<String, List<CategoryModel>>> getCachedCategories() async {
    final cached = await _cacheManager.readMap(CacheKeys.libraryCategories);
    if (cached == null) return {'categories': [], 'yearlyCategories': []};

    final normalData = cached['categories'] as List<dynamic>? ?? [];
    final yearlyData = cached['yearlyCategories'] as List<dynamic>? ?? [];

    return {
      'categories': normalData
          .map((raw) => CategoryModel.fromJson(raw as Map<String, dynamic>))
          .toList(),
      'yearlyCategories': yearlyData
          .map((raw) => CategoryModel.fromJson(raw as Map<String, dynamic>))
          .toList(),
    };
  }

  Future<Map<String, List<CategoryModel>>> fetchCategories() async {
    final response = await _apiService.execute(
      method: Method.get,
      url: ApiUrl.categoriesActive,
      requiresAuth: false,
    );

    final data = response['categories'] as List<dynamic>? ?? [];
    final yearlyData = response['yearlyCategories'] as List<dynamic>? ?? [];

    final categories =
        await Future.wait(
            data.map((raw) async {
              final model = CategoryModel.fromJson(raw as Map<String, dynamic>);
              final localImage = await _cacheImage(model.image, 'categories');
              return model.copyWith(localImagePath: localImage);
            }),
          )
          ..sort((a, b) => a.order.compareTo(b.order));

    final yearlyCategories =
        await Future.wait(
            yearlyData.map((raw) async {
              final model = CategoryModel.fromJson(raw as Map<String, dynamic>);
              final localImage = await _cacheImage(model.image, 'categories');
              return model.copyWith(localImagePath: localImage);
            }),
          )
          ..sort((a, b) => a.order.compareTo(b.order));

    await _cacheManager.writeMap(CacheKeys.libraryCategories, {
      'categories': categories.map((c) => c.toCacheJson()).toList(),
      'yearlyCategories': yearlyCategories.map((c) => c.toCacheJson()).toList(),
    });

    return {'categories': categories, 'yearlyCategories': yearlyCategories};
  }

  Future<List<Chapter>> getCachedSubjects(dynamic categoryId) async {
    final cached = await _cacheManager.readMap(
      CacheKeys.librarySubjects(categoryId),
    );
    if (cached == null) return const <Chapter>[];
    final data = cached['subjects'] as List<dynamic>? ?? [];
    return data
        .map((raw) => Chapter.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<List<Chapter>> fetchSubjects(dynamic categoryId) async {
    final cleanIdStr = categoryId.toString().replaceAll('_yearly', '');
    final cleanId = int.tryParse(cleanIdStr) ?? 0;
    final isYearly = categoryId.toString().contains('_yearly');

    final response = await _apiService.execute(
      method: Method.get,
      url: ApiUrl.subjectsByCategory(cleanId),
      requiresAuth: false,
    );
    final data = response['subjects'] as List<dynamic>? ?? [];
    final subjects = data.map((raw) {
      final model = Chapter.fromJson(raw as Map<String, dynamic>);
      if (isYearly) {
        return Chapter(
          id: '${model.id}_yearly',
          categoryId: categoryId.toString(),
          name: model.name,
          order: model.order,
          image: model.image,
          status: model.status,
          isDeleted: model.isDeleted,
        );
      }
      return model;
    }).toList()..sort((a, b) => a.order.compareTo(b.order));

    await _cacheManager.writeMap(CacheKeys.librarySubjects(categoryId), {
      'subjects': subjects.map((s) => s.toCacheJson()).toList(),
    });

    return subjects;
  }

  Future<List<TopicItem>> getCachedTopics(dynamic subjectId) async {
    final cached = await _cacheManager.readMap(
      CacheKeys.libraryTopics(subjectId),
    );
    if (cached == null) return const <TopicItem>[];
    final data = cached['topics'] as List<dynamic>? ?? [];
    return data
        .map((raw) => TopicItem.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopicItem>> fetchTopics(dynamic subjectId, {String? type}) async {
    final cleanIdStr = subjectId.toString().replaceAll('_yearly', '');
    final cleanId = int.tryParse(cleanIdStr) ?? 0;
    final isYearly = subjectId.toString().contains('_yearly');

    final response = await _apiService.execute(
      method: Method.get,
      url: ApiUrl.topicsBySubject(cleanId, type: type),
      requiresAuth: false,
    );
    final data = response['topics'] as List<dynamic>? ?? [];
    final topics = await Future.wait(
      data.map((raw) async {
        final rawModel = TopicItem.fromJson(raw as Map<String, dynamic>);
        final model = isYearly
            ? rawModel.copyWith(
                id: '${rawModel.id}_yearly',
                subjectId: subjectId.toString(),
              )
            : rawModel;

        // Decrypt encrypted URL if present
        String? decryptedVideoUrl = model.videoUrl;
        if (model.encryptedUrl != null &&
            model.encryptedUrl!.isNotEmpty &&
            model.iv != null &&
            model.tag != null) {
          try {
            decryptedVideoUrl = await EncryptionService.decryptUrl(
              model.encryptedUrl!,
              model.iv!,
              model.tag!,
            );
          } catch (e) {
            // Decryption error handling
          }
        }

        final localImage = await _cacheImage(
          model.thumbUrl ?? model.imageUrl,
          'topics',
        );
        return model.copyWith(
          localImagePath: localImage,
          videoUrl: decryptedVideoUrl,
        );
      }),
    );

    await _cacheManager.writeMap(CacheKeys.libraryTopics(subjectId), {
      'topics': topics.map((t) => t.toCacheJson()).toList(),
    });

    return topics;
  }

  Future<String?> _cacheImage(String? url, String folderName) async {
    if (url == null || url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : uri.toString();
      final docsDir = await getApplicationDocumentsDirectory();
      final folder = Directory('${docsDir.path}/library/$folderName');
      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }
      final sanitizedName = fileName.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final filePath = '${folder.path}/$sanitizedName';
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      final response = await _assetDownloader.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(response.data ?? <int>[]);
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
