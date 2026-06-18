enum SyncPhase {
  cmsApis,
  profile,
  categories,
  subjects,
  topics,
  media,
  uploading,
  idle,
}

enum CategorySyncStatus {
  notStarted,
  syncing,
  completed,
  error,
  cancelled,
}

class SyncProgress {
  final SyncPhase currentPhase;
  final int totalItems;
  final int completedItems;
  final double percentage;
  final String? errorMessage;
  final String? currentItemName;

  SyncProgress({
    required this.currentPhase,
    required this.totalItems,
    required this.completedItems,
    this.errorMessage,
    this.currentItemName,
  }) : percentage = totalItems > 0 ? (completedItems / totalItems).clamp(0.0, 1.0) : 0.0;

  SyncProgress copyWith({
    SyncPhase? currentPhase,
    int? totalItems,
    int? completedItems,
    String? errorMessage,
    String? currentItemName,
  }) {
    return SyncProgress(
      currentPhase: currentPhase ?? this.currentPhase,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      errorMessage: errorMessage ?? this.errorMessage,
      currentItemName: currentItemName ?? this.currentItemName,
    );
  }

  String get phaseName {
    switch (currentPhase) {
      case SyncPhase.cmsApis:
        return 'Syncing CMS Content';
      case SyncPhase.profile:
        return 'Syncing Profile';
      case SyncPhase.categories:
        return 'Syncing Categories';
      case SyncPhase.subjects:
        return 'Syncing Subjects';
      case SyncPhase.topics:
        return 'Syncing Topics';
      case SyncPhase.media:
        return 'Downloading Media';
      case SyncPhase.uploading:
        return 'Uploading to Hologram';
      case SyncPhase.idle:
        return 'Idle';
    }
  }
}

