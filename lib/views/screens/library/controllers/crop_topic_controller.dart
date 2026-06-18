import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show MatrixUtils;
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:vizlearn/controllers/hologram_controller.dart';
import 'package:vizlearn/data/models/library_model.dart';
import 'package:vizlearn/utils/app_utils.dart';
import 'package:vizlearn/utils/encryption/encryption_service.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:video_player/video_player.dart';

class CropTopicController extends GetxController {
  CropTopicController({
    required this.topic,
    required this.hasVideo,
    required this.hasImage,
    required this.previewImagePath,
  });

  final TopicItem topic;
  final bool hasVideo;
  final bool hasImage;
  final String previewImagePath;

  late final HologramController _hologramController;
  late final TransformationController _transformController;

  double? _viewportSide;
  final RxBool isUploading = false.obs;
  final RxBool isVideoInitialized = false.obs;
  VideoPlayerController? videoPlayerController;
  File? _tempVideoFile;

  TransformationController get transformController => _transformController;

  double? get viewportSide => _viewportSide;

  @override
  void onInit() {
    super.onInit();
    _hologramController = Get.find<HologramController>();
    _transformController = TransformationController();

    // Restore last crop transform if available
    final status = _hologramController.mediaStatusOf(topic.id);
    final matrix = status.cropMatrix;
    if (matrix != null && matrix.length == 16) {
      _transformController.value = Matrix4.fromList(matrix);
    }

    if (hasVideo) {
      _initializeVideoPreview();
    }
  }

  Future<void> _initializeVideoPreview() async {
    try {
      final status = _hologramController.mediaStatusOf(topic.id);
      final localPath = status.localPath;
      if (localPath == null || localPath.isEmpty) return;

      final originalFile = File(localPath);
      if (!await originalFile.exists()) return;

      final bool isEncrypted =
          localPath.endsWith('.encrypted') ||
          await EncryptionService.isFileEncrypted(localPath);

      String playbackPath = localPath;

      if (isEncrypted) {
        final bytes = await EncryptionService.decryptFileToBytes(localPath);
        final tempDir = await _hologramController.getTopicMediaDirectory();
        _tempVideoFile = File(
          p.join(tempDir.path, 'preview_decrypt_${topic.id}.mp4'),
        );
        await _tempVideoFile!.writeAsBytes(bytes);
        playbackPath = _tempVideoFile!.path;
      }

      videoPlayerController = VideoPlayerController.file(File(playbackPath));
      await videoPlayerController!.initialize();
      await videoPlayerController!.setLooping(true);
      await videoPlayerController!.play();
      isVideoInitialized.value = true;
    } catch (e) {
      log('Error initializing video preview: $e');
    }
  }

  @override
  void onClose() {
    videoPlayerController?.dispose();
    _transformController.dispose();
    if (_tempVideoFile != null && _tempVideoFile!.existsSync()) {
      _tempVideoFile!.deleteSync();
    }
    super.onClose();
  }

  void setViewportSide(double side) {
    _viewportSide = side;
  }

  void resetCrop() {
    _transformController.value = Matrix4.identity();
    _hologramController.clearTopicCropMatrix(topic.id);
  }

