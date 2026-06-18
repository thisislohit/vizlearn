import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../modules/ar/controllers/ar_controller.dart';
import '../../modules/ar/repositories/ar_marker_repository.dart';
import '../../modules/ar/services/ar_api_service.dart';
import '../../services/api_service.dart';

class ArBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ArController>(
      ArController(
        ArRepository(ArApiService(GetIt.I<APIService>())),
      ),
    );
  }
}
