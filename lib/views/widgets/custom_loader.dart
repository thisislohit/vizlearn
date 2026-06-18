import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:load_it/load_it.dart';

import '../../theme/app_font.dart';
import '../../utils/app_export.dart';

enum LoaderStyle {
  flowBar,
  vortex,
  cubeSpinner,
  helix,
  dualRing,
}

class CustomLoader extends StatelessWidget {
  const CustomLoader({
    super.key,
    this.message,
    this.style = LoaderStyle.helix,
    this.size = 56,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
    this.padding,
    this.textStyle,
  });

  final String? message;
  final LoaderStyle style;
  final double size;
  final Color? color;
  final bool showBackground;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? AppColors.white.withOpacity(0.6);

    final loader = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIndicator(loaderColor),
        if (message?.isNotEmpty ?? false) ...[
          16.hS,
          Text(
            message!,
            style: textStyle ?? AppFont.w600.s16,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    final decorated = showBackground
        ? Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: (backgroundColor ?? AppColors.primary.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: loader,
          )
        : Padding(
            padding: padding ?? EdgeInsets.zero,
            child: loader,
          );

    return Center(child: decorated);
  }

  Widget _buildIndicator(Color loaderColor) {
    switch (style) {
      case LoaderStyle.vortex:
        return VortexSpinnerIndicator(color: loaderColor, size: size);
      case LoaderStyle.cubeSpinner:
        return CubeSpinnerIndicator(color: loaderColor, size: size);
      case LoaderStyle.helix:
        return HelixSpinLoader(color: loaderColor, size: size);
      case LoaderStyle.dualRing:
        return DualRingIndicator(color: loaderColor, size: size);
      case LoaderStyle.flowBar:
        return _SafeFlowBarLoader(color: loaderColor, size: size);
    }
  }
}

class _SafeFlowBarLoader extends StatefulWidget {
  const _SafeFlowBarLoader({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_SafeFlowBarLoader> createState() => _SafeFlowBarLoaderState();
}

class _SafeFlowBarLoaderState extends State<_SafeFlowBarLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              final phase = progress * 2 * math.pi + (index * math.pi / 2);
              final wave = (math.sin(phase) + 1) / 2;
              final barHeight = (wave * widget.size).clamp(widget.size * 0.25, widget.size);
              return Container(
                width: widget.size * 0.16,
                height: barHeight,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.size * 0.08),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}