  Future<void> uploadToHologram() async {
    if (previewImagePath.isEmpty) {
      AppUtils.showGetSnackbar('Crop', 'No preview available to upload.');
      return;
    }

    if (isUploading.value) return; // Prevent multiple simultaneous uploads

    isUploading.value = true;

    try {
      // For pure image topics, try to physically crop the local image file
      // according to current crop circle; for videos we only use the visual crop.
      String? croppedPath;

      _hologramController.setTopicCroppingStatus(topic.id, true);
      try {
        if (hasImage && !hasVideo) {
          try {
            Get.back();
            croppedPath = await _createCroppedImageFile();
          } catch (e) {
            log(e.toString());
            AppUtils.showGetSnackbar(
              'Crop',
              'Failed to generate cropped image: $e',
            );
            return;
          }
        } else if (hasVideo) {
          try {
            Get.back();
            croppedPath = await _createCroppedVideoFile();
          } catch (e) {
            log(e.toString());
            AppUtils.showGetSnackbar(
              'Crop',
              'Failed to generate cropped video: $e',
            );
            return;
          }
        }
      } finally {
        _hologramController.setTopicCroppingStatus(topic.id, false);
      }

      // Persist current transform so next time we can restore same region.
      _hologramController.saveTopicCropMatrix(
        topic.id,
        _transformController.value.storage.toList(),
      );

      try {
        await _hologramController.replaceTopicMediaWithCrop(
          topic,
          hasVideo: hasVideo,
          hasImage: hasImage,
          overrideLocalPath: croppedPath,
        );

        // Wait a bit more to ensure status is updated
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if upload was successful before navigating back
        // Wait a bit for status to update after file list refresh
        await Future.delayed(const Duration(milliseconds: 1500));

        final status = _hologramController.mediaStatusOf(topic.id);
        String? successMessage;

        if (status.isUploaded) {
          successMessage = 'Cropped media uploaded to hologram.';
        } else {
          // If status not updated, wait a bit more and check again
          await Future.delayed(const Duration(milliseconds: 1000));
          final finalStatus = _hologramController.mediaStatusOf(topic.id);
          if (finalStatus.isUploaded) {
            successMessage = 'Cropped media uploaded to hologram.';
          } else {
            // Even if status check fails, navigate back after upload completes
            // The upload method already completed successfully
            successMessage = 'Upload completed. Status may update shortly.';
          }
        }
        AppUtils.showGetSnackbar('Success', successMessage);
      } catch (e) {
        // Don't navigate back on error
        // Show error message to user
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        AppUtils.showGetSnackbar('Upload Failed', errorMessage);
      }
    } finally {
      isUploading.value = false;
    }
  }

