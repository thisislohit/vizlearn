import 'package:get/get.dart';
import 'package:vizlearn/views/screens/advanced_controls/advanced_controls_screen.dart';
import 'package:vizlearn/views/screens/basic_controls/basic_controls_screen.dart';
import 'package:vizlearn/views/screens/device_specs/device_specs_screen.dart';
import 'package:vizlearn/views/screens/library/chapters_screen.dart';
import 'package:vizlearn/views/screens/notifications/notification_screen.dart';
import 'package:vizlearn/views/screens/side_menu/about_us/about_us_screen.dart';
import 'package:vizlearn/views/screens/hologram_test/hologram_test_screen.dart';
import '../views/screens/side_menu/contact_us/contact_us_screen.dart';
import '../views/screens/side_menu/profile/profile_screen.dart';
import '../views/screens/side_menu/technologies/technologies_screen.dart';
import '../views/screens/side_menu/why_choose_vizlearn/why_choose_vizlearn_screen.dart';
import '../views/screens/library/yearly_addons_screen.dart';
import '../views/screens/side_menu/content_library/content_library_screen.dart';
import '../views/screens/side_menu/terms_and_conditions/terms_and_conditions_screen.dart';
import '../views/screens/side_menu/privacy_policy/privacy_policy_screen.dart';
import '../views/screens/splash/splash_screen.dart';
import '../views/screens/onboarding/onboarding_screens.dart';
import '../views/screens/login/login_screen.dart';
import '../views/screens/home/home_screen.dart';
import '../injectors/bindings/splash_binding.dart';
import '../injectors/bindings/onboarding_binding.dart';
import '../injectors/bindings/login_binding.dart';
import '../injectors/bindings/bottom_nav_binding.dart';
import '../injectors/bindings/drawer_binding.dart';
import '../injectors/bindings/hologram_binding.dart';
import '../injectors/bindings/library_binding.dart';
import '../injectors/bindings/chapter_binding.dart';
import '../injectors/bindings/technologies_binding.dart';
import '../injectors/bindings/notification_binding.dart';
import '../injectors/bindings/contact_us_binding.dart';
import '../injectors/bindings/about_us_binding.dart';
import '../injectors/bindings/privacy_policy_binding.dart';
import '../injectors/bindings/terms_binding.dart';
import '../injectors/bindings/why_choose_binding.dart';
import '../injectors/bindings/profile_binding.dart';
// AR module
import '../modules/ar/views/screens/ar_mode_selection_screen.dart';
import '../modules/ar/views/screens/ar_download_screen.dart';
import '../modules/ar/views/screens/ar_scanner_screen.dart';
import '../injectors/bindings/ar_binding.dart';

class AppRoutes {
  static const String initial = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String basicControls = '/basic-controls';
  static const String advancedControls = '/advanced-controls';
  static const String deviceSpecs = '/device-specifications';
  static const String hologramTest = '/hologram-test';
  static const String aboutUs = '/about-us';
  static const String contactUs = '/contact-us';
  static const String profile = '/profile';
  static const String technologies = '/technologies';
  static const String whyChooseVizlearn = '/why-choose-vizlearn';
  static const String chapters = '/chapters';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String privacyPolicy = '/privacy-policy';
  static const String yearlyAddons = '/yearly-addons';
  // AR module routes
  static const String arModeSelection = '/ar-mode-selection';
  static const String arDownload = '/ar-download';
  static const String arScanner = '/ar-scanner';

  static List<GetPage> pages = [
    GetPage(
      name: initial,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreens(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      bindings: [
        BottomNavBinding(),
        DrawerBinding(),
        HologramBinding(),
        LibraryBinding(),
      ],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationScreen(),
      binding: NotificationBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: basicControls,
      page: () => const BasicControlsScreen(),
      bindings: [BottomNavBinding(), DrawerBinding(), LibraryBinding()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: hologramTest,
      page: () => const HologramTestScreen(),
      bindings: [BottomNavBinding(), DrawerBinding(), HologramBinding()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: chapters,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return ChaptersScreen(
          categoryId: args?['categoryId'] ?? 0,
          categoryName: args?['categoryName'] ?? '',
          categoryType: args?['categoryType'],
        );
      },
      bindings: [LibraryBinding(), ChapterBinding()],
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: advancedControls,
      page: () => const AdvancedControlsScreen(),
      bindings: [BottomNavBinding(), DrawerBinding()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: deviceSpecs,
      page: () => const DeviceSpecsScreen(),
      bindings: [BottomNavBinding(), DrawerBinding()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: aboutUs,
      page: () => const AboutUsScreen(),
      binding: AboutUsBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: contactUs,
      page: () => const ContactUsScreen(),
      binding: ContactUsBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: technologies,
      page: () => const TechnologiesScreen(),
      binding: TechnologiesBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: whyChooseVizlearn,
      page: () => const WhyChooseVizlearnScreen(),
      binding: WhyChooseBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: termsAndConditions,
      page: () => const TermsAndConditionsScreen(),
      binding: TermsBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: privacyPolicy,
      page: () => const PrivacyPolicyScreen(),
      binding: PrivacyPolicyBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: yearlyAddons,
      page: () => const YearlyAddonsScreen(),
      binding: LibraryBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    // ── AR module ────────────────────────────────────────────────────────────
    // ArBinding is placed on arModeSelection so ArController stays alive
    // for the full AR flow (mode selection → download → scanner).
    // When the user exits AR mode entirely, it is disposed with this route.
    GetPage(
      name: arModeSelection,
      page: () => const ArModeSelectionScreen(),
      binding: ArBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: arDownload,
      page: () => const ArDownloadScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: arScanner,
      page: () => const ArScannerScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
