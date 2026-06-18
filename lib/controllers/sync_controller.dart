import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../data/models/library_model.dart';
import '../data/models/sync_progress_model.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/side_menu/cms_repository.dart';
import '../data/repositories/side_menu/contact_us_repository.dart';
import '../injectors/configure_dependencies.dart';
import '../services/api_service.dart';
import '../utils/cache/api_cache_manager.dart';
import '../utils/cache/cache_keys.dart';
import '../utils/cache/secure_local_storage.dart';
import '../utils/enums.dart';
import 'hologram_controller.dart';
import 'library_controller.dart';
import 'notification_controller.dart';
import '../utils/api/api_exception.dart';

class SyncController extends GetxController {
  SyncController({
    required this.apiService,
    required this.cacheManager,
    required this.profileRepository,
    required this.cmsRepository,
    required this.contactUsRepository,
  });

  final APIService apiService;
  final ApiCacheManager cacheManager;
  final ProfileRepository profileRepository;
  final CMSRepository cmsRepository;
  final ContactUsRepository contactUsRepository;

  // Sync meta fields stored under CacheKeys.syncMeta in ApiCacheManager (Hive)
  static const String _firstSyncField = 'firstSyncCompleted';
  static const String _inProgressField = 'inProgress';

  // Sync state
  final Rx<SyncPhase> currentPhase = SyncPhase.idle.obs;
  final Rx<SyncProgress> syncProgress = SyncProgress(
    currentPhase: SyncPhase.idle,
    totalItems: 0,
    completedItems: 0,
  ).obs;
  final RxBool _isSyncingRx = false.obs;

  // Cumulative progress tracking (single 0-100 bar)
  int _totalWork = 0;
  int _completedWork = 0;

  // Category sync status tracking (using string keys like '1' or '1_yearly')
  final RxMap<String, CategorySyncStatus> categorySyncStatus =
      <String, CategorySyncStatus>{}.obs;

  // Cancellation flag
  bool _isCancelled = false;
  bool _isSyncing = false;

  @override
  void onInit() {
    super.onInit();
    _loadSyncState();
    _restoreCategoryStatuses();
  }

  Future<void> _loadSyncState() async {
    try {
      final meta =
          await cacheManager.readMap(CacheKeys.syncMeta) ?? <String, dynamic>{};
      final isInProgress = meta[_inProgressField] == true;
      if (isInProgress) {
        // Reset if app was closed during sync
        meta[_inProgressField] = false;
        await cacheManager.writeMap(CacheKeys.syncMeta, meta);
      }
    } catch (_) {
      // ignore meta restore errors
    }
  }

  // Check if first-time sync is needed
  Future<bool> isFirstTimeSync() async {
    try {
      final meta =
          await cacheManager.readMap(CacheKeys.syncMeta) ?? <String, dynamic>{};
      final completed = meta[_firstSyncField] == true;
      return !completed;
    } catch (_) {
      return true;
    }
  }

  // Mark first sync as complete
  Future<void> markFirstSyncComplete() async {
    try {
      final meta =
          await cacheManager.readMap(CacheKeys.syncMeta) ?? <String, dynamic>{};
      meta[_firstSyncField] = true;
      meta[_inProgressField] = false;
      await cacheManager.writeMap(CacheKeys.syncMeta, meta);
    } catch (_) {
      // ignore failures, will just resync next time
    }
  }

  // Get overall progress percentage
  double getOverallProgress() {
    return syncProgress.value.percentage;
  }

  // Get current phase name
  String getCurrentPhase() {
    return syncProgress.value.phaseName;
  }

  // Check if sync is in progress
  bool get isSyncing => _isSyncingRx.value;

  // Cancel sync
  Future<void> cancelSync() async {
    _isCancelled = true;
    _isSyncing = false;
    _isSyncingRx.value = false;
    currentPhase.value = SyncPhase.idle;

    try {
      final meta =
          await cacheManager.readMap(CacheKeys.syncMeta) ?? <String, dynamic>{};
      meta[_inProgressField] = false;
      await cacheManager.writeMap(CacheKeys.syncMeta, meta);
    } catch (_) {
      // ignore
    }
  }

