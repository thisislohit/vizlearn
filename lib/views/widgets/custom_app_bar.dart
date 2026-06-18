import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';

import '../../gen/assets.gen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.elevation,
    this.height,
    this.styleType,
    this.leadingWidth,
    this.leading,
    this.leadingBack = true,
    this.onLeadingTap,
    this.title,
    this.titleWidget,
    this.textStyle,
    this.centerTitle,
    this.actions,
    this.shadowColor,
    this.backgroundColor,
    this.leadingBackColor,
    this.textColor,
  });

  final double? elevation;
  final double? height;
  final Style? styleType;
  final double? leadingWidth;
  final Widget? leading;
  final bool? leadingBack;
  final Function()? onLeadingTap;
  final String? title;
  final Widget? titleWidget;
  final TextStyle? textStyle;
  final bool? centerTitle;
  final List<Widget>? actions;
  final Color? shadowColor;
  final Color? backgroundColor;
  final Color? leadingBackColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation ?? 0,
      toolbarHeight: height ?? AppSizes.appBarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor ?? Colors.transparent,
      leadingWidth: leadingWidth ?? 64,
      leading: _leading(context),
      title: titleWidget ?? _buildTitle(),
      titleSpacing: 8,
      centerTitle: centerTitle ?? true,
      actions: actions,
      shadowColor: shadowColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(title ?? '', style: textStyle ?? AppFont.w700.s20.copyWith(color: AppColors.white));
  }

  Widget? _leading(BuildContext context) {
    if (leadingBack == false) {
      return Padding(padding: const EdgeInsets.only(left: AppSizes.md), child: leading);
    } else {
      return IconButton(
        onPressed: () {
          if (onLeadingTap != null) {
            onLeadingTap;
          } else {
            Navigator.pop(context);
          }
        },
        icon: Container(width: double.infinity,child: CustomImageView(color: leadingBackColor ?? AppColors.white, imagePath: Assets.icons.arrowBack, width: 24, height: 24)),
      );
    }
  }

  @override
  Size get preferredSize => Size(SizeUtils.width, height ?? AppSizes.appBarHeight);
}

enum Style { bgShadow }
