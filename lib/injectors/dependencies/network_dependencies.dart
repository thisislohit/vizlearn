import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:get_it/get_it.dart';

import '../../utils/network/network_checker.dart';

final getIt = GetIt.I;

void registerNetworkDependencies() {
  // Network Info
  getIt.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.createInstance(),
  );

  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfo(getIt<InternetConnectionChecker>()),
  );
}

