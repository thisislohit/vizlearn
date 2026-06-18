import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger/app_logger.dart';
import 'package:vizlearn/controllers/connection_controller.dart';

import '../data/repositories/auth_repository.dart';
import '../routes/app_routes.dart';
import '../services/fcm_service.dart';
import '../utils/app_utils.dart';
import '../utils/cache/cache_keys.dart';
import '../utils/cache/secure_local_storage.dart';
import '../utils/enums.dart';
import '../utils/validators.dart';
import '../injectors/bindings/profile_binding.dart';
import '../injectors/bindings/sync_binding.dart';
import '../injectors/configure_dependencies.dart';
import '../views/screens/side_menu/profile/controllers/profile_controller.dart';
import '../controllers/sync_controller.dart';
import 'hologram_controller.dart';

class AuthController extends GetxController {
  AuthController({
    required this.authRepository,
    required this.secureStorage,
  });

  final AuthRepository authRepository;
  final SecureLocalStorage secureStorage;
  final _logger = AppLogger.logger;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isFormValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_updateFormValidity);
    passwordController.addListener(_updateFormValidity);
  }

  @override
  void onClose() {
    emailController.removeListener(_updateFormValidity);
    passwordController.removeListener(_updateFormValidity);
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? validateEmail(String? value) {
    return AppValidators.validateEmail(value);
  }

  String? validatePassword(String? value) {
    return AppValidators.validatePassword(value);
  }

  void onPasswordSubmitted(String value) {
    if (formKey.currentState?.validate() ?? false) {
      login();
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;

    final valid = formKey.currentState?.validate() ?? false;
    _updateFormValidity();
    if (!valid) return;

    try {
      isLoading.value = true;
      final deviceMeta = await _getDeviceMeta();

      // Get FCM token for login - ensure a fresh token is generated
      String? fcmToken;
      try {
        final fcmService = getIt<FCMService>();
        // Delete any existing token first to ensure a new one is generated
        try {
          await fcmService.deleteToken();
        } catch (e) {
          // Ignore errors if token doesn't exist or deletion fails
          _logger.w('⚠️ Error deleting old FCM token: $e');
        }
        // Initialize FCM to generate a new token
        fcmToken = await fcmService.initializeFCM();
        if (fcmToken == null || fcmToken.isEmpty) {
          // Try to get token if initialization didn't return it
          fcmToken = await fcmService.getCurrentToken();
        }
        _logger.i('🔑 New FCM Token generated for login: $fcmToken');
      } catch (e) {
        _logger.e('⚠️ Error getting FCM token for login: $e');
        // Continue with login even if FCM token fails
      }

      final response = await authRepository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
        deviceId: deviceMeta['id'] ?? 'unknown-device',
        deviceName: deviceMeta['name'] ?? 'Unknown Device',
        fcmToken: fcmToken ?? '',
      );

      if (response.token.isEmpty) {
        throw Exception(response.message.isNotEmpty ? response.message : 'Invalid response');
      }

      await secureStorage.save(key: CacheKeys.token, value: response.token);
      await secureStorage.save(key: CacheKeys.refreshToken, value: response.refreshToken);

      // Initialize profile controller and fetch profile data
      ProfileBinding().dependencies();
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        // Fetch profile in background (don't wait for it)
        profileController.fetchProfile();
      }

      // Initialize sync controller and trigger background sync
      if (!Get.isRegistered<SyncController>()) {
        final syncBinding = SyncBinding();
        syncBinding.dependencies();
      }
      if (Get.isRegistered<SyncController>()) {
        final syncController = Get.find<SyncController>();
        // Trigger background sync (don't wait for it)
        syncController.syncAll(showDialog: false);
      }

      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      AppUtils.showGetSnackbar(
        'Error',
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, String>> _getDeviceMeta() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'id': '${info.id}',
          'name': '${info.brand} ${info.model}',
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'id': info.identifierForVendor ?? 'ios-device',
          'name': '${info.utsname.machine} ${info.model}',
        };
      }
    } catch (_) {
      // ignore errors, will fallback below
    }
    return {
      'id': 'unknown-device',
      'name': Platform.operatingSystem,
    };
  }

  void _updateFormValidity() {
    final emailValid = AppValidators.validateEmail(emailController.text.trim()) == null;
    final passwordValid = AppValidators.validatePassword(passwordController.text) == null;
    isFormValid.value = emailValid && passwordValid;
  }

  Future<void> logout() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      // 1️⃣ Try logout API (NON-blocking)
      try {
        final deviceMeta = await _getDeviceMeta();
        final deviceId = deviceMeta['id'] ?? 'unknown-device';
        await authRepository.logout(deviceId: deviceId);
      } catch (e) {
        _logger.e('⚠️ Logout API failed, continuing local logout: $e');
      }

      // 2️⃣ FCM cleanup (already safe)
      try {
        final fcmService = getIt<FCMService>();
        await fcmService.logoutCleanup();
      } catch (e) {
        _logger.e('⚠️ Error during FCM cleanup: $e');
      }

      // 3️⃣ Local cleanup (ALWAYS runs)
      await secureStorage.clearAll();

      const boxName = 'api_cache_box';
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<String>(boxName).clear();
        await Hive.box<String>(boxName).close();
      } else if (await Hive.boxExists(boxName)) {
        final box = await Hive.openBox<String>(boxName);
        await box.clear();
        await box.close();
      }

      const statusBoxName = 'topic_media_status_box';
      if (Hive.isBoxOpen(statusBoxName)) {
        await Hive.box<String>(statusBoxName).clear();
      } else if (await Hive.boxExists(statusBoxName)) {
        final statusBox = await Hive.openBox<String>(statusBoxName);
        await statusBox.clear();
      }

      // 4️⃣ File cleanup
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final libraryDir = Directory('${appDir.path}/library');
        if (await libraryDir.exists()) {
          await libraryDir.delete(recursive: true);
        }
      } catch (e) {
        _logger.e('Failed to clear library media dir: $e');
      }

      // 5️⃣ Controller cleanup
      if (Get.isRegistered<HologramController>()) {
        final holo = Get.find<HologramController>();
        holo.topicMedia.clear();
        holo.topicMedia.refresh();
      }

      if (Get.isRegistered<ConnectionController>()) {
        Get.delete<ConnectionController>(force: true);
      }

      emailController.clear();
      passwordController.clear();
      isFormValid.value = false;

      // 6️⃣ Navigate to login (ALWAYS)
      Get.offAllNamed(AppRoutes.login);

    } finally {
      isLoading.value = false;
    }
  }

}

