import 'dart:developer' as developer;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

import '../models/ar_marker_model.dart';
import '../repositories/ar_marker_repository.dart';

enum ArDownloadPhase { idle, fetching, downloading, done, error }

enum ArScanPhase {
  initializing,
  scanning,
  markerFound,
  modelLoading,
  modelReady,
  error,
}

class ArController extends GetxController {
  final ArRepository _repo;

  ArController(this._repo);

  // ── Download / load state ─────────────────────────────────────────────────

  final Rx<ArDownloadPhase> downloadPhase = ArDownloadPhase.idle.obs;
  final RxList<ArMarkerModel> markers = <ArMarkerModel>[].obs;
  final RxString errorMessage = ''.obs;

  // Progress from ArRepository (0–100)
  final RxInt loadPercent = 0.obs;
  final RxString loadStage = ''.obs;
  final RxInt loadCompleted = 0.obs;
  final RxInt loadTotal = 0.obs;

  // ── Scanner state ─────────────────────────────────────────────────────────

  final Rx<ArScanPhase> scanPhase = ArScanPhase.initializing.obs;
  final Rx<ArMarkerModel?> detectedMarker = Rx<ArMarkerModel?>(null);
  final RxBool isModelVisible = false.obs;

  // ── Audio ─────────────────────────────────────────────────────────────────

