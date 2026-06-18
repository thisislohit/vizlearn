import 'package:flutter/material.dart';

class CloudShape extends StatelessWidget {
  final String text;
  final Color color;
  final TextStyle textStyle;

  const CloudShape({
    super.key,
    required this.text,
    required this.color,
    required this.textStyle,
  });

  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    final textWidth = _measureTextWidth(text, textStyle);
    final cloudWidth = textWidth + 20; // padding left+right
    final cloudHeight = textWidth/8 + 30.0;

    return CustomPaint(
      size: Size(cloudWidth, cloudHeight),
      painter: _CloudPainter(color),
      child: SizedBox(
        width: cloudWidth,
        height: cloudHeight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              text,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final Color color;

  _CloudPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    final centerY = size.height * 0.6;
    final puffRadius = size.height * 0.25;

    final puffCenters = [
      Offset(size.width * 0.15, centerY),
      Offset(size.width * 0.3, centerY - puffRadius),
      Offset(size.width * 0.5, centerY - puffRadius * 1.2),
      Offset(size.width * 0.7, centerY - puffRadius),
      Offset(size.width * 0.85, centerY),
      Offset(size.width * 0.7, centerY + puffRadius * 0.8),
      Offset(size.width * 0.5, centerY + puffRadius),
      Offset(size.width * 0.3, centerY + puffRadius * 0.8),
    ];

    for (var c in puffCenters) {
      path.addOval(Rect.fromCircle(center: c, radius: puffRadius));
    }

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.15,
          centerY - puffRadius,
          size.width * 0.7,
          puffRadius * 2,
        ),
        Radius.circular(puffRadius * 0.6),
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
