import 'package:get/get.dart';

import '../../data/models/side_menu/cms_model.dart';
import '../../data/repositories/side_menu/cms_repository.dart';
import '../../utils/app_utils.dart';
import '../../utils/enums.dart';

abstract class CmsContentController extends GetxController {
  CmsContentController({required this.repository, required this.type});

  final CMSRepository repository;
  final CmsContentType type;

  final Rx<CmsContentData?> content = Rx<CmsContentData?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  bool _isRefreshing = false;

  @override
  void onInit() {
    super.onInit();
    _hydrateFromCache();
  }

  Future<void> _hydrateFromCache() async {
    isLoading.value = true;
    try {
      final cached = await repository.getCachedContent(type);
      if (cached != null) {
        final model = CmsContentResponse.fromJson(cached);
        final entry = _extractEntry(model);
        if (entry != null) {
          content.value = entry;
          content.refresh();
        }
      }
    } catch (_) {
      // ignore cache failures
    } finally {
      if (content.value == null) {
        await fetchContent(showLoader: false);
      }
      isLoading.value = false;
    }
  }

  Future<void> fetchContent({
    bool refresh = false,
    bool showLoader = true,
  }) async {
    if (!refresh && content.value != null) {
      return;
    }

    try {
      if (showLoader) {
        isLoading.value = true;
      }

      final response = await repository.fetchContent(type);
      final model = CmsContentResponse.fromJson(response);
      final entry = _extractEntry(model);
      if (entry != null) {
        content.value = entry;
        content.refresh();
      } else {
        errorMessage.value = 'No content available';
      }
    } catch (e) {
      errorMessage.value = e.toString();
      AppUtils.showGetSnackbar('Error', e.toString());
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshContent() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchContent(refresh: true, showLoader: false);
    } finally {
      _isRefreshing = false;
    }
  }

  CmsContentData? _extractEntry(CmsContentResponse response) {
    final key = _contentKey(type);
    return response.entries[key];
  }

  String _contentKey(CmsContentType type) {
    switch (type) {
      case CmsContentType.privacyPolicy:
        return 'privacy_policy';
      case CmsContentType.termsAndConditions:
        return 'terms_and_conditions';
      case CmsContentType.whyChooseUs:
        return 'why_choose_us';
      case CmsContentType.aboutUs:
        return 'about_us';
    }
  }
}

class AboutUsController extends CmsContentController {
  AboutUsController(CMSRepository repository)
    : super(repository: repository, type: CmsContentType.aboutUs);
}

class PrivacyPolicyController extends CmsContentController {
  PrivacyPolicyController(CMSRepository repository)
    : super(repository: repository, type: CmsContentType.privacyPolicy);
}

class TermsController extends CmsContentController {
  TermsController(CMSRepository repository)
    : super(repository: repository, type: CmsContentType.termsAndConditions);
}

class WhyChooseController extends CmsContentController {
  WhyChooseController(CMSRepository repository)
    : super(repository: repository, type: CmsContentType.whyChooseUs);
}
