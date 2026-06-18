import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_font.dart';
import '../../utils/app_export.dart';

class DialogOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  DialogOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class CustomGlassDialog extends StatelessWidget {
  final String title;
  final List<DialogOption>? options;
  final Widget? child;
  final double? barrierOpacity;
  final double? blurSigma;

  const CustomGlassDialog({
    super.key,
    required this.title,
    this.options,
    this.child,
    this.barrierOpacity = 0.25,
    this.blurSigma = 20,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    List<DialogOption>? options,
    Widget? child,
    double? barrierOpacity,
    double? blurSigma,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(barrierOpacity ?? 0.25),
      builder: (BuildContext context) {
        return CustomGlassDialog(
          title: title,
          options: options,
          child: child,
          barrierOpacity: barrierOpacity,
          blurSigma: blurSigma,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma ?? 20,
            sigmaY: blurSigma ?? 20,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppFont.w700.s20.copyWith(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(AppSizes.md),
                  child:
                      child ??
                      Column(
                        children: (options ?? []).asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < (options?.length ?? 0) - 1
                                  ? 12
                                  : 0,
                            ),
                            child: _buildOptionTile(
                              context: context,
                              option: option,
                            ),
                          );
                        }).toList(),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required DialogOption option,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          option.onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      option.color.withOpacity(0.8),
                      option.color.withOpacity(0.5),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, color: Colors.white, size: 24),
              ),
              16.wS,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: AppFont.w700.s16.copyWith(color: Colors.white),
                    ),
                    4.hS,
                    Text(
                      option.subtitle,
                      style: AppFont.w400.s12.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
