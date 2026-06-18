import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'theme/theme.dart';
import 'utils/constants/colors.dart';
import 'services/fcm_service.dart';
import 'services/navigator_service.dart';
import 'injectors/configure_dependencies.dart';
import 'injectors/get_di.dart';

/// ===============================
/// MAIN (KEEP IT CLEAN)
/// ===============================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Firebase (INITIALIZE BEFORE RUNAPP)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const AppBootstrap());
}

/// ===============================
/// BOOTSTRAP
/// ===============================
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 🔹 Environment
    await dotenv.load(fileName: ".env");

    // 🔹 Timezone
    tz.initializeTimeZones();

    // 🔹 Hive (SAFE HERE)
    await Hive.initFlutter();

    // 🔹 Secure storage (first install)
    await _clearSecureStorageOnFirstInstall();

    // 🔹 DI
    await _initializeDependencies();

    // 🔹 Orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 🔹 Status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return const MyApp();
  }
}

/// ===============================
/// APP
/// ===============================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 🔹 FCM setup AFTER Firebase
    FCMService.setup();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: NavigatorService.navigatorKey,
      initialBinding: AppBindings(),
      debugShowCheckedModeBanner: false,
      getPages: AppRoutes.pages,
      title: 'VizLearn',
      theme: theme,
      initialRoute: AppRoutes.initial,
      transitionDuration: const Duration(milliseconds: 600),
      opaqueRoute: true,
    );
  }
}

/// ===============================
/// HELPERS
/// ===============================
Future<void> _initializeDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  if (!GetIt.I.isRegistered<SharedPreferences>()) {
    GetIt.I.registerSingleton<SharedPreferences>(prefs);
  }
  configureDependencies();
  await GetIt.I.allReady();
}

Future<void> _clearSecureStorageOnFirstInstall() async {
  final prefs = await SharedPreferences.getInstance();
  final firstInstall = prefs.getBool('isFirstInstall') ?? true;

  if (firstInstall) {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    await prefs.setBool('isFirstInstall', false);
  }
}
