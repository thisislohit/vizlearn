import 'package:flutter/material.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_glass_dialog.dart';

void showARWarningDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  CustomGlassDialog.show(
    context: context,
    title: 'Warning',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This feature uses Augmented Reality.', style: AppFont.w700.s14),
        12.hS,
        _buildBulletPoint(
          'Please ensure parental supervision while using this feature.',
        ),
        8.hS,
        _buildBulletPoint('Be aware of your surroundings and avoid obstacles.'),
        8.hS,
        _buildBulletPoint('Use the app in a safe, open area.'),
        16.hS,
        Text('Tap Continue to proceed.', style: AppFont.w400.s14),
        24.hS,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomElevatedButton(
              text: 'Continue',
              height: 44,
              width: 100,
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildBulletPoint(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('• ', style: AppFont.w700.s14),
      4.wS,
      Expanded(child: Text(text, style: AppFont.w400.s14)),
    ],
  );
}