  // Reset cancellation flag
  void _resetCancellation() {
    _isCancelled = false;
  }

  /// On app startup, restore category sync statuses from Hive so that
  /// UI (home cards, chapters screen) reflects the real state even after restart.
  Future<void> _restoreCategoryStatuses() async {
    try {
      final stored = await cacheManager.readMap(CacheKeys.syncedCategories);
      if (stored == null) return;
      final idsDynamic = stored['ids'] as List<dynamic>? ?? const [];
      for (final raw in idsDynamic) {
        final key = raw.toString();
        categorySyncStatus[key] = CategorySyncStatus.completed;
      }
    } catch (_) {
      // Best-effort restore; ignore errors here.
    }
  }

  Future<void> _persistCategoryStatus(
    String categoryKey,
    CategorySyncStatus status,
  ) async {
    final existing =
        await cacheManager.readMap(CacheKeys.syncedCategories) ??
        <String, dynamic>{};
    final idsDynamic = existing['ids'] as List<dynamic>? ?? const [];
    final ids = idsDynamic.map((e) => e.toString()).toSet();

    if (status == CategorySyncStatus.completed) {
      ids.add(categoryKey);
    } else {
      ids.remove(categoryKey);
    }

    await cacheManager.writeMap(CacheKeys.syncedCategories, {
      'ids': ids.toList(),
    });
  }

  void _resetProgress() {
    _totalWork = 0;
    _completedWork = 0;
    _updateProgress(
      phase: SyncPhase.idle,
      currentItemName: null,
      errorMessage: null,
    );
  }

  void _addWork(int count) {
    if (count <= 0) return;
    _totalWork += count;
    _updateProgress(
      phase: currentPhase.value,
      currentItemName: syncProgress.value.currentItemName,
    );
  }

  void _completeWork({int count = 1, String? currentItemName}) {
    _completedWork += count;
    if (_completedWork > _totalWork) _completedWork = _totalWork;
    _updateProgress(
      phase: currentPhase.value,
      currentItemName: currentItemName ?? syncProgress.value.currentItemName,
    );
  }

  // Update progress helper (single cumulative bar)
  void _updateProgress({
    required SyncPhase phase,
    String? currentItemName,
    String? errorMessage,
  }) {
    final total = _totalWork;
    final completed = _completedWork.clamp(0, total);
    syncProgress.value = SyncProgress(
      currentPhase: phase,
      totalItems: total,
      completedItems: completed,
      currentItemName: currentItemName,
      errorMessage: errorMessage,
    );
    currentPhase.value = phase;
  }

  // Phase 2.1: Sync CMS APIs
  Future<bool> syncCmsApis() async {
    if (_isCancelled) return false;

    _updateProgress(phase: SyncPhase.cmsApis);

    final cmsApis = [
      (CmsContentType.aboutUs, CacheKeys.aboutUsContent),
      (CmsContentType.privacyPolicy, CacheKeys.privacyPolicyContent),
      (CmsContentType.termsAndConditions, CacheKeys.termsContent),
      (CmsContentType.whyChooseUs, CacheKeys.whyChooseContent),
      // contact us handled separately
    ];

    _addWork(cmsApis.length + 1); // include contact us

    for (final (type, cacheKey) in cmsApis) {
      if (_isCancelled) return false;
      try {
        final response = await cmsRepository.fetchContent(type);
        await cacheManager.writeMap(cacheKey, response);
        _completeWork(currentItemName: type.toString());
      } catch (e) {
        if (e is NoInternetException) return false;
        _completeWork(currentItemName: '${type.toString()} (Error)');
      }
    }

    // Sync contact us separately
    if (_isCancelled) return false;
    try {
      final response = await contactUsRepository.fetchContactUs();
      await cacheManager.writeMap(CacheKeys.contactUsContent, response);
      _completeWork(currentItemName: 'Contact Us');
    } catch (e) {
      if (e is NoInternetException) return false;
      _completeWork(currentItemName: 'Contact Us (Error)');
    }
    return true;
  }

