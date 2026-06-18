import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/gen/assets.gen.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_image_view.dart';
import '../../routes/app_routes.dart';

class ShakingNotificationIcon extends StatefulWidget {
  const ShakingNotificationIcon({super.key});

  @override
  State<ShakingNotificationIcon> createState() => _ShakingNotificationIconState();
}

class _ShakingNotificationIconState extends State<ShakingNotificationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _minuteTimer;
  Timer? _stopShakeTimer;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _startShake();
    _minuteTimer = Timer.periodic(const Duration(seconds: 15), (_) => _startShake());
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _stopShakeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startShake() {
    _stopShakeTimer?.cancel();
    _controller.repeat();
    setState(() => _isShaking = true);
    _stopShakeTimer = Timer(const Duration(seconds: 5), _stopShake);
  }

  void _stopShake() {
    if (!mounted) return;
    _controller.stop();
    setState(() => _isShaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_isShaking) {
          return child!;
        }

        final wave = math.sin(_controller.value * 2 * math.pi);
        return Transform.translate(
          offset: Offset(wave * 3.5, 0),
          child: Transform.rotate(
            angle: wave * 0.08,
            child: child,
          ),
        );
      },
      child: CustomImageView(
        imagePath: Assets.icons.notification.path,
        width: 45,
        height: 45,
        onTap: () => Get.toNamed(AppRoutes.notifications),
        circularSplash: true,
      ),
    );
  }
}

