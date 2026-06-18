import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';
class TextFieldLabel extends StatelessWidget {
  const TextFieldLabel({super.key, required this.label, this.isMandatory = true, this.style, this.color});
  final String label;
  final bool isMandatory;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: style ?? CustomTextStyles.b4.copyWith(
                  color: color,
                ),
              ),
              if(isMandatory)
                TextSpan(
                text: "*",
                style: style?.copyWith(color: AppColors.primary) ?? CustomTextStyles.b4Primary,
              ),
            ],
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