  Future<String> _createCroppedImageFile() async {
    // We need viewport size information to translate the crop circle to image space.
    final side = viewportSide;
    if (side == null) {
      throw Exception('Viewport not ready for cropping.');
    }

    // Ensure a local file exists for this topic.
    final localPath = await _hologramController.ensureLocalTopicMedia(topic);
    if (localPath == null || localPath.isEmpty) {
      throw Exception('Local image not found. Please download it first.');
    }

    final originalFile = File(localPath);
    if (!await originalFile.exists()) {
      throw Exception('Local image file missing on disk.');
    }

    // Check if file is encrypted and decrypt if necessary
    final bool isEncrypted =
        localPath.endsWith('.encrypted') ||
        await EncryptionService.isFileEncrypted(localPath);

    final Uint8List bytes;
    if (isEncrypted) {
      try {
        bytes = await EncryptionService.decryptFileToBytes(localPath);
      } catch (e) {
        throw Exception('Failed to decrypt image file: $e');
      }
    } else {
      bytes = await originalFile.readAsBytes();
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image.');
    }

    final imgW = decoded.width.toDouble();
    final imgH = decoded.height.toDouble();

    // Circle in viewport coordinates
    final viewportRadius = side * 0.35;
    final viewportCenter = Offset(side / 2, side / 2);

    // Transform viewport coordinates back into image-child coordinates.
    final inv = Matrix4.inverted(_transformController.value);
    Offset toChild(Offset v) => MatrixUtils.transformPoint(inv, v);

    // Map child coordinates (square of size "side") to image space given BoxFit.contain.
    Offset childToImage(Offset c) {
      final x = c.dx;
      final y = c.dy;
      if (imgW >= imgH) {
        // Landscape image: width fits viewport, vertical padding.
        final scale = side / imgW;
        final drawnHeight = imgH * scale;
        final vPad = (side - drawnHeight) / 2;
        final imgX = x / scale;
        final imgY = (y - vPad) / scale;
        return Offset(imgX, imgY);
      } else {
        // Portrait image: height fits viewport, horizontal padding.
        final scale = side / imgH;
        final drawnWidth = imgW * scale;
        final hPad = (side - drawnWidth) / 2;
        final imgX = (x - hPad) / scale;
        final imgY = y / scale;
        return Offset(imgX, imgY);
      }
    }

    // Transform circle center to image coordinates
    final childCenter = toChild(viewportCenter);
    final imgCenter = childToImage(childCenter);

    // Validate center coordinates
    if (imgCenter.dx.isNaN ||
        imgCenter.dy.isNaN ||
        imgCenter.dx.isInfinite ||
        imgCenter.dy.isInfinite) {
      throw Exception('Invalid image center coordinates');
    }

    // Transform a point on the circle edge to get the radius in image coordinates
    final viewportEdgePoint = viewportCenter + Offset(viewportRadius, 0);
    final childEdgePoint = toChild(viewportEdgePoint);
    final imgEdgePoint = childToImage(childEdgePoint);
    final imgRadius = (imgEdgePoint - imgCenter).distance;

    // Validate radius
    if (imgRadius.isNaN || imgRadius.isInfinite || imgRadius <= 0) {
      throw Exception('Invalid image radius');
    }

    // Square crop aligned to the circle's bounding box (diagonal = circle diameter)
    // We allow transparent areas when the crop extends outside the image bounds.
    final cropSize = (imgRadius * 2).ceil();
    if (cropSize <= 0) {
      throw Exception('Invalid crop size: $cropSize');
    }

    final cropLeft = imgCenter.dx - imgRadius;
    final cropTop = imgCenter.dy - imgRadius;

    // Create an output image filled with transparency
    final output = img.Image(width: cropSize, height: cropSize);
    img.fill(output, color: img.ColorRgba8(0, 0, 0, 0));

    // Copy pixels from the source image where available; otherwise keep transparent.
    for (int y = 0; y < cropSize; y++) {
      for (int x = 0; x < cropSize; x++) {
        final srcX = (cropLeft + x).round();
        final srcY = (cropTop + y).round();
        if (srcX >= 0 &&
            srcX < imgW.toInt() &&
            srcY >= 0 &&
            srcY < imgH.toInt()) {
          final pixel = decoded.getPixel(srcX, srcY);
          output.setPixel(x, y, pixel);
        }
      }
    }

    // Save as PNG to preserve transparency when part of the crop is outside the image.
    final outBytes = img.encodePng(output);

    final dir = p.dirname(localPath);
    // Strip .encrypted extension if present to get the actual base filename
    String basePath = localPath;
    if (basePath.endsWith('.encrypted')) {
      basePath = basePath.substring(0, basePath.length - '.encrypted'.length);
    }
    // Get the base name without extension and save as PNG (to keep transparency)
    final base = p.basenameWithoutExtension(basePath);
    final croppedPath = p.join(dir, '${base}_crop.png');

    final outFile = File(croppedPath);
    await outFile.writeAsBytes(outBytes, flush: true);
    return croppedPath;
  }

