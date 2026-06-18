class CacheKeys {
  CacheKeys._();

  static const String token = 'TOKEN';
  static const String refreshToken = 'REFRESH_TOKEN';

  // Content cache keys
  static const String aboutUsContent = 'ABOUT_US_CONTENT';
  static const String contactUsContent = 'CONTACT_US_CONTENT';
  static const String privacyPolicyContent = 'PRIVACY_POLICY_CONTENT';
  static const String termsContent = 'TERMS_CONTENT';
  static const String whyChooseContent = 'WHY_CHOOSE_CONTENT';

  // Library cache keys
  static const String libraryCategories = 'LIBRARY_CATEGORIES';
  static String librarySubjects(dynamic categoryId) =>
      'LIBRARY_SUBJECTS_$categoryId';
  static String libraryTopics(dynamic subjectId) => 'LIBRARY_TOPICS_$subjectId';

  // Profile cache key
  static const String profile = 'PROFILE';

  // Sync metadata (stored in Hive via ApiCacheManager)
  static const String syncMeta = 'SYNC_META';
  static const String syncedCategories = 'SYNCED_CATEGORIES';

  // Notifications
  static const String notificationCache = 'NOTIFICATION_CACHE';
}
