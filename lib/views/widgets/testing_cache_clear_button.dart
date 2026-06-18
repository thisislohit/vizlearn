import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../controllers/hologram_controller.dart';

class TestingCacheClearButton extends StatefulWidget {
  final double opacity;

  const TestingCacheClearButton({super.key, this.opacity = 1});

  @override
  State<TestingCacheClearButton> createState() => _TestingCacheClearButtonState();
}

class _TestingCacheClearButtonState extends State<TestingCacheClearButton> {
  Offset position = const Offset(20, 120);
  bool _clearing = false;

  Future<void> _clearCache() async {
    if (_clearing) return;
    setState(() => _clearing = true);
    try {
      // Clear all API response cache (api_cache_box)
      const apiBoxName = 'api_cache_box';
      if (Hive.isBoxOpen(apiBoxName)) {
        await Hive.box<String>(apiBoxName).clear();
      } else if (await Hive.boxExists(apiBoxName)) {
        final box = await Hive.openBox<String>(apiBoxName);
        await box.clear();
      }

      // Clear topic media status cache (used by HologramController)
      const statusBoxName = 'topic_media_status_box';
      if (Hive.isBoxOpen(statusBoxName)) {
        await Hive.box<String>(statusBoxName).clear();
      } else if (await Hive.boxExists(statusBoxName)) {
        final statusBox = await Hive.openBox<String>(statusBoxName);
        await statusBox.clear();
      }

      // Reset in-memory hologram media status so sync can redownload files
      if (Get.isRegistered<HologramController>()) {
        final holo = Get.find<HologramController>();
        holo.topicMedia.clear();
        holo.topicMedia.refresh();
      }

      // Clear all local media under /library (topics, categories, etc.)
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final libraryDir = Directory('${appDir.path}/library');
        if (await libraryDir.exists()) {
          await libraryDir.delete(recursive: true);
        }
      } catch (e) {
        log('Failed to clear library media dir: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('[TEST] Cache and media cleared')),
        );
      }
    } catch (e) {
      log(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('[TEST] Failed to clear cache/media: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Opacity(
        opacity: widget.opacity,
        child: Draggable(
          feedback: _buildButton(),
          childWhenDragging: Text('I was here'),
          onDragEnd: (details) {
            setState(() {
              position = Offset(
                details.offset.dx.clamp(12, MediaQuery.of(context).size.width - 72),
                details.offset.dy.clamp(80, MediaQuery.of(context).size.height - 160),
              );
            });
          },
          child: _buildButton(),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: _clearing ? null : _clearCache,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _clearing
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Icon(
                Icons.delete_forever,
                color: Colors.white,
              ),
      ),
    );
  }
}

