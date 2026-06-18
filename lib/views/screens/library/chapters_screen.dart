import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/controllers/hologram_controller.dart';
import 'package:vizlearn/controllers/library_controller.dart';
import 'package:vizlearn/controllers/sync_controller.dart';
import 'package:vizlearn/data/models/library_model.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import 'package:vizlearn/views/widgets/gradient_divider.dart';
import 'package:vizlearn/views/widgets/custom_loader.dart';

import 'controllers/chapter_controller.dart';
import 'crop_topic_screen.dart';

enum MediaState {
  notDownloadedNotUploaded, // Case 1: Red
  notDownloadedUploaded, // Case 2: Yellow
  downloadedNotUploaded, // Case 3: White
  downloadedUploaded, // Case 4: Green
}

class ChaptersScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String? categoryType;

  const ChaptersScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryType,
  });

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final LibraryController libraryController = Get.find<LibraryController>();
  final ChapterController chapterController = Get.find<ChapterController>();
  final HologramController hologramController = Get.find<HologramController>();
  SyncController? _syncController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SyncController>()) {
      _syncController = Get.find<SyncController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomWrapper(
      child: Column(
        children: [
          CustomAppBar(title: widget.categoryName),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Check if category is fully synced
    if (_syncController != null) {
      return FutureBuilder<bool>(
        future: _syncController!.isCategoryFullySynced(
          widget.categoryId,
          categoryType: widget.categoryType,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader();
          }

          final isFullySynced = snapshot.data ?? false;

          if (!isFullySynced) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomLoader(),
                  16.hS,
                  Text(
                    'Syncing category data...',
                    style: AppFont.w700.s14.copyWith(color: AppColors.white),
                    textAlign: TextAlign.center,
                  ),
                  8.hS,
                  Text(
                    'Please wait while we download all content for this category.',
                    style: AppFont.w400.s12.copyWith(
                      color: AppColors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return _buildContent();
        },
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    final categoryKey = widget.categoryType == 'yearly'
        ? '${widget.categoryId}_yearly'
        : '${widget.categoryId}';
    final subjects = libraryController.getSubjectsForCategory(categoryKey);
    final isLoading = libraryController.isSubjectsLoading(categoryKey);

    if (isLoading && subjects.isEmpty) {
      return const CustomLoader();
    }

    if (subjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects available for this category yet.',
          style: AppFont.w700.s14.copyWith(color: AppColors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        children: [
          for (int i = 0; i < subjects.length; i++) ...[
            _buildSubjectItem(subjects[i]),
            if (i < subjects.length - 1) const GradientDivider(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectItem(Chapter subject) {
    final topics = libraryController.getTopicsForSubject(subject.id);
    final isTopicsLoading = libraryController.isTopicsLoading(subject.id);

    return Obx(() {
      final isExpanded = chapterController.isChapterExpanded(subject.id);
      return Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Toggle expansion. We also try to fetch topics if they're not loaded.
              chapterController.toggleChapter(subject.id);
              if (!chapterController.isChapterExpanded(subject.id)) return;
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: AppSizes.md,
              ).copyWith(bottom: isExpanded ? 0 : AppSizes.md),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: CustomImageView(
                      key: ValueKey(isExpanded),
                      imagePath: isExpanded
                          ? Assets.icons.folderOpen.path
                          : Assets.icons.folder.path,
                      height: 40,
                      width: 40,
                    ),
                  ),
                  12.wS,
                  Expanded(
                    child: Text(
                      subject.name,
                      style: AppFont.w700.s16.copyWith(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: [
                      if (isTopicsLoading && topics.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CustomLoader(size: 32),
                        )
                      else if (topics.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32, top: 16),
                          child: Text(
                            'Topics coming soon',
                            style: AppFont.w500.s14.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        )
                      else
                        for (int i = 0; i < topics.length; i++) ...[
                          _buildTopicItem(topics[i]),
                          if (i < topics.length - 1) const GradientDivider(),
                          if (i == topics.length - 1)
                            const SizedBox(height: 16),
                        ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }

  Widget _buildTopicItem(TopicItem topic) {
    return Obx(() {
      final status = hologramController.mediaStatusOf(topic.id);
      final localPath = status.localPath;
      final hasLocalMedia = localPath != null && localPath.isNotEmpty;
      final hasVideoUrl = topic.videoUrl?.isNotEmpty ?? false;
      final hasImageOnly =
          !hasVideoUrl && (topic.imageUrl?.isNotEmpty ?? false);
      final hasMedia = hasVideoUrl || hasImageOnly;
      final isUploaded = status.isUploaded;

      // Determine the 4 states
      // Case 1: Not downloaded, not uploaded - Red border
      // Case 2: Not downloaded, uploaded - Yellow border
      // Case 3: Downloaded, not uploaded - White border
      // Case 4: Downloaded, uploaded - Green border
      final mediaState = _getMediaState(hasLocalMedia, isUploaded, hasMedia);

      String? previewImagePath;
      if (hasVideoUrl) {
        previewImagePath = (topic.thumbUrl?.isNotEmpty ?? false)
            ? topic.localImagePath ?? topic.thumbUrl
            : (topic.imageUrl?.isNotEmpty ?? false
                  ? topic.localImagePath ?? topic.imageUrl
                  : null);
      } else if (hasImageOnly) {
        previewImagePath = topic.localImagePath ?? topic.imageUrl;
      }

      Widget previewWidget;
      if (previewImagePath?.isNotEmpty == true) {
        previewWidget = _TopicPreview(imagePath: previewImagePath!);
      } else if (hasVideoUrl) {
        previewWidget = _TopicStatusIconWidget(
          imagePath: Assets.icons.video.path,
        );
      } else {
        previewWidget = _TopicStatusIconWidget(
          imagePath: Assets.icons.invalid.path,
        );
      }

      final isCropping = status.isCropping;

      return AbsorbPointer(
        absorbing: isCropping,
        child: Opacity(
          opacity: isCropping ? 0.7 : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: AppSizes.sm,
            ).copyWith(left: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleTopicRowTap(
                      topic,
                      mediaState,
                      hasVideoUrl,
                      hasImageOnly,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            topic.topicName,
                            style: AppFont.w700.s16.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        8.wS,
                        // Show sync button for cases 1, 2, 3 (left side of image)
                        if (mediaState != MediaState.downloadedUploaded ||
                            isCropping)
                          _SyncButton(
                            topic: topic,
                            mediaState: mediaState,
                            hasVideoUrl: hasVideoUrl,
                            hasImageOnly: hasImageOnly,
                            onSync: () => _handleSync(
                              topic,
                              mediaState,
                              hasVideoUrl,
                              hasImageOnly,
                            ),
                          ),
                        if (mediaState != MediaState.downloadedUploaded ||
                            isCropping)
                          8.wS,
                        GestureDetector(
                          onTap: () => _handleImageTap(
                            topic,
                            mediaState,
                            hasVideoUrl,
                            hasImageOnly,
                          ),
                          child: previewWidget,
                        ),
                      ],
                    ),
                  ),
                ),
                // Show menu button for case 2 (uploaded but not downloaded) and case 4 (downloaded and uploaded)
                if (isUploaded && hologramController.isWebSocketConnected.value)
                  4.wS,
                if (isUploaded && hologramController.isWebSocketConnected.value)
                  SizedBox(
                    width: 28,
                    height: 36,
                    child: _TopicMenuButton(
                      topic: topic,
                      canCrop: (hasImageOnly || hasVideoUrl) && hasLocalMedia,
                      canReset: localPath?.contains('_crop') ?? false,
                      onDelete: () => _handleTopicDelete(topic),
                      onCrop: () =>
                          _handleTopicCrop(topic, hasVideoUrl, hasImageOnly),
                      onReset: () => _handleTopicReset(topic),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  MediaState _getMediaState(
    bool hasLocalMedia,
    bool isUploaded,
    bool hasMedia,
  ) {
    if (!hasMedia) {
      return MediaState.notDownloadedNotUploaded;
    }
    if (!hasLocalMedia && !isUploaded) {
      return MediaState.notDownloadedNotUploaded; // Case 1: Red
    }
    if (!hasLocalMedia && isUploaded) {
      return MediaState.notDownloadedUploaded; // Case 2: Yellow
    }
    if (hasLocalMedia && !isUploaded) {
      return MediaState.downloadedNotUploaded; // Case 3: White
    }
    return MediaState.downloadedUploaded; // Case 4: Green
  }

  void _handleSync(
    TopicItem topic,
    MediaState state,
    bool hasVideo,
    bool hasImage,
  ) async {
    try {
      switch (state) {
        case MediaState.notDownloadedNotUploaded:
          // Case 1: Download and upload
          await hologramController.syncCase1DownloadAndUpload(topic);
          break;
        case MediaState.notDownloadedUploaded:
          // Case 2: Download only
          await hologramController.syncCase2Download(topic);
          break;
        case MediaState.downloadedNotUploaded:
          // Case 3: Upload only
          await hologramController.syncCase3Upload(topic);
          break;
        case MediaState.downloadedUploaded:
          // Case 4: No sync needed
          break;
      }
    } catch (e) {
      // Don't show snackbar - sync button will remain visible
    }
  }

  void _handleTopicRowTap(
    TopicItem topic,
    MediaState state,
    bool hasVideo,
    bool hasImage,
  ) {
    switch (state) {
      case MediaState.notDownloadedNotUploaded:
        // Case 1: Click entire row to download
        _handleDownloadTap(topic, hasVideo, hasImage);
        break;
      case MediaState.notDownloadedUploaded:
        // Case 2: Click rest of row (not image) to play on hologram
        _handlePlayOnHologram(topic);
        break;
      case MediaState.downloadedNotUploaded:
        // Case 3: Click entire row to upload
        _handleUploadToHologram(topic, hasVideo, hasImage);
        break;
      case MediaState.downloadedUploaded:
        // Case 4: Click anywhere to play
        _handlePlayOnHologram(topic);
        break;
    }
  }

  void _handleImageTap(
    TopicItem topic,
    MediaState state,
    bool hasVideo,
    bool hasImage,
  ) {
    switch (state) {
      case MediaState.notDownloadedNotUploaded:
        // Case 1: Click image also downloads (same as row)
        _handleDownloadTap(topic, hasVideo, hasImage);
        break;
      case MediaState.notDownloadedUploaded:
        // Case 2: Click image to download
        _handleDownloadTap(topic, hasVideo, hasImage);
        break;
      case MediaState.downloadedNotUploaded:
        // Case 3: Click image also uploads (same as row)
        _handleUploadToHologram(topic, hasVideo, hasImage);
        break;
      case MediaState.downloadedUploaded:
        // Case 4: Click image to play (same as row)
        _handlePlayOnHologram(topic);
        break;
    }
  }

  void _handlePlayOnHologram(TopicItem topic) async {
    // Use the existing handleTopicTap which handles play logic
    await hologramController.handleTopicTap(topic);
  }

  void _handleUploadToHologram(
    TopicItem topic,
    bool hasVideo,
    bool hasImage,
  ) async {
    // Use handleTopicTap which will upload if not uploaded and connected
    await hologramController.handleTopicTap(topic);
  }

  void _handleDownloadTap(TopicItem topic, bool hasVideo, bool hasImage) async {
    try {
      if (hasVideo) {
        await hologramController.downloadTopicVideoLocally(topic);
      } else if (hasImage) {
        await hologramController.downloadTopicImageLocally(topic);
      }
      AppUtils.showGetSnackbar('Success', 'Media downloaded successfully');
    } catch (e) {
      AppUtils.showGetSnackbar('Download Failed', e.toString());
    }
  }

  void _handleTopicDelete(TopicItem topic) {
    hologramController.deleteTopicMedia(topic);
  }

  void _handleTopicCrop(TopicItem topic, bool hasVideo, bool hasImage) {
    // Allow cropping for both image only topics and video topics if they have local media.
    // Logic: hasImage && !hasVideo -> Image crop
    //        hasVideo -> Video crop

    // Check if media is downloaded
    final status = hologramController.mediaStatusOf(topic.id);
    if (status.localPath == null || status.localPath!.isEmpty) {
      AppUtils.showGetSnackbar(
        'Crop Topic',
        'Please download the media first.',
      );
      return;
    }

    // Determine preview image
    final preview = _resolvePreviewImage(topic, hasVideo, hasImage);
    if (preview == null || preview.isEmpty) {
      AppUtils.showGetSnackbar('Crop Topic', 'No preview available to crop.');
      return;
    }

    Get.to(
      () => CropTopicScreen(
        topic: topic,
        hasVideo: hasVideo,
        hasImage: hasImage,
        previewImagePath: preview,
      ),
    );
  }

  String? _resolvePreviewImage(TopicItem topic, bool hasVideo, bool hasImage) {
    if (hasVideo) {
      // For videos, favor the local thumb, then online thumb, then fallback to image
      if (topic.thumbUrl?.isNotEmpty ?? false) {
        return topic.localImagePath ?? topic.thumbUrl;
      }
      if (topic.imageUrl?.isNotEmpty ?? false) {
        return topic.localImagePath ?? topic.imageUrl;
      }
    } else if (hasImage) {
      if (topic.imageUrl?.isNotEmpty ?? false) {
        return topic.localImagePath ?? topic.imageUrl;
      }
    }
    return null;
  }

  void _handleTopicReset(TopicItem topic) async {
    try {
      await hologramController.resetTopicMedia(topic);
      AppUtils.showGetSnackbar(
        'Success',
        'Media reset to original successfully.',
      );
    } catch (e) {
      AppUtils.showGetSnackbar('Reset Failed', e.toString());
    }
  }
}

class _TopicPreview extends StatelessWidget {
  final String imagePath;

  const _TopicPreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomImageView(
          imagePath: imagePath,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _TopicStatusIconWidget extends StatelessWidget {
  final String? imagePath;

  const _TopicStatusIconWidget({this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: CustomImageView(
            imagePath: imagePath ?? Assets.icons.invalid.path,
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final TopicItem topic;
  final MediaState mediaState;
  final bool hasVideoUrl;
  final bool hasImageOnly;
  final VoidCallback onSync;

  const _SyncButton({
    required this.topic,
    required this.mediaState,
    required this.hasVideoUrl,
    required this.hasImageOnly,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final hologramController = Get.find<HologramController>();

    return Obx(() {
      final status = hologramController.mediaStatusOf(topic.id);
      final isDownloading = status.isDownloading;
      final isUploading = status.isUploading;
      final isCropping = status.isCropping;
      final isSyncing = isDownloading || isUploading;
      final progress = isDownloading
          ? status.downloadProgress
          : (isUploading ? status.uploadProgress : 0.0);

      if (isCropping) {
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      }

      if (isSyncing) {
        // Show loader with percentage
        return SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                backgroundColor: AppColors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDownloading ? Colors.red : Colors.green,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppFont.w700.s8.copyWith(color: AppColors.white),
              ),
            ],
          ),
        );
      } else {
        // Show sync icon
        return GestureDetector(
          onTap: onSync,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sync, size: 16, color: AppColors.white),
          ),
        );
      }
    });
  }
}

class _TopicMenuButton extends StatefulWidget {
  final TopicItem topic;
  final VoidCallback onDelete;
  final VoidCallback onCrop;
  final VoidCallback onReset;
  final bool canCrop;
  final bool canReset;

  const _TopicMenuButton({
    required this.topic,
    required this.onDelete,
    required this.onCrop,
    required this.onReset,
    required this.canCrop,
    required this.canReset,
  });

  @override
  State<_TopicMenuButton> createState() => _TopicMenuButtonState();
}

class _TopicMenuButtonState extends State<_TopicMenuButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggleMenu() {
    if (_overlayEntry == null) {
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _buildOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          onTap: _toggleMenu,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                offset: Offset(-155 + size.width, -(20 - size.height) / 2),
                child: _GlassMenu(
                  onDelete: () {
                    _toggleMenu();
                    widget.onDelete();
                  },
                  onCrop: () {
                    _toggleMenu();
                    widget.onCrop();
                  },
                  canCrop: widget.canCrop,
                  onReset: () {
                    _toggleMenu();
                    widget.onReset();
                  },
                  canReset: widget.canReset,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: const Icon(Icons.more_vert, color: AppColors.white, size: 18),
        padding: EdgeInsets.zero,
        splashRadius: 18,
        onPressed: _toggleMenu,
      ),
    );
  }
}

class _GlassMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onCrop;
  final VoidCallback onReset;
  final bool canCrop;
  final bool canReset;

  const _GlassMenu({
    required this.onDelete,
    required this.onCrop,
    required this.onReset,
    required this.canCrop,
    required this.canReset,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 124,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuRow(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: onDelete,
              ),
              if (canCrop) ...[
                const GradientDivider(height: 1, colors: _whiteGradientColors),
                _MenuRow(icon: Icons.crop, label: 'Crop', onTap: onCrop),
              ],
              if (canReset) ...[
                const GradientDivider(height: 1, colors: _whiteGradientColors),
                _MenuRow(icon: Icons.restore, label: 'Reset', onTap: onReset),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.md2,
            vertical: AppSizes.sm2,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              4.wS,
              Text(
                label,
                style: AppFont.w700.s16.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<Color> _whiteGradientColors = [
  Color(0x00FFFFFF),
  Color(0x40FFFFFF),
  Color(0xFFFFFFFF),
  Color(0x40FFFFFF),
  Color(0x00FFFFFF),
];