  // Phase 2.2: Sync Profile and Categories (Post-Login)
  Future<bool> syncProfileAndCategories() async {
    if (_isCancelled) return false;

    _updateProgress(phase: SyncPhase.profile);
    _addWork(3); // profile + categories + notifications

    // Sync Profile
    if (_isCancelled) return false;
    try {
      final profileResponse = await profileRepository.getProfile();
      await cacheManager.writeMap(CacheKeys.profile, profileResponse.toJson());
      _completeWork(currentItemName: 'Profile');
    } catch (e) {
      if (e is NoInternetException) return false;
      _completeWork(currentItemName: 'Profile (Error)');
    }

    // Sync Categories using LibraryController
    if (_isCancelled) return false;
    try {
      if (!Get.isRegistered<LibraryController>()) {
        throw Exception('LibraryController not registered');
      }
      final libraryController = Get.find<LibraryController>();
      await libraryController.fetchCategories(forceRefresh: true);
      _updateProgress(
        phase: SyncPhase.categories,
        currentItemName: 'Categories',
      );
      _completeWork(currentItemName: 'Categories');
    } catch (e) {
      if (e is NoInternetException) return false;
      _completeWork(currentItemName: 'Categories (Error)');
    }

    // Sync Notifications using NotificationController
    if (_isCancelled) return false;
    try {
      if (Get.isRegistered<NotificationController>()) {
        final notificationController = Get.find<NotificationController>();
        await notificationController.fetchNotifications(forceRefresh: true);
        _completeWork(currentItemName: 'Notifications');
      } else {
        // Skip if NotificationController is not registered
        _completeWork(currentItemName: 'Notifications (Skipped)');
      }
    } catch (e) {
      if (e is NoInternetException) return false;
      _completeWork(currentItemName: 'Notifications (Error)');
    }
    return true;
  }

  // Phase 2.4: Sync Media Files for a specific category
  Future<bool> syncMediaFilesForCategory(
    String categoryKey,
    List<TopicItem> topics,
  ) async {
    if (_isCancelled) return false;

    // Ensure we have a hologram controller to handle local media download
    // (device connection is not required for local downloads).
    final hologramController = Get.isRegistered<HologramController>()
        ? Get.find<HologramController>()
        : Get.put(HologramController());

    // Filter topics that have media
    final topicsWithMedia = topics.where((topic) {
      return (topic.videoUrl?.isNotEmpty ?? false) ||
          (topic.imageUrl?.isNotEmpty ?? false);
    }).toList();

    int totalMediaFiles = 0;
    for (final topic in topicsWithMedia) {
      if (topic.videoUrl?.isNotEmpty ?? false) totalMediaFiles++;
      if (topic.imageUrl?.isNotEmpty ?? false) totalMediaFiles++;
    }

    _addWork(totalMediaFiles);
    _updateProgress(phase: SyncPhase.media);

    for (final topic in topicsWithMedia) {
      if (_isCancelled) return false;

      // Check if media exists locally
      final status = hologramController.mediaStatusOf(topic.id);
      final hasLocalMedia =
          status.localPath != null && status.localPath!.isNotEmpty;

      if (!hasLocalMedia) {
        // Download video if exists
        if (topic.videoUrl?.isNotEmpty ?? false) {
          if (_isCancelled) return false;
          try {
            await hologramController.downloadTopicVideoLocally(topic);
            _completeWork(currentItemName: '${topic.topicName} (Video)');
          } catch (e) {
            if (e is NoInternetException) return false;
            _completeWork(currentItemName: '${topic.topicName} (Video Error)');
          }
        }

        // Download image if exists
        if (topic.imageUrl?.isNotEmpty ?? false) {
          if (_isCancelled) return false;
          try {
            await hologramController.downloadTopicImageLocally(topic);
            _completeWork(currentItemName: '${topic.topicName} (Image)');
          } catch (e) {
            if (e is NoInternetException) return false;
            _completeWork(currentItemName: '${topic.topicName} (Image Error)');
          }
        }
      } else {
        // Media already exists, skip but count as completed
        int mediaCount = 0;
        if (topic.videoUrl?.isNotEmpty ?? false) mediaCount++;
        if (topic.imageUrl?.isNotEmpty ?? false) mediaCount++;
        _completeWork(count: mediaCount, currentItemName: '${topic.topicName}');
      }
    }

    // Mark this category as completed immediately after its media is synced
    categorySyncStatus[categoryKey] = CategorySyncStatus.completed;
    await _persistCategoryStatus(categoryKey, CategorySyncStatus.completed);
    return true;
  }

