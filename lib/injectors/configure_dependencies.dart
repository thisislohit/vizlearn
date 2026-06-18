import 'package:get_it/get_it.dart';
import 'dependencies/core_dependencies.dart';
import 'dependencies/library_dependencies.dart';
import 'dependencies/network_dependencies.dart';
import 'dependencies/auth_dependencies.dart';
import 'dependencies/notification_dependencies.dart';

final getIt = GetIt.I;

void configureDependencies() {
  // Register core dependencies (storage, API, etc.)
  registerCoreDependencies();

  // Register network dependencies
  registerNetworkDependencies();

  // Register auth dependencies
  registerAuthDependencies();

  // Register library dependencies
  registerLibraryDependencies();

  // Register notification dependencies
  registerNotificationDependencies();
}

// This function will be called to initialize all dependencies
Future<void> init() async {
  configureDependencies();
  await getIt.allReady();
}
