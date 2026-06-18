import 'package:get/get.dart';

import '../data/models/library_model.dart';
import '../data/repositories/library_repository.dart';
import '../utils/app_utils.dart';
import 'hologram_controller.dart';

class LibraryController extends GetxController {
  LibraryController(this._repository);

  final LibraryRepository _repository;
  final HologramController? _hologramController =
      Get.isRegistered<HologramController>()
      ? Get.find<HologramController>()
      : null;

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<CategoryModel> yearlyCategories = <CategoryModel>[].obs;
  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);

  final RxBool isLoadingCategories = false.obs;
  final RxString categoriesError = ''.obs;

  final RxMap<String, List<Chapter>> _subjectsByCategory =
      <String, List<Chapter>>{}.obs;
  final RxSet<String> _subjectsLoading = <String>{}.obs;

  final RxMap<String, List<TopicItem>> _topicsBySubject =
      <String, List<TopicItem>>{}.obs;
  final RxSet<String> _topicsLoading = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Hydrate everything we can from local cache on startup.
    // All API fetches (categories/subjects/topics) are driven by Sync All
    // or explicit user actions, not from here.
    _hydrateAllFromCache();
  }

  Future<void> _hydrateCategoriesFromCache() async {
    final cached = await _repository.getCachedCategories();
    if (cached['categories']!.isNotEmpty) {
      categories.assignAll(cached['categories']!);
    }
    if (cached['yearlyCategories']!.isNotEmpty) {
      yearlyCategories.assignAll(cached['yearlyCategories']!);
    }
  }

  Future<void> _hydrateAllFromCache() async {
    // Categories
    await _hydrateCategoriesFromCache();

    // Hydrate normal categories
    for (final category in categories) {
      final categoryKey = '${category.id}';
      await _hydrateCategoryContent(categoryKey);
    }

    // Hydrate yearly categories
    for (final category in yearlyCategories) {
      final categoryKey = '${category.id}_yearly';
      await _hydrateCategoryContent(categoryKey);
    }
  }

  Future<void> _hydrateCategoryContent(String categoryKey) async {
    final hasSubjects = await _hydrateSubjectsFromCache(categoryKey);
    if (!hasSubjects) return;

    final subjects = _subjectsByCategory[categoryKey] ?? const <Chapter>[];
    for (final subject in subjects) {
      await _hydrateTopicsFromCache(subject.id);
    }
  }

  Future<bool> _hydrateSubjectsFromCache(String categoryKey) async {
    final cached = await _repository.getCachedSubjects(categoryKey);
    if (cached.isEmpty) return false;
    _subjectsByCategory[categoryKey] = cached;
    return true;
  }

  Future<bool> _hydrateTopicsFromCache(String subjectId) async {
    final cached = await _repository.getCachedTopics(subjectId);
    if (cached.isEmpty) return false;
    _topicsBySubject[subjectId] = cached;
    final controller = _hologramController;
    if (controller != null) {
      await controller.ensureTopicsLocalStatus(cached);
    }
    return true;
  }

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    if (isLoadingCategories.value) return;
    if (categories.isNotEmpty && !forceRefresh) return;

    try {
      isLoadingCategories.value = true;
      categoriesError.value = '';

      final result = await _repository.fetchCategories();
      categories.assignAll(result['categories']!);
      yearlyCategories.assignAll(result['yearlyCategories']!);
      isLoadingCategories.value = false;
    } catch (e) {
      categoriesError.value = e.toString();
      if (forceRefresh) {
        rethrow;
      }
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> fetchSubjectsForCategory(
    dynamic categoryId, {
    bool forceRefresh = false,
  }) async {
    final categoryKey = categoryId.toString();
    if (!forceRefresh) {
      if (_subjectsByCategory.containsKey(categoryKey) &&
          _subjectsByCategory[categoryKey]!.isNotEmpty) {
        return;
      }
      final hydrated = await _hydrateSubjectsFromCache(categoryKey);
      if (hydrated) return;
    }
    if (_subjectsLoading.contains(categoryKey)) return;

    _subjectsLoading.add(categoryKey);
    try {
      final subjects = await _repository.fetchSubjects(categoryKey);
      _subjectsByCategory[categoryKey] = subjects;
    } catch (e) {
      if (forceRefresh) {
        rethrow;
      }
      if (_subjectsByCategory.isEmpty) {
        AppUtils.showGetSnackbar('Library', 'Unable to load subjects: $e');
      }
    } finally {
      _subjectsLoading.remove(categoryKey);
    }
  }

  List<Chapter> getSubjectsForCategory(dynamic categoryId) {
    return _subjectsByCategory[categoryId.toString()] ?? const <Chapter>[];
  }

  bool isSubjectsLoading(dynamic categoryId) =>
      _subjectsLoading.contains(categoryId.toString());

  Future<void> fetchTopicsForSubject(
    dynamic subjectId, {
    bool forceRefresh = false,
    String? categoryType,
  }) async {
    final subjectKey = subjectId.toString();
    if (!forceRefresh) {
      if (_topicsBySubject.containsKey(subjectKey) &&
          _topicsBySubject[subjectKey]!.isNotEmpty) {
        return;
      }
      final hydrated = await _hydrateTopicsFromCache(subjectKey);
      if (hydrated) return;
    }
    if (_topicsLoading.contains(subjectKey)) return;

    _topicsLoading.add(subjectKey);
    try {
      final topics = await _repository.fetchTopics(
        subjectKey,
        type: categoryType,
      );
      _topicsBySubject[subjectKey] = topics;
      final controller = _hologramController;
      if (controller != null) {
        await controller.ensureTopicsLocalStatus(topics);
      }
    } catch (e) {
      if (forceRefresh) {
        // When force refresh, rethrow so caller can handle it
        rethrow;
      }
      if (_topicsBySubject.isEmpty) {
        AppUtils.showGetSnackbar('Library', 'Unable to load topics: $e');
      }
    } finally {
      _topicsLoading.remove(subjectKey);
    }
  }

  List<TopicItem> getTopicsForSubject(String subjectId) {
    return _topicsBySubject[subjectId] ?? const <TopicItem>[];
  }

  bool isTopicsLoading(String subjectId) {
    return _topicsLoading.contains(subjectId);
  }

  void selectCategory(CategoryModel category) {
    selectedCategory.value = category;
  }

  void clearSelectedCategory() {
    selectedCategory.value = null;
  }
}