  Future<void> _cleanupSyncState() async {
    _isSyncing = false;
    _isSyncingRx.value = false;
    try {
      final meta =
          await cacheManager.readMap(CacheKeys.syncMeta) ?? <String, dynamic>{};
      meta[_inProgressField] = false;
      await cacheManager.writeMap(CacheKeys.syncMeta, meta);
    } catch (_) {}
  }

  // Main sync all method
  Future<void> syncAll({
    bool showDialog = true,
    VoidCallback? onBlockingComplete,
  }) async {
    if (_isSyncing) {
      return; // Already syncing
    }

    _isSyncing = true;
    _isSyncingRx.value = true;
    _resetCancellation();
    _resetProgress();

    try {
      final meta =
          await cacheManager.readMap(CacheKeys.syncMeta) ?? <String, dynamic>{};
      meta[_inProgressField] = true;
      await cacheManager.writeMap(CacheKeys.syncMeta, meta);
    } catch (_) {}

    try {
      // Phase 1: CMS APIs (always sync)
      if (!await syncCmsApis()) {
        await _cleanupSyncState();
        return;
      }

      // Phase 2: Profile and Categories (if logged in)
      final token = await getIt<SecureLocalStorage>().load(
        key: CacheKeys.token,
      );
      if (token.isNotEmpty) {
        if (!await syncProfileAndCategories()) {
          await _cleanupSyncState();
          return;
        }

        // Close blocking dialog after profile & categories
        onBlockingComplete?.call();

        // Phase 3 & 4: Process each category individually (Subjects, Topics, and Media)
        // This allows us to mark each category as completed as soon as its data is synced
        // Ensure LibraryController is registered
        if (!Get.isRegistered<LibraryController>()) {
          throw Exception('LibraryController not registered');
        }
        final libraryController = Get.find<LibraryController>();

        // Get categories from LibraryController
        var categories = libraryController.categories;
        var yearlyCategories = libraryController.yearlyCategories;
        if (categories.isEmpty && yearlyCategories.isEmpty) {
          // Fetch categories first if not cached
          await libraryController.fetchCategories(forceRefresh: true);
          categories = libraryController.categories;
          yearlyCategories = libraryController.yearlyCategories;
        }

        // Process each category individually
        // Update phase to subjects
        _updateProgress(phase: SyncPhase.subjects);

        final allPossibleCategories = [
          ...categories.map((c) => (c, 'normal')),
          ...yearlyCategories.map((c) => (c, 'yearly')),
        ];

        for (final (category, typeStr) in allPossibleCategories) {
          if (_isCancelled) {
            await _cleanupSyncState();
            return;
          }

          final categoryKey = typeStr == 'yearly'
              ? '${category.id}_yearly'
              : '${category.id}';

          // Mark category as syncing
          categorySyncStatus[categoryKey] = CategorySyncStatus.syncing;

          try {
            // Step 1: Fetch subjects for this category
            await libraryController.fetchSubjectsForCategory(
              categoryKey,
              forceRefresh: true,
            );
            final subjects = libraryController.getSubjectsForCategory(
              categoryKey,
            );
            _addWork(subjects.length); // Add subjects to work count

            // Step 2: Fetch topics for each subject
            // Update phase to topics
            _updateProgress(phase: SyncPhase.topics);

            final allTopicsForCategory = <TopicItem>[];
            for (final subject in subjects) {
              if (_isCancelled) break;

              try {
                await libraryController.fetchTopicsForSubject(
                  subject.id,
                  forceRefresh: true,
                  categoryType: typeStr == 'yearly' ? 'yearly' : null,
                );
                final topics = libraryController.getTopicsForSubject(
                  subject.id,
                );
                allTopicsForCategory.addAll(topics);
                _addWork(topics.length); // Add topics to work count
                _completeWork(currentItemName: subject.name); // Subject done
              } catch (e) {
                if (e is NoInternetException) {
                  await _cleanupSyncState();
                  return;
                }
                // For other errors, skip this subject's topics and continue
                _completeWork(currentItemName: '${subject.name} (Error)');
              }
            }

            // Step 3: Sync media files for this category
            // This will mark the category as completed when done
            if (!await syncMediaFilesForCategory(
              categoryKey,
              allTopicsForCategory,
            )) {
              await _cleanupSyncState();
              return;
            }

            // Step 4: Warm up LibraryController cache for this category
            await libraryController.fetchSubjectsForCategory(
              categoryKey,
              forceRefresh: false,
            );
            final cachedSubjects = libraryController.getSubjectsForCategory(
              categoryKey,
            );
            for (final subject in cachedSubjects) {
              await libraryController.fetchTopicsForSubject(
                subject.id,
                forceRefresh: false,
                categoryType: typeStr == 'yearly' ? 'yearly' : null,
              );
            }
          } catch (e) {
            if (e is NoInternetException) {
              await _cleanupSyncState();
              return;
            }
            // For other category errors, log and move to next category
          }
        }

        // Warm up LibraryController caches so UI uses local data without rehitting APIs
        if (Get.isRegistered<LibraryController>()) {
          final libraryController = Get.find<LibraryController>();

          // Warm up normal categories
          for (final category in categories) {
            final categoryKey = '${category.id}';
            await libraryController.fetchSubjectsForCategory(
              categoryKey,
              forceRefresh: false,
            );
            final subjects = libraryController.getSubjectsForCategory(
              categoryKey,
            );
            for (final subject in subjects) {
              await libraryController.fetchTopicsForSubject(
                subject.id,
                forceRefresh: false,
              );
            }
          }

          // Warm up yearly categories
          for (final category in yearlyCategories) {
            final categoryKey = '${category.id}_yearly';
            await libraryController.fetchSubjectsForCategory(
              categoryKey,
              forceRefresh: false,
            );
            final subjects = libraryController.getSubjectsForCategory(
              categoryKey,
            );
            for (final subject in subjects) {
              await libraryController.fetchTopicsForSubject(
                subject.id,
                forceRefresh: false,
                categoryType: 'yearly',
              );
            }
          }
        }
      }

      // Mark sync as complete
      await markFirstSyncComplete();
      _isSyncing = false;
      _isSyncingRx.value = false;
    } catch (e) {
      _isSyncing = false;
      _isSyncingRx.value = false;
      try {
        final meta =
            await cacheManager.readMap(CacheKeys.syncMeta) ??
            <String, dynamic>{};
        meta[_inProgressField] = false;
        await cacheManager.writeMap(CacheKeys.syncMeta, meta);
      } catch (_) {}
      rethrow;
    }
  }

