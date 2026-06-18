import 'package:get/get.dart';

class ChapterController extends GetxController {
  // Expanded chapters for accordion
  final RxList<String> expandedChapters = <String>[].obs;

  // Toggle chapter expansion
  void toggleChapter(String chapterId) {
    if (expandedChapters.contains(chapterId)) {
      expandedChapters.remove(chapterId);
    } else {
      expandedChapters.add(chapterId);
    }
  }

  // Check if chapter is expanded
  bool isChapterExpanded(String chapterId) {
    return expandedChapters.contains(chapterId);
  }

  // Expand a chapter
  void expandChapter(String chapterId) {
    if (!expandedChapters.contains(chapterId)) {
      expandedChapters.add(chapterId);
    }
  }

  // Collapse a chapter
  void collapseChapter(String chapterId) {
    expandedChapters.remove(chapterId);
  }

  // Collapse all chapters
  void collapseAll() {
    expandedChapters.clear();
  }

  @override
  void onClose() {
    expandedChapters.clear();
    super.onClose();
  }
}