  Future<String> _createCroppedVideoFile() async {
    final side = viewportSide;
    if (side == null) throw Exception('Viewport not ready.');

    // 1. Ensure local video exists
    final localPath = await _hologramController.ensureLocalTopicMedia(topic);
    if (localPath == null || localPath.isEmpty) {
      throw Exception('Local video not found. Please download it first.');
    }

    final originalFile = File(localPath);
    if (!await originalFile.exists()) {
      throw Exception('Local video file missing on disk.');
    }

    // 2. Prepare source file (decrypt if needed)
    final bool isEncrypted =
        localPath.endsWith('.encrypted') ||
        await EncryptionService.isFileEncrypted(localPath);

    String inputPath = localPath;
    File? tempDecryptedFile;

    if (isEncrypted) {
      try {
        final bytes = await EncryptionService.decryptFileToBytes(localPath);
        final tempDir = await _hologramController.getTopicMediaDirectory();
        tempDecryptedFile = File(
          p.join(tempDir.path, 'temp_decrypt_${topic.id}.mp4'),
        );
        await tempDecryptedFile.writeAsBytes(bytes);
        inputPath = tempDecryptedFile.path;
      } catch (e) {
        throw Exception('Failed to decrypt video for processing: $e');
      }
    }

    // 3. Calculate crop parameters
    // We assume the video fits "contain" in the crop widget.
    // However, for videos we often don't have the exact dimensions readily available
    // without probin. But usually CustomImageView uses BoxFit.contain.
    // We'll rely on FFprobe or just assume standard aspect ratios if we can't probe?
    // A robust way requires getting video dimensions.
    // ffmpeg_kit includes FFprobeKit. Let's use it or assume we can get it.
    // If not, we might need 'video_player' controller to get size?
    // For now, let's try to get dimensions via FFmpeg probe if possible,
    // or rely on `flutter_video_info` or similar if checked.
    // Wait, we don't have extra packages. Let's assume we can use FFmpeg to get info.

    // ACTUALLY: We can use FFprobeKit from the same package family.
    // However, to keep it simple and since we are inside a widget that might
    // display the video, maybe we can pass dimensions?
    // But `CropTopicController` is separated.
    // Let's use `ffmpeg_kit` to get media info.

    // 4. Construct FFmpeg crop command
    // We need to map viewport coordinates to video coordinates.
    // Matrix -> Invert -> Map crop circle rect -> Video rect.
    // This is same math as image, BUT we need video WIDTH and HEIGHT.

    // Let's get video dimensions first using FFmpegKit `FFprobeKit` is usually separate.
    // If not available, we might struggle.
    // Assuming `ffmpeg_kit_flutter` includes `FFprobeKit` or `FFmpegKitConfig`.
    // Let's try to just run a probe command or use `getMediaInformation`.

    // NOTE: For now, I will add `ffmpeg_kit_flutter_min_gpl` which usually spans both.
    // Importing `package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart`;

    // ... (Code continues below with implementation) ...
    // To implement `_createCroppedVideoFile` fully I need to import FFprobeKit too.
    // I will add the import in a separate edit if needed, or assume it's available.
    // Let's implement assuming we can get dimensions.

    // Use a placeholder for dimensions for now or try to use `flutter_video_info` if added?
    // No, use FFprobe from kit.

    return _processVideoCrop(inputPath, side);
  }