  // Sync single category
  Future<void> syncCategory(int categoryId, {String? categoryType}) async {
    if (_isSyncing) return;

    if (!Get.isRegistered<LibraryController>()) {
      throw Exception('LibraryController not registered');
    }
    final libraryController = Get.find<LibraryController>();

    _isSyncing = true;
    _isSyncingRx.value = true;
    _resetCancellation();

    bool isYearlySelection;
    if (categoryType != null) {
      isYearlySelection = categoryType == 'yearly';
    } else {
      final inNormal = libraryController.categories.any(
        (c) => c.id == categoryId,
      );
      final inYearly = libraryController.yearlyCategories.any(
        (c) => c.id == categoryId,
      );
      if (inNormal) {
        isYearlySelection = false;
      } else if (inYearly) {
        isYearlySelection = true;
      } else {
        isYearlySelection = false;
      }
    }

    final categoryKey = isYearlySelection
        ? '${categoryId}_yearly'
        : '$categoryId';
    final typeStr = isYearlySelection ? 'yearly' : null;

    categorySyncStatus[categoryKey] = CategorySyncStatus.syncing;

    try {
      // Fetch subjects for category using LibraryController
      await libraryController.fetchSubjectsForCategory(
        categoryKey,
        forceRefresh: true,
      );
      final subjects = libraryController.getSubjectsForCategory(categoryKey);

      // Fetch topics for each subject using LibraryController
      final allTopics = <TopicItem>[];

      for (final subject in subjects) {
        await libraryController.fetchTopicsForSubject(
          subject.id,
          forceRefresh: true,
          categoryType: typeStr,
        );
        final topics = libraryController.getTopicsForSubject(subject.id);
        allTopics.addAll(topics);
      }

      // Download media files
      final hologramController = Get.isRegistered<HologramController>()
          ? Get.find<HologramController>()
          : null;

      if (hologramController != null) {
        for (final topic in allTopics) {
          if (_isCancelled) break;

          final status = hologramController.mediaStatusOf(topic.id);
          final hasLocalMedia =
              status.localPath != null && status.localPath!.isNotEmpty;

          if (!hasLocalMedia) {
            if (topic.videoUrl?.isNotEmpty ?? false) {
              try {
                await hologramController.downloadTopicVideoLocally(topic);
              } catch (_) {
                // Continue on error
              }
            }
            if (topic.imageUrl?.isNotEmpty ?? false) {
              try {
                await hologramController.downloadTopicImageLocally(topic);
              } catch (_) {
                // Continue on error
              }
            }
          }
        }
      }

      categorySyncStatus[categoryKey] = CategorySyncStatus.completed;
      await _persistCategoryStatus(categoryKey, CategorySyncStatus.completed);
    } catch (e) {
      categorySyncStatus[categoryKey] = CategorySyncStatus.error;
    } finally {
      _isSyncing = false;
      _isSyncingRx.value = false;
    }
  }

