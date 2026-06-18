class ApiUrl {
  const ApiUrl._();
  // static const String baseUrl = 'http://192.168.0.92:8081/api/v1/';
  // static const String baseUrl = 'https://api.vizlearn.co.in/api/v1/';
  static const String baseUrl = 'https://dev-api.vizlearn.co.in/api/v1/';

  // CMS Endpoints
  static const String aboutUs = "cms/about_us";
  static const String contactUs = "contactus";
  static const String privacyPolicy = "cms/privacy_policy";
  static const String termsAndConditions = "cms/terms_and_conditions";
  static const String whyChooseUs = "cms/why_choose_us";

  // Auth
  static const String login = "schools/login";
  static const String logout = "schools/logout";
  static const String updateProfile = "schools/updateprofile";
  static const String getProfile = "schools/getprofile";

  // Library
  static const String categoriesActive = "categories/active";
  static String subjectsByCategory(int categoryId) =>
      "subjects/category/$categoryId";
  static String topicsBySubject(int subjectId, {String? type}) =>
      "topics/subject/$subjectId${type != null ? '?type=$type' : ''}";
  // Notifications
  static const String schoolNotifications = "notifications/notification-school";
  static String markAsRead(int notificationId) =>
      "notifications/markasread/$notificationId";

  // AR
  static const String arSyncMeta = "ar/mobile/sync-meta";
  static const String arMarkers = "ar/mobile/markers";
  static String arContentById(int id) => "ar/mobile/$id";
  static String arContentByMarkerId(String markerId) => "ar/mobile/by-marker/$markerId";
}
