import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../../../theme/app_font.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/extensions/sizedbox_extensions.dart';
import '../../controllers/ar_controller.dart';
import '../../models/ar_marker_model.dart';
import '../widgets/ar_controls_overlay.dart';
import '../widgets/ar_status_indicator.dart';

class ArScannerScreen extends StatefulWidget {
  const ArScannerScreen({super.key});

  @override
  State<ArScannerScreen> createState() => _ArScannerScreenState();
}

class _ArScannerScreenState extends State<ArScannerScreen>
    with WidgetsBindingObserver {
  late final ArController _ctrl;

  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;

  // Active 3D node and its last detected world transform
  ARNode? _currentNode;
  vm.Matrix4? _lastTransform;
  String? _currentMarkerName;
  bool _isReplacingModel = false;
  bool _isInteracting = false;

  // Map from various imageName forms → marker, for fast lookup
  final Map<String, ArMarkerModel> _markerByImageName = {};

  bool? _cameraPermissionStatus; // null: checking, true: granted, false: denied
  bool _isCheckingPermission = false;
  final bool _arSupported = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = Get.find<ArController>();
    _checkPermissionsAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionManager?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sessionManager?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Re-check permission when returning to the app, especially if it was denied
      if (_cameraPermissionStatus != true) {
        _checkPermissionsAndInit();
      }
    }
  }

  // ── Permission check ──────────────────────────────────────────────────────

  Future<void> _checkPermissionsAndInit() async {
    if (_isCheckingPermission) return;
    _isCheckingPermission = true;

    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _cameraPermissionStatus = status.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  // ── AR session setup ──────────────────────────────────────────────────────

  Future<void> _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    _sessionManager = sessionManager;
    _objectManager = objectManager;

    // Build lookup map and collect image paths for the tracker
    final docsDir = (await getApplicationDocumentsDirectory()).path;
    debugPrint('ArScanner: Current Documents Dir: $docsDir');
    final paths = _buildMarkerLookup();
    
    // We send raw paths first. If detection still doesn't fire, we'll try prefixes.
    final trackingPaths = paths; 
    
    debugPrint('ArScanner: tracking ${paths.length} markers');
    for (final p in paths) {
      final file = File(p);
      final exists = file.existsSync();
      final size = exists ? file.lengthSync() : 0;
      debugPrint('ArScanner: marker path: $p (exists: $exists, size: $size bytes)');
    }

    // Fired once when the native image tracking database is compiled and ready
    sessionManager.onImageTrackingConfigured = (success) {
      debugPrint('ArScanner: Image tracking configured: $success');
      if (mounted) {
        setState(() => _initialized = true);
        _ctrl.setScanReady();
      }
    };

    // Fired on every detection event (continuous tracking)
    sessionManager.onImageDetected = _onImageDetected;

    // Tracking quality changes — inform controller so UI can reflect loss
    sessionManager.onTrackingStateChanged = (state, reason) {
      debugPrint('ArScanner: Tracking state changed: $state (reason: $reason)');
      if (state != 'normal' && _currentMarkerName != null) {
        _ctrl.onMarkerLost(_currentMarkerName!);
        
        // Hide model on tracking loss to match Unity's behavior
        if (_currentNode != null) {
          _objectManager?.removeNode(_currentNode!);
          _currentNode = null;
          _currentMarkerName = null;
        }
      }
    };

    objectManager.onPanStart = (_) => _isInteracting = true;
    objectManager.onPanEnd = (name, transform) {
      _isInteracting = false;
      _lastTransform = transform;
    };
    objectManager.onRotationStart = (_) => _isInteracting = true;
    objectManager.onRotationEnd = (name, transform) {
      _isInteracting = false;
      _lastTransform = transform;
    };
    objectManager.onScaleStart = (_) => _isInteracting = true;
    objectManager.onScaleEnd = (name, transform) {
      _isInteracting = false;
      _lastTransform = transform;
    };

    await sessionManager.onInitialize(
      showAnimatedGuide: false,
      showFeaturePoints: true, // Show dots to verify tracking is active
      showPlanes: false,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: false,
      handlePans: true,
      handleRotation: true,
      handleScaling: true,
      trackingImagePaths: trackingPaths,
      continuousImageTracking: true, // MUST be true for continuous detection updates
      imageTrackingUpdateIntervalMs: 100, // Faster detection response
      lightIntensityMultiplier: 1.5, // Standard brightness (1000 was way too high)
    );

    await objectManager.onInitialize();
  }

  /// Builds the [_markerByImageName] lookup table and returns the list of
  /// local marker image paths to register with the AR tracking system.
  List<String> _buildMarkerLookup() {
    _markerByImageName.clear();
    final paths = <String>[];

    for (final marker in _ctrl.markers) {
      final path = marker.markerImageLocalPath;
      if (path == null || !File(path).existsSync()) continue;

      // STABILITY FIX: ARKit struggles with very large reference images.
      // We increased the limit to 10MB to accommodate high-res markers.
      final size = File(path).lengthSync();
      if (size > 10 * 1024 * 1024) {
        debugPrint('ArScanner: Skipping ${marker.title} - Image too large (${(size/1024).round()} KB)');
        continue;
      }

      paths.add(path);

      // Index by various forms to ensure we match what the native side returns
      _markerByImageName[path] = marker;
      _markerByImageName[p.basename(path)] = marker;
      _markerByImageName[p.basenameWithoutExtension(path)] = marker;
      _markerByImageName['file://$path'] = marker;

      debugPrint('ArScanner: Mapping marker ${marker.id} to: ${p.basename(path)}');
    }

    return paths;
  }

  // ── Image detection ───────────────────────────────────────────────────────

  void _onImageDetected(String imageName, vm.Matrix4 transformation) {
    debugPrint('ArScanner: [NATIVE CALLBACK] Image detected: "$imageName"');
    
    // Look up marker by name or variations
    final marker = _markerByImageName[imageName] ??
        _markerByImageName[p.basename(imageName)] ??
        _markerByImageName[p.basenameWithoutExtension(imageName)] ??
        _markerByImageName['file://$imageName'];

    if (marker == null) {
      debugPrint('ArScanner: [WARNING] No marker found for "$imageName". Available keys: ${_markerByImageName.keys.take(10).join(", ")}');
      return;
    }

    debugPrint('ArScanner: >>> DETECTED: ${marker.title} (ID: ${marker.id}, Name: ${marker.markerName}) <<<');

    // Build the model transform: same world pose as the marker, scaled by marker's displayScale
    final modelTransform = vm.Matrix4.fromFloat64List(transformation.storage);
    final scale = marker.displayScale;
    debugPrint('ArScanner: Placing ${marker.title} at scale $scale');

    modelTransform.scaleByVector3(vm.Vector3(scale, scale, scale));
    
    _lastTransform = modelTransform.clone();

    if (_isInteracting) {
      debugPrint('ArScanner: Interaction in progress, skipping marker update');
      return;
    }

    if (_currentNode != null && _currentMarkerName == marker.markerName) {
      // Same marker visible: update world position with basic smoothing to match Unity's behavior
      _smoothUpdateNodeTransform(_currentNode!, modelTransform);
    } else {
      // New marker (or first detection): swap out the current model
      _replaceModel(marker, modelTransform);
    }

    // Notify controller; it's a no-op if this marker is already active
    _ctrl.onMarkerDetected(marker.markerName);
  }

  /// Basic smoothing for transformation updates, approximating Unity's exponential lerp
  void _smoothUpdateNodeTransform(ARNode node, vm.Matrix4 target) {
    // For now, we apply directly. In a more advanced implementation, 
    // we could interpolate between current and target over multiple frames.
    node.transform = target;
  }

  Future<void> _replaceModel(ArMarkerModel marker, vm.Matrix4 transform) async {
    if (_isReplacingModel) return;
    _isReplacingModel = true;

    try {
      final old = _currentNode;
      if (old != null) {
        await _objectManager?.removeNode(old);
        _currentNode = null;
        _currentMarkerName = null;
      }

      final modelPath = marker.modelLocalPath;
      if (modelPath == null || !File(modelPath).existsSync()) return;

      final node = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: modelPath,
        transformation: transform,
        name: 'model_${marker.id}',
      );

      final placed = await _objectManager?.addNode(node) ?? false;
      debugPrint('ArScanner: addNode result for ${marker.title}: $placed (path: $modelPath)');
      if (placed) {
        _currentNode = node;
        _currentMarkerName = marker.markerName;
      }
    } catch (e) {
      debugPrint('ArScanner: failed to place model for ${marker.title}: $e');
      _ctrl.closeModel();
    } finally {
      _isReplacingModel = false;
    }
  }

  // ── Control callbacks ─────────────────────────────────────────────────────

  Future<void> _resetModelPosition() async {
    final node = _currentNode;
    final last = _lastTransform;
    if (node == null || last == null) return;
    node.transform = last.clone();
  }

  void _onCloseModel() {
    final node = _currentNode;
    if (node != null) {
      _objectManager?.removeNode(node);
      _currentNode = null;
      _currentMarkerName = null;
      _lastTransform = null;
    }
    _ctrl.closeModel();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cameraPermissionStatus == null) {
      return _buildInitializingOverlay();
    }
    if (_cameraPermissionStatus == false) {
      return _buildPermissionDeniedScreen();
    }
    if (!_arSupported) {
      return _buildArUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── AR camera view ─────────────────────────────────────────────
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),

          // ── Scanning frame animation ───────────────────────────────────
          Obx(() {
            final scanning =
                _ctrl.scanPhase.value == ArScanPhase.scanning && _initialized;
            return scanning
                ? const ArScanningFrame()
                : const SizedBox.shrink();
          }),

          // ── Status indicator (top centre) ──────────────────────────────
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ArStatusIndicator(),
          ),

          // ── Close button (top right) ───────────────────────────────────
          _buildCloseButton(),

          // ── Model controls overlay (bottom) ───────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ArControlsOverlay(onResetPosition: _resetModelPosition),
          ),

          // ── Loading overlay while AR initialises ───────────────────────
          if (!_initialized) _buildInitializingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () {
              _onCloseModel();
              Get.back();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitializingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppColors.buttonPrimary,
                strokeWidth: 3,
              ),
            ),
            20.hS,
            Text(
              'Starting AR camera...',
              style: AppFont.w500.s15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.no_photography_rounded,
                color: Colors.white54,
                size: 80,
              ),
              32.hS,
              Text(
                'Camera Permission Required',
                style: AppFont.w700.s22,
                textAlign: TextAlign.center,
              ),
              16.hS,
              Text(
                'VizLearn AR needs camera access to detect markers and show 3D models.',
                style: AppFont.w400.s14.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              40.hS,
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AppSettings.openAppSettings();
                    await _checkPermissionsAndInit();
                  },
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Open Settings',
                    style:
                        AppFont.w700.s16.copyWith(color: AppColors.primary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              20.hS,
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Go Back',
                  style: AppFont.w500.s14.copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArUnsupportedScreen() {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.view_in_ar_rounded,
                color: Colors.white38,
                size: 80,
              ),
              32.hS,
              Text(
                'AR Not Supported',
                style: AppFont.w700.s22,
                textAlign: TextAlign.center,
              ),
              16.hS,
              Text(
                'Your device does not support Augmented Reality. Please try on a supported device.',
                style: AppFont.w400.s14.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              40.hS,
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style:
                        AppFont.w700.s16.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
