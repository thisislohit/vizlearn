import 'package:flutter/material.dart';

import '../../theme/app_font.dart';
import '../../utils/constants/colors.dart';

class CustomSwitchWithText extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitchWithText({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 30,
      child: Stack(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.buttonPrimary,
            inactiveTrackColor: const Color(0xFF979797),
            activeThumbColor: Colors.black,
            inactiveThumbColor: Colors.black,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            trackOutlineColor: WidgetStateProperty.all(value ? AppColors.buttonPrimary : Color(0xFF979797)),
          ),
          Positioned(
            left: value ? 12 : 32,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                value ? 'ON' : 'OFF',
                style: AppFont.w700.s8.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}