import 'package:flutter/material.dart';

class GradientDivider extends StatelessWidget {
  final double height;
  final List<Color>? colors;
  final List<double>? stops;
  const GradientDivider({
    super.key,
    this.height = 2,
    this.colors,
    this.stops,
  });

  static const List<Color> _defaultColors = [
    Color(0x00118DF3),
    Color(0x40118DF3),
    Color(0xFF118DF3),
    Color(0x40118DF3),
    Color(0x00118DF3),
  ];

  static const List<double> _defaultStops = [0.0, 0.2404, 0.4856, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? _defaultColors;
    final gradientStops = stops ?? _defaultStops;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
          stops: gradientStops,
        ),
      ),
    );
  }
}

