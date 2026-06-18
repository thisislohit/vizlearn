// import 'package:get/get.dart';
// import 'package:injectable/injectable.dart';
// import '../services/fcm_service.dart';
// import '../utils/app_utils.dart';
// import '../utils/enums.dart';
//
// @injectable
// class FCMController extends GetxController {
//   final FCMService _fcmService;
//
//   FCMController(this._fcmService);
//
//   var fcmToken = ''.obs;
//   var isInitializing = false.obs;
//   var isTokenAvailable = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     initializeFCM();
//   }
//
//   /// Subscribe to users topic on initialization
//   Future<void> subscribeToUsersTopic() async {
//     await subscribeToTopic('users');
//   }
//
//   /// Initialize FCM and get token
//   Future<void> initializeFCM() async {
//     try {
//       isInitializing.value = true;
//       final token = await _fcmService.initializeFCM();
//
//       if (token != null && token.isNotEmpty) {
//         fcmToken.value = token;
//         isTokenAvailable.value = true;
//       } else {
//         isTokenAvailable.value = false;
//         AppUtils.showToastMessage(
//           'Failed to get FCM token',
//           toastType: ToastType.error,
//         );
//       }
//     } catch (e) {
//       isTokenAvailable.value = false;
//       AppUtils.showToastMessage(
//         'Error initializing FCM: $e',
//         toastType: ToastType.error,
//       );
//     } finally {
//       isInitializing.value = false;
//     }
//   }
//
//   /// Get current FCM token
//   Future<String?> getCurrentToken() async {
//     try {
//       final token = await _fcmService.getCurrentToken();
//       if (token != null && token.isNotEmpty) {
//         fcmToken.value = token;
//         isTokenAvailable.value = true;
//         return token;
//       }
//       return null;
//     } catch (e) {
//       AppUtils.showToastMessage(
//         'Error getting FCM token: $e',
//         toastType: ToastType.error,
//       );
//       return null;
//     }
//   }
//
//   /// Refresh FCM token
//   Future<void> refreshToken() async {
//     await getCurrentToken();
//   }
//
//   /// Subscribe to topic
//   Future<void> subscribeToTopic(String topic) async {
//     try {
//       await _fcmService.subscribeToTopic(topic);
//       AppUtils.showToastMessage(
//         'Subscribed to $topic',
//         toastType: ToastType.success,
//       );
//     } catch (e) {
//       AppUtils.showToastMessage(
//         'Error subscribing to topic: $e',
//         toastType: ToastType.error,
//       );
//     }
//   }
//
//   /// Unsubscribe from topic
//   Future<void> unsubscribeFromTopic(String topic) async {
//     try {
//       await _fcmService.unsubscribeFromTopic(topic);
//       AppUtils.showToastMessage(
//         'Unsubscribed from $topic',
//         toastType: ToastType.success,
//       );
//     } catch (e) {
//       AppUtils.showToastMessage(
//         'Error unsubscribing from topic: $e',
//         toastType: ToastType.error,
//       );
//     }
//   }
// }