  Future<String> _processVideoCrop(String inputPath, double side) async {
    // 1. Get video information using FFprobe
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final info = session.getMediaInformation();

    if (info == null) {
      throw Exception('Failed to get media info from video.');
    }

    final streams = info.getStreams();
    if (streams.isEmpty) {
      throw Exception('No streams found in video.');
    }

    // Get video width and height
    // Note: FFprobe usually returns properties, but we might need to parse.
    // ffmpeg_kit streams have getWidth() / getHeight()

    int? width;
    int? height;

    // Find the video stream
    for (var stream in streams) {
      if (stream.getType() == 'video') {
        width = stream.getWidth();
        height = stream.getHeight();
        break;
      }
    }

    if (width == null || height == null) {
      throw Exception('Could not determine video dimensions.');
    }

    final double vidW = width.toDouble();
    final double vidH = height.toDouble();

    // 2. Map viewport crop circle to video coordinates
    // This logic mirrors _createCroppedImageFile but using video definitions

    // Circle in viewport coordinates
    final viewportRadius = side * 0.35;
    final viewportCenter = Offset(side / 2, side / 2);

    // Transform viewport coordinates back into child (video widget) coordinates.
    // The video widget is inside the InteractiveViewer.
    final inv = Matrix4.inverted(_transformController.value);
    Offset toChild(Offset v) => MatrixUtils.transformPoint(inv, v);

    // Map child coordinates to video-content space.
    // Assuming the video is rendered with BoxFit.contain inside the square of size `side`.
    Offset childToVideo(Offset c) {
      final x = c.dx;
      final y = c.dy;
      if (vidW >= vidH) {
        // Landscape: fits width
        final scale = side / vidW;
        final drawnHeight = vidH * scale;
        final vPad = (side - drawnHeight) / 2;
        final vidX = x / scale;
        final vidY = (y - vPad) / scale;
        return Offset(vidX, vidY);
      } else {
        // Portrait: fits height
        final scale = side / vidH;
        final drawnWidth = vidW * scale;
        final hPad = (side - drawnWidth) / 2;
        final vidX = (x - hPad) / scale;
        final vidY = y / scale;
        return Offset(vidX, vidY);
      }
    }

    // Transform circle center to video coordinates
    final childCenter = toChild(viewportCenter);
    final vidCenter = childToVideo(childCenter);

    // Transform radius
    final viewportEdgePoint = viewportCenter + Offset(viewportRadius, 0);
    final childEdgePoint = toChild(viewportEdgePoint);
    final vidEdgePoint = childToVideo(childEdgePoint);
    final vidRadius = (vidEdgePoint - vidCenter).distance;

    // Calculate crop box (square)
    // w:h:x:y
    final cropSize = (vidRadius * 2);
    final cropX = vidCenter.dx - vidRadius;
    final cropY = vidCenter.dy - vidRadius;

    // Let's implement robust integer clamping for the crop string.
    // (cw, ch, cx, cy variables removed as we calculate final values from intersection logic below)

    // Construct local path for output
    final dir = await _hologramController.getTopicMediaDirectory();
    final base = p
        .basenameWithoutExtension(inputPath)
        .replaceAll('_crop', '')
        .replaceAll('.encrypted', '');
    final outPath = p.join(dir.path, '${base}_crop.mp4');

    // Delete previous if exists
    final outFile = File(outPath);
    if (await outFile.exists()) {
      await outFile.delete();
    }

    // Build FFmpeg command
    // filter: crop=w:h:x:y
    // Ensure cx, cy are not too far out that w/h becomes invalid?
    // Actually, we should probably ensure the crop is at least partially inside.
    // FFmpeg's crop filter behaviour:
    // "If the x and y offsets result in cropping outside the input area, the crop filter will automatically adjust them to keep the output within the input area."
    // BUT the error says: "Invalid too big or non positive size for width '1980' or height '1980'"
    // This implies that perhaps cw/ch are larger than video dimensions?
    // OR that cx+cw > width etc in a way that ffmpeg rejects for the given codec/format constraints.

    // Let's CLAMP the crop rectangle to the video boundaries for safety.
    // This changes the "virtual padding" approach but guarantees validity.
    // If we want transparency we need complex filters.
    // For now: Clamp to valid video usage.
    // Clamp X, Y to be within [-width, width] ? No, valid coords are 0..width.
    // But we allowed panning outside.
    // Implementation: intersection of cropRect and videoRect.

    // If user zooms OUT, the 'cropSize' might be LARGER than the video dimensions (vidW, vidH).
    // In that case, we want to PAD the video to match the requested 'cropSize' (or aspect ratio)
    // rather than just clamping it (which zooms it back in).
    // Or more accurately: The 'viewport' sees a black background around the video.
    // We should emulate this by padding the video with black bars to match the requested crop size,
    // and then crop *that*.

    // Easier approach with FFmpeg:
    // 1. Pad the input video to be large enough to contain the crop area.
    // 2. Then crop.

    // Calculate the 'bounding box' of the crop and the video.
    // However, FFmpeg 'pad' filter pads *around* the original video.
    // If cropX < 0, we need padding on the left.
    // If cropY < 0, we need padding on the top.
    // If cropX + cropSize > vidW, we need padding on the right.
    // If cropY + cropSize > vidH, we need padding on the bottom.

    // Let's calculate required padding.
    // padX: how much to adding to left (video starts at x=padX in new canvas)
    // padY: how much to add to top (video starts at y=padY in new canvas)

    // Relative to the 'crop' top-left (0,0 of crop space):
    // Video is at (vidX_relative, vidY_relative) = (-cropX, -cropY)

    // If we simply use a filter chain:
    // pad=width:height:x:y:color=black
    // We want the final canvas to be such that we can just crop the requested area.
    // Actually, simplest is to create a canvas that covers the UNION of the video and the crop rect,
    // position the video correctly within it, and then crop.

    // Union Rect:
    final cropRect = Rect.fromLTWH(cropX, cropY, cropSize, cropSize);
    final videoRect = Rect.fromLTWH(0, 0, vidW, vidH);
    final unionRect = cropRect.expandToInclude(videoRect);

    // New canvas size (rounded)
    int canvasW = unionRect.width.ceil();
    int canvasH = unionRect.height.ceil();
    // Ensure even
    if (canvasW % 2 != 0) canvasW++;
    if (canvasH % 2 != 0) canvasH++;

    // Where to place the original video in this new canvas?
    // Video was at (0,0). Union rect top-left is (unionRect.left, unionRect.top).
    // So video pos is (0 - unionRect.left, 0 - unionRect.top).
    int placeX = (0 - unionRect.left).round();
    int placeY = (0 - unionRect.top).round();

    // Then we crop from this canvas.
    // The requested crop was at (cropX, cropY).
    // In the new canvas space (where unionRect.topLeft is 0,0),
    // the crop top-left is (cropX - unionRect.left, cropY - unionRect.top).
    int finalCropX = (cropX - unionRect.left).round();
    int finalCropY = (cropY - unionRect.top).round();
    int finalCropW = cropSize.round();
    int finalCropH = cropSize.round();

    // Ensure even crop (though x264 might handle odd crop if not strictly 420p, but 420p wants even)
    if (finalCropW % 2 != 0) finalCropW--;
    if (finalCropH % 2 != 0) finalCropH--;

    // Build filter chain:
    // 1. Pad video to canvasW:canvasH at placeX:placeY
    // 2. Crop to finalCropW:finalCropH at finalCropX:finalCropY
    String filter =
        'pad=$canvasW:$canvasH:$placeX:$placeY:black,crop=$finalCropW:$finalCropH:$finalCropX:$finalCropY';

    // 3. Downscale if output is too large (e.g. > 1080p).
    // When zooming out (shrinking video), the 'crop' area in source pixels becomes huge.
    // We must limit the output resolution to ensure the device can play it.
    const maxDimension = 1080;
    if (finalCropW > maxDimension || finalCropH > maxDimension) {
      filter += ',scale=$maxDimension:$maxDimension';
      log(
        'FFmpeg scaling output to $maxDimension x $maxDimension (original crop was $finalCropW x $finalCropH)',
      );
    }

    log('FFmpeg pad+crop+scale: $filter');
    log(
      'FFmpeg cropping: $filter (Original requested: ${cropSize.round()} at ${cropX.round()},${cropY.round()})',
    );

    // Added -c:a aac to ensure audio is compatible and not lost/corrupted.
    // -pix_fmt yuv420p ensures compatibility with most players.
    // -movflags +faststart helps with immediate playback.
    final command =
        '-y -i "$inputPath" -vf "$filter" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -pix_fmt yuv420p -movflags +faststart "$outPath"';
    // Switched to libx264 for better compatibility and explicit pixel format.

    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        throw Exception('FFmpeg failed with code $returnCode: $logs');
      }
    });

    // If we created a temp decrypted file, delete it
    if (inputPath.contains('temp_decrypt_')) {
      final temp = File(inputPath);
      if (await temp.exists()) await temp.delete();
    }

    return outPath;
  }
}
