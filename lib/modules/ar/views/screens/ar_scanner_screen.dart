import 'dart:io';
import 'dart:math' as math;

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
  vm.Matrix4? _latestBaseTransform;
  vm.Vector3 _userTranslation = vm.Vector3.zero();
  double _userRotationDegrees = 0.0;
  double _userScaleMultiplier = 1.0;
  static const _minUserScale = 0.25;
  static const _maxUserScale = 4.0;
  static const _zoomStep = 1.2;
  String? _currentMarkerName;
  int? _activeMarkerId;
  bool _isReplacingModel = false;
  bool _isInteracting = false;
  bool _disposed = false;

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

  void _stopArCallbacks() {
    _disposed = true;
    _sessionManager?.onImageDetected = null;
    _sessionManager?.onImageTrackingConfigured = null;
    _sessionManager?.onTrackingStateChanged = null;
  }

  @override
  void dispose() {
    _stopArCallbacks();
    WidgetsBinding.instance.removeObserver(this);
    _onCloseModel();
    _sessionManager?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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

    // Tracking quality changes — only update UI state; do not tear down the
    // model on transient ARCore glitches (common on Android image tracking).
    sessionManager.onTrackingStateChanged = (state, reason) {
      if (_disposed) return;
      if (state != 'normal' && _activeMarkerId != null) {
        _ctrl.onMarkerLost(_currentMarkerName ?? '');
      }
    };

    objectManager.onPanStart = (_) => _isInteracting = true;
    objectManager.onPanEnd = (name, transform) {
      _isInteracting = false;
      _syncUserTransformFromWorld(transform);
      _applyCurrentTransform();
    };
    objectManager.onRotationStart = (_) => _isInteracting = true;
    objectManager.onRotationEnd = (name, transform) {
      _isInteracting = false;
      _syncUserTransformFromWorld(transform);
      _applyCurrentTransform();
    };

    await sessionManager.onInitialize(
      showAnimatedGuide: false,
      showFeaturePoints: false, // Turn off feature points to save CPU/Buffers on Android
      showPlanes: false,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: false,
      handlePans: true,
      handleRotation: true,
      trackingImagePaths: trackingPaths,
      continuousImageTracking: true,
      imageTrackingUpdateIntervalMs: 500,
      lightIntensityMultiplier: 1.5,
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
    if (_disposed) return;

    final marker = _markerByImageName[imageName] ??
        _markerByImageName[p.basename(imageName)] ??
        _markerByImageName[p.basenameWithoutExtension(imageName)] ??
        _markerByImageName['file://$imageName'];

    if (marker == null) return;

    if (_isInteracting) return;

    if (_activeMarkerId == marker.id) {
      final markerTransform = vm.Matrix4.fromFloat64List(transformation.storage);
      final scale = marker.displayScale;
      final baseTransform =
          markerTransform.clone()..scaleByVector3(vm.Vector3(scale, scale, scale));
      _latestBaseTransform = baseTransform;
      final modelTransform = _composeModelTransform(baseTransform);
      _lastTransform = modelTransform.clone();
      if (_currentNode != null) {
        _smoothUpdateNodeTransform(_currentNode!, modelTransform);
      }
      return;
    }

    if (_isReplacingModel) return;

    _activeMarkerId = marker.id;
    _currentMarkerName = marker.markerName;

    debugPrint(
      'ArScanner: >>> DETECTED: ${marker.title} (ID: ${marker.id}, Name: ${marker.markerName}) <<<',
    );

    final markerTransform = vm.Matrix4.fromFloat64List(transformation.storage);
    final scale = marker.displayScale;
    final baseTransform =
        markerTransform.clone()..scaleByVector3(vm.Vector3(scale, scale, scale));
    _latestBaseTransform = baseTransform;
    _lastTransform = _composeModelTransform(baseTransform).clone();

    _userTranslation = vm.Vector3.zero();
    _userRotationDegrees = 0.0;
    _userScaleMultiplier = 1.0;
    _replaceModel(marker, _composeModelTransform(baseTransform));
    _ctrl.onMarkerDetected(marker.markerName);
  }

  vm.Matrix4 _composeModelTransform([vm.Matrix4? base]) {
    final baseTransform = base ?? _latestBaseTransform;
    if (baseTransform == null) return vm.Matrix4.identity();

    final userTransform = vm.Matrix4.compose(
      _userTranslation,
      vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        vm.radians(_userRotationDegrees),
      ),
      vm.Vector3.all(_userScaleMultiplier),
    );
    return baseTransform * userTransform;
  }

  void _setRotationDegrees(double degrees) {
    if (_currentNode == null) return;
    _userRotationDegrees = degrees.clamp(0.0, 360.0);
    _applyCurrentTransform();
    if (mounted) setState(() {});
  }

  double _yAngleToDegrees(double radians) {
    final degrees = vm.degrees(radians) % 360;
    return degrees < 0 ? degrees + 360 : degrees;
  }

  void _syncUserTransformFromWorld(vm.Matrix4 worldTransform) {
    final base = _latestBaseTransform;
    if (base == null) return;

    final relative = vm.Matrix4.inverted(base) * worldTransform;
    final rotation = vm.Quaternion(0, 0, 0, 0);
    final scale = vm.Vector3.zero();
    relative.decompose(_userTranslation, rotation, scale);

    _userScaleMultiplier = scale.x.clamp(_minUserScale, _maxUserScale);
    _userRotationDegrees = _yAngleToDegrees(
      math.atan2(
        2.0 * (rotation.w * rotation.y + rotation.x * rotation.z),
        1.0 - 2.0 * (rotation.y * rotation.y + rotation.z * rotation.z),
      ),
    );
    _lastTransform = worldTransform.clone();
    if (mounted) setState(() {});
  }

  void _applyCurrentTransform() {
    final node = _currentNode;
    if (node == null || _latestBaseTransform == null) return;
    final transform = _composeModelTransform();
    node.transform = transform;
    _lastTransform = transform.clone();
  }

  void _zoomIn() {
    if (_currentNode == null) return;
    _userScaleMultiplier =
        (_userScaleMultiplier * _zoomStep).clamp(_minUserScale, _maxUserScale);
    _applyCurrentTransform();
  }

  void _zoomOut() {
    if (_currentNode == null) return;
    _userScaleMultiplier =
        (_userScaleMultiplier / _zoomStep).clamp(_minUserScale, _maxUserScale);
    _applyCurrentTransform();
  }

  void _rotateLeft() {
    _setRotationDegrees((_userRotationDegrees + 15) % 360);
  }

  void _rotateRight() {
    _setRotationDegrees((_userRotationDegrees - 15 + 360) % 360);
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
      } else {
        _currentMarkerName = null;
        _activeMarkerId = null;
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
    _userTranslation = vm.Vector3.zero();
    _userRotationDegrees = 0.0;
    _userScaleMultiplier = 1.0;
    _applyCurrentTransform();
    if (mounted) setState(() {});
  }

  void _onCloseModel() {
    final node = _currentNode;
    if (node != null) {
      _objectManager?.removeNode(node);
      _currentNode = null;
    }
    _currentMarkerName = null;
    _activeMarkerId = null;
    _lastTransform = null;
    _userTranslation = vm.Vector3.zero();
    _userRotationDegrees = 0.0;
    _userScaleMultiplier = 1.0;
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
          if (_initialized)
            GetBuilder<ArController>(
              id: 'arStatus',
              builder: (ctrl) {
                final scanning =
                    ctrl.scanPhase.value == ArScanPhase.scanning;
                return IgnorePointer(
                  ignoring: !scanning,
                  child: Opacity(
                    opacity: scanning ? 1 : 0,
                    child: const ArScanningFrame(),
                  ),
                );
              },
            ),

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
            child: ArControlsOverlay(
              onCloseModel: _onCloseModel,
              onResetPosition: _resetModelPosition,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onRotateLeft: _rotateLeft,
              onRotateRight: _rotateRight,
              rotationDegrees: _userRotationDegrees,
              onRotationChanged: _setRotationDegrees,
            ),
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
              _stopArCallbacks();
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