  // Check if category is fully synced
  Future<bool> isCategoryFullySynced(
    int categoryId, {
    String? categoryType,
  }) async {
    // Determine the key based on available data in LibraryController
    if (!Get.isRegistered<LibraryController>()) {
      return false;
    }
    final libraryController = Get.find<LibraryController>();
    bool isYearlySelection;
    if (categoryType != null) {
      isYearlySelection = categoryType == 'yearly';
    } else {
      // If type not specified, try to detect.
      // If it exists in normal categories, assume normal.
      // Otherwise if it exists in yearly, assume yearly.
      final inNormal = libraryController.categories.any(
        (c) => c.id == categoryId,
      );
      final inYearly = libraryController.yearlyCategories.any(
        (c) => c.id == categoryId,
      );

      if (inNormal) {
        isYearlySelection = false;
      } else if (inYearly) {
        isYearlySelection = true;
      } else {
        isYearlySelection = false; // Default fallback
      }
    }

    final categoryKey = isYearlySelection
        ? '${categoryId}_yearly'
        : '$categoryId';
    final typeStr = isYearlySelection ? 'yearly' : null;

    final status = categorySyncStatus[categoryKey];
    if (status == CategorySyncStatus.completed) {
      return true;
    }

    // Try to hydrate from cache first
    await libraryController.fetchSubjectsForCategory(
      categoryKey,
      forceRefresh: false,
    );
    final subjects = libraryController.getSubjectsForCategory(categoryKey);
    if (subjects.isEmpty) return false;

    // Ensure hologram controller exists so we can read media status
    final hologramController = Get.isRegistered<HologramController>()
        ? Get.find<HologramController>()
        : Get.put(HologramController());

    for (final subject in subjects) {
      // Try to hydrate topics from cache first
      await libraryController.fetchTopicsForSubject(
        subject.id,
        forceRefresh: false,
        categoryType: typeStr,
      );
      final topics = libraryController.getTopicsForSubject(subject.id);
      if (topics.isEmpty) return false;

      // Check if all media files exist
      for (final topic in topics) {
        final status = hologramController.mediaStatusOf(topic.id);
        final hasLocalMedia =
            status.localPath != null && status.localPath!.isNotEmpty;

        final needsMedia =
            (topic.videoUrl?.isNotEmpty ?? false) ||
            (topic.imageUrl?.isNotEmpty ?? false);

        if (needsMedia && !hasLocalMedia) {
          return false;
        }
      }
    }

    return true;
  }
}
