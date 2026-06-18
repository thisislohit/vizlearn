import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/theme/app_font.dart';
import '../../gen/assets.gen.dart';
import '../../utils/app_export.dart';
import '../../controllers/bottom_nav_controller.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final List<GlobalKey<_ShakingNavIconState>> _iconKeys = [
    GlobalKey<_ShakingNavIconState>(),
    GlobalKey<_ShakingNavIconState>(),
    GlobalKey<_ShakingNavIconState>(),
    GlobalKey<_ShakingNavIconState>(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BottomNavController>();
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF031E58),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  controller: controller,
                  index: 0,
                  icon: Assets.icons.home,
                  label: 'VizLearn Home',
                  iconKey: _iconKeys[0],
                ),
                _buildNavItem(
                  controller: controller,
                  index: 1,
                  icon: Assets.icons.basicControls,
                  label: 'Basic Controls',
                  iconKey: _iconKeys[1],
                ),
                _buildNavItem(
                  controller: controller,
                  index: 2,
                  icon: Assets.icons.advancedControls,
                  label: 'Advanced Controls',
                  iconKey: _iconKeys[2],
                ),
                _buildNavItem(
                  controller: controller,
                  index: 3,
                  icon: Assets.icons.deviceSpecs,
                  label: 'Device Specifications',
                  iconKey: _iconKeys[3],
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildNavItem({
    required BottomNavController controller,
    required int index,
    required AssetGenImage icon,
    required String label,
    required GlobalKey<_ShakingNavIconState> iconKey,
  }) {
    final isSelected = controller.currentIndex.value == index;
    final formattedLabel = label.replaceAll(' ', '\n');

    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.changeIndex(index);
          if (isSelected) {
            iconKey.currentState?.startShake();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with scale and shake animation
            AnimatedScale(
              scale: isSelected ? 1.15 : 0.9,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: 56,
                height: 56,
                child: isSelected
                    ? _ShakingNavIcon(
                        key: iconKey,
                        icon: icon,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            AppColors.white.withOpacity(0.3),
                            BlendMode.modulate,
                          ),
                          child: CustomImageView(
                            imagePath: icon.path,
                            width: 56,
                            height: 56,
                          ),
                        ),
                      ),
              ),
            ),
            4.hS,
            // Label
            Text(
              formattedLabel,
              style: AppFont.w700.s10.copyWith(color: isSelected ? AppColors.white : const Color(0xFF478ED4),),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShakingNavIcon extends StatefulWidget {
  const _ShakingNavIcon({super.key, required this.icon});

  final AssetGenImage icon;

  @override
  State<_ShakingNavIcon> createState() => _ShakingNavIconState();
}

class _ShakingNavIconState extends State<_ShakingNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _stopShakeTimer;
  bool _isShaking = false;
  DateTime? _shakeStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _startShake();
  }

  @override
  void dispose() {
    _stopShakeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void startShake() {
    _startShake();
  }

  void _startShake() {
    _stopShakeTimer?.cancel();
    _controller.repeat();
    _shakeStartTime = DateTime.now();
    setState(() => _isShaking = true);
    _stopShakeTimer = Timer(const Duration(seconds: 3), _stopShake);
  }

  void _stopShake() {
    if (!mounted) return;
    _controller.stop();
    _shakeStartTime = null;
    setState(() => _isShaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!_isShaking || _shakeStartTime == null) {
            return child!;
          }

          // Calculate elapsed time in seconds
          final elapsedSeconds = DateTime.now().difference(_shakeStartTime!).inMilliseconds / 1000.0;

          // Damping factor: exponential decay over 3 seconds
          // Starts at 1.0 and decreases to near 0
          final dampingFactor = math.sin(-elapsedSeconds * 1);

          final wave = math.sin(_controller.value * 2 * math.pi);
          final amplitude = 10.5 * dampingFactor;

          return Transform.translate(
            offset: Offset(0, wave * amplitude),
            child: Transform.rotate(
              angle: wave * 0.3 * dampingFactor,
              child: child,
            ),
          );
        },
        child: CustomImageView(
          imagePath: widget.icon.path,
          width: 56,
          height: 56,
        ),
    );
  }
}