  final RxBool isAudioMuted = false.obs;
  final RxBool isAudioPlaying = false.obs;
  final AudioPlayer _audio = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    _audio.onPlayerStateChanged.listen((state) {
      isAudioPlaying.value = state == PlayerState.playing;
    });
  }

  @override
  void onClose() {
    _audio.dispose();
    super.onClose();
  }

  // ── Download helpers ──────────────────────────────────────────────────────

  bool get allMarkersDownloaded =>
      markers.isNotEmpty && markers.every((m) => m.isFullyDownloaded);

  /// Fetches, downloads, and caches all AR markers in one call.
  /// Progress is reported via [loadPercent] (0–100) and [loadStage].
  Future<void> initializeMarkers() async {
    downloadPhase.value = ArDownloadPhase.fetching;
    errorMessage.value = '';
    loadPercent.value = 0;
    loadStage.value = '';
    loadCompleted.value = 0;
    loadTotal.value = 0;

    try {
      final entries = await _repo.getOrFetchMarkers(
        onLoadProgress: (progress) {
          loadPercent.value = progress.percent;
          loadStage.value = progress.stage ?? '';
          loadCompleted.value = progress.completed ?? 0;
          loadTotal.value = progress.total ?? 0;

          if (progress.percent > 0 && progress.percent < 100) {
            downloadPhase.value = ArDownloadPhase.downloading;
          }
        },
      );

      markers.assignAll(entries.map(_entryToModel));

      if (markers.isNotEmpty) {
        downloadPhase.value = ArDownloadPhase.done;
      } else {
        downloadPhase.value = ArDownloadPhase.error;
        errorMessage.value = 'No AR markers found. Please try again.';
      }
    } catch (e) {
      downloadPhase.value = ArDownloadPhase.error;
      errorMessage.value = 'Failed to load AR content. Please try again.';
      _log('initializeMarkers: $e', error: true);
    }
  }

  Future<void> retryDownload() async {
    downloadPhase.value = ArDownloadPhase.fetching;
    errorMessage.value = '';
    loadPercent.value = 0;
    loadStage.value = '';
    loadCompleted.value = 0;
    loadTotal.value = 0;

    try {
      final entries = await _repo.getOrFetchMarkers(
        forceRefresh: true,
        onLoadProgress: (progress) {
          loadPercent.value = progress.percent;
          loadStage.value = progress.stage ?? '';
          loadCompleted.value = progress.completed ?? 0;
          loadTotal.value = progress.total ?? 0;
          if (progress.percent > 0 && progress.percent < 100) {
            downloadPhase.value = ArDownloadPhase.downloading;
          }
        },
      );

      markers.assignAll(entries.map(_entryToModel));
      downloadPhase.value =
          markers.isNotEmpty ? ArDownloadPhase.done : ArDownloadPhase.error;
      if (markers.isEmpty) errorMessage.value = 'No AR markers found. Please try again.';
    } catch (e) {
      downloadPhase.value = ArDownloadPhase.error;
      errorMessage.value = 'Failed to load AR content. Please try again.';
      _log('retryDownload: $e', error: true);
    }
  }

  ArMarkerModel _entryToModel(ArMarkerEntry e) {
    return ArMarkerModel(
      id: e.id,
      title: e.title,
      markerImageUrl: '',
      model3dUrl: '',
      audioUrl: null,
      markerImageLocalPath: e.markerImageLocalPath,
      modelLocalPath: e.modelLocalPath,
      audioLocalPath: e.audioLocalPath,
      displayScale: e.displayScale,
    );
  }

  // ── Scanner callbacks ─────────────────────────────────────────────────────

  bool _detectionSequenceActive = false;

  void _setScanPhase(ArScanPhase phase) {
    if (scanPhase.value != phase) {
      scanPhase.value = phase;
      update(['arStatus']);
    }
  }

  void _setModelVisible(bool visible) {
    if (isModelVisible.value != visible) {
      isModelVisible.value = visible;
      update(['arControls', 'arStatus']);
    }
  }

  Future<void> onMarkerDetected(String markerName) async {
    final id = int.tryParse(markerName.replaceFirst('ar_marker_', ''));
    if (id == null) return;

    final marker = markers.where((m) => m.id == id).firstOrNull;
    if (marker == null || !marker.isFullyDownloaded) return;

    if (detectedMarker.value?.id == id &&
        (isModelVisible.value || _detectionSequenceActive)) {
      return;
    }

    _detectionSequenceActive = true;
    detectedMarker.value = marker;

    try {
      _setScanPhase(ArScanPhase.markerFound);

      await Future.delayed(const Duration(milliseconds: 400));
      if (detectedMarker.value?.id != id) return;

      _setScanPhase(ArScanPhase.modelLoading);

      await Future.delayed(const Duration(milliseconds: 500));
      if (detectedMarker.value?.id != id) return;

      _setModelVisible(true);
      _setScanPhase(ArScanPhase.modelReady);

      if (!isAudioMuted.value) await _playAudio(marker);
    } finally {
      _detectionSequenceActive = false;
    }
  }

  void onMarkerLost(String markerName) {
    // Tracking glitches are common; keep the current UI while the model stays visible.
  }

  void setScanReady() {
    _setScanPhase(ArScanPhase.scanning);
  }

  void closeModel() {
    _detectionSequenceActive = false;
    _setModelVisible(false);
    detectedMarker.value = null;
    _setScanPhase(ArScanPhase.scanning);
    _audio.stop();
    isAudioPlaying.value = false;
    update(['arControls']);
  }

  // ── Audio controls ────────────────────────────────────────────────────────

  Future<void> toggleMute() async {
    isAudioMuted.value = !isAudioMuted.value;
    update(['arControls']);
    if (isAudioMuted.value) {
      await _audio.pause();
    } else {
      final m = detectedMarker.value;
      if (m != null && isModelVisible.value) await _playAudio(m);
    }
  }

  Future<void> replayAudio() async {
    final m = detectedMarker.value;
    if (m == null || !isModelVisible.value) return;
    isAudioMuted.value = false;
    await _playAudio(m);
  }

  Future<void> _playAudio(ArMarkerModel marker) async {
    final path = marker.audioLocalPath;
    if (path == null || path.isEmpty) return;
    if (!File(path).existsSync()) return;
    try {
      await _audio.stop();
      await _audio.play(DeviceFileSource(path));
    } catch (e) {
      _log('Audio playback error: $e', error: true);
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  String get scanStatusLabel => switch (scanPhase.value) {
        ArScanPhase.initializing => 'Starting camera...',
        ArScanPhase.scanning => 'Scanning...',
        ArScanPhase.markerFound => 'Marker Found!',
        ArScanPhase.modelLoading => 'Loading Model...',
        ArScanPhase.modelReady => 'Ready!',
        ArScanPhase.error => 'Camera Error',
      };

  void _log(String msg, {bool error = false}) {
    developer.log(msg, name: 'ArController', level: error ? 1000 : 0);
  }
}
