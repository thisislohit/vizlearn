// import 'package:get/get.dart';
// import '../controllers/fcm_controller.dart';
//
// class FCMHelper {
//   static FCMController get _fcmController => Get.find<FCMController>();
//
//   /// Get current FCM token
//   static String? get currentToken => _fcmController.fcmToken.value;
//
//   /// Check if FCM token is available
//   static bool get isTokenAvailable => _fcmController.isTokenAvailable.value;
//
//   /// Check if FCM is initializing
//   static bool get isInitializing => _fcmController.isInitializing.value;
//
//   /// Get FCM token asynchronously
//   static Future<String?> getToken() async {
//     return await _fcmController.getCurrentToken();
//   }
//
//   /// Refresh FCM token
//   static Future<void> refreshToken() async {
//     await _fcmController.refreshToken();
//   }
//
//   /// Subscribe to a topic
//   static Future<void> subscribeToTopic(String topic) async {
//     await _fcmController.subscribeToTopic(topic);
//   }
//
//   /// Unsubscribe from a topic
//   static Future<void> unsubscribeFromTopic(String topic) async {
//     await _fcmController.unsubscribeFromTopic(topic);
//   }
//
//   /// Wait for FCM token to be available
//   static Future<String?> waitForToken({Duration timeout = const Duration(seconds: 10)}) async {
//     final stopwatch = Stopwatch()..start();
//
//     while (stopwatch.elapsed < timeout) {
//       if (isTokenAvailable && currentToken != null && currentToken!.isNotEmpty) {
//         return currentToken;
//       }
//       await Future.delayed(const Duration(milliseconds: 100));
//     }
//
//     return null;
//   }
// }
