import 'dart:ui';

import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final BorderRadius borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(borderRadius.topLeft.x, -1);
    path.lineTo(size.width - borderRadius.topRight.x, -1);

    // Add top-right corner
    path.arcToPoint(
      Offset(size.width, borderRadius.topRight.y),
      radius: borderRadius.topRight,
      clockwise: true,
    );

    // Add right border
    path.lineTo(size.width, size.height - borderRadius.bottomRight.y);

    // Add bottom-right corner
    path.arcToPoint(
      Offset(size.width - borderRadius.bottomRight.x, size.height),
      radius: borderRadius.bottomRight,
      clockwise: true,
    );

    // Add bottom border
    path.lineTo(borderRadius.bottomLeft.x, size.height);

    // Add bottom-left corner
    path.arcToPoint(
      Offset(0, size.height - borderRadius.bottomLeft.y),
      radius: borderRadius.bottomLeft,
      clockwise: true,
    );

    // Add left border
    path.lineTo(0, borderRadius.topLeft.y);

    // Add top-left corner
    path.arcToPoint(
      Offset(borderRadius.topLeft.x, -2),
      radius: borderRadius.topLeft,
      clockwise: true,
    );

    final dashPath = Path();

    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(
            distance,
            distance + gap,
          ),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
