import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/side_menu/contact_us_model.dart';
import '../../data/repositories/side_menu/contact_us_repository.dart';
import '../../utils/app_utils.dart';
import '../../utils/enums.dart';

class ContactUsController extends GetxController {
  final ContactUsRepository repository;

  ContactUsController(this.repository);

  final Rx<ContactUsData?> contactData = Rx<ContactUsData?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _hydrateFromCache();
  }

  Future<void> _hydrateFromCache() async {
    isLoading.value = true;
    try {
      final cached = await repository.getCachedContactUs();
      if (cached != null) {
        final model = ContactUsResponse.fromJson(cached);
        contactData.value = model.data;
        contactData.refresh();
      }
    } catch (e) {
      log("Contact us failure: ${e.toString()}");
      // ignore cache failures
    } finally {
      if (contactData.value == null) {
        await fetchContactUs(showLoader: false);
        isLoading.value = false; // Ensure loading is stopped after fetch
      } else {
        isLoading.value = false;
      }
    }
  }

  Future<void> fetchContactUs({bool refresh = false, bool showLoader = true}) async {
    if (!refresh && contactData.value != null) {
      return;
    }

    try {
      if (showLoader) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final response = await repository.fetchContactUs();
      final model = ContactUsResponse.fromJson(response);
      contactData.value = model.data;
      contactData.refresh();
    } catch (e) {
      errorMessage.value = e.toString();
      AppUtils.showGetSnackbar('Error' , e.toString());
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshContactUs() async {
      await fetchContactUs(refresh: true, showLoader: false);
  }
}

