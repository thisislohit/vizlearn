import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_font.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/extensions/sizedbox_extensions.dart';
import '../../controllers/ar_controller.dart';

/// Drop this widget into a [Stack] wrapped in a [Positioned] or aligned at top.
class ArStatusIndicator extends StatelessWidget {
  const ArStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ArController>();

    return Obx(() {
      final phase = ctrl.scanPhase.value;
      if (phase == ArScanPhase.modelReady) return const SizedBox.shrink();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Center(
            child: _StatusPill(
              label: ctrl.scanStatusLabel,
              phase: phase,
            ),
          ),
        ),
      );
    });
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final ArScanPhase phase;

  const _StatusPill({required this.label, required this.phase});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _style(phase);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 18),
              8.wS,
            ] else ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              ),
              8.wS,
            ],
            Text(label, style: AppFont.w700.s14.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }

  (Color bg, Color fg, IconData? icon) _style(ArScanPhase phase) {
    return switch (phase) {
      ArScanPhase.initializing => (
          Colors.black87,
          Colors.white,
          null,
        ),
      ArScanPhase.scanning => (
          Colors.black87,
          Colors.white,
          null,
        ),
      ArScanPhase.markerFound => (
          AppColors.darkGreen.withOpacity(0.9),
          Colors.white,
          Icons.check_circle_rounded,
        ),
      ArScanPhase.modelLoading => (
          AppColors.primary.withOpacity(0.9),
          Colors.white,
          null,
        ),
      ArScanPhase.modelReady => (
          AppColors.darkGreen.withOpacity(0.9),
          Colors.white,
          Icons.check_circle_rounded,
        ),
      ArScanPhase.error => (
          AppColors.red.withOpacity(0.9),
          Colors.white,
          Icons.error_outline_rounded,
        ),
    };
  }
}

/// Scanning animation shown when no marker is detected yet.
class ArScanningFrame extends StatefulWidget {
  const ArScanningFrame({super.key});

  @override
  State<ArScanningFrame> createState() => _ArScanningFrameState();
}

class _ArScanningFrameState extends State<ArScanningFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(painter: _CornerFramePainter()),
        ),
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double corner = 30;
    const double r = 10;

    // Top-left
    canvas.drawLine(Offset(r, 0), Offset(corner, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, corner), paint);
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, r * 2, r * 2),
      3.14159,
      -3.14159 / 2,
      false,
      paint,
    );

    // Top-right
    canvas.drawLine(Offset(size.width - corner, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, corner), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
      -3.14159 / 2,
      -3.14159 / 2,
      false,
      paint,
    );

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - corner), Offset(0, size.height - r), paint);
    canvas.drawLine(Offset(r, size.height), Offset(corner, size.height), paint);
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
      3.14159 / 2,
      3.14159 / 2,
      false,
      paint,
    );

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - corner, size.height), Offset(size.width - r, size.height), paint);
    canvas.drawLine(
        Offset(size.width, size.height - corner), Offset(size.width, size.height - r), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
      0,
      3.14159 / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
