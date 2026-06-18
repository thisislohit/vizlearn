import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_font.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/extensions/sizedbox_extensions.dart';
import '../../controllers/ar_controller.dart';

/// Floating overlay controls shown while a 3D model is visible.
/// Must be placed inside a Stack, wrapped with a bottom Positioned by the parent.
/// All touch targets are large (min 56 px) for young children.
class ArControlsOverlay extends StatelessWidget {
  final VoidCallback onResetPosition;

  const ArControlsOverlay({super.key, required this.onResetPosition});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = Get.find<ArController>();
      if (!ctrl.isModelVisible.value) return const SizedBox.shrink();
      return SafeArea(child: _buildPanel(ctrl));
    });
  }

  Widget _buildPanel(ArController ctrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker title
          if (ctrl.detectedMarker.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                ctrl.detectedMarker.value!.title,
                style: AppFont.w700.s16,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.close_rounded,
                label: 'Close',
                color: AppColors.red,
                onTap: () => Get.find<ArController>().closeModel(),
              ),
              Obx(
                () => _ControlButton(
                  icon: ctrl.isAudioMuted.value
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  label: ctrl.isAudioMuted.value ? 'Unmute' : 'Mute',
                  color: ctrl.isAudioMuted.value
                      ? Colors.grey
                      : AppColors.buttonPrimary,
                  onTap: () => Get.find<ArController>().toggleMute(),
                ),
              ),
              _ControlButton(
                icon: Icons.replay_rounded,
                label: 'Replay',
                color: AppColors.info,
                onTap: () => Get.find<ArController>().replayAudio(),
              ),
              _ControlButton(
                icon: Icons.center_focus_strong_rounded,
                label: 'Reset',
                color: Colors.white70,
                onTap: onResetPosition,
              ),
            ],
          ),

          12.hS,

          // Gesture hint
          Text(
            'Pinch to scale  •  Drag to move  •  Two fingers to rotate',
            style: AppFont.w400.s11.copyWith(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          8.hS,
          Text(
            label,
            style: AppFont.w500.s11.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
