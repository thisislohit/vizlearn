import 'package:get/get.dart';

class TechnologiesController extends GetxController {
  // Expanded items for accordion
  final RxList<String> expandedItems = <String>[].obs;

  // Toggle item expansion
  void toggleItem(String itemId) {
    if (expandedItems.contains(itemId)) {
      expandedItems.remove(itemId);
    } else {
      expandedItems.add(itemId);
    }
  }

  // Check if item is expanded
  bool isItemExpanded(String itemId) {
    return expandedItems.contains(itemId);
  }

  @override
  void onClose() {
    expandedItems.clear();
    super.onClose();
  }
}

