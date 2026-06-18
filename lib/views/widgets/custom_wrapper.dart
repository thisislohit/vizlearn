import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants/colors.dart';
import '../../gen/assets.gen.dart';
import 'custom_image_view.dart';
import 'testing_cache_clear_button.dart';

class CustomWrapper extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavBar;
  final Widget? appBar;
  const CustomWrapper({super.key, required this.child, this.bottomNavBar, this.appBar});

  @override
  Widget build(BuildContext context) {
    // Get screen size before keyboard affects it
    final screenSize = MediaQuery.of(context).size;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevent resizing when keyboard opens
        bottomNavigationBar: bottomNavBar,
        body: SafeArea(
          bottom: true,
          top: false,
          child: Stack(
            children: [
              // Background image - use fixed screen size
              Positioned.fill(
                child: CustomImageView(
                  imagePath: Assets.images.appBackground.path,
                  width: screenSize.width,
                  height: screenSize.height,
                  fit: BoxFit.cover,
                ),
              ),
              // Radial gradient overlay - vertical oval shape (elliptical)
              Positioned.fill(
                child: Transform.scale(
                  scaleX: 1.0,
                  scaleY: 1.5, // Stretch vertically to create vertical oval
                  child: Container(
                    width: screenSize.width,
                    height: screenSize.height,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.1), // 50% horizontal, 39.65% from top
                        radius: 0.6, // Increased radius to spread the gradient more
                        colors: [
                          const Color(0xFF2296F6).withOpacity(0.1), // #118DF3 - semi-transparent
                          const Color(0xFF031E58).withOpacity(0.9), // #031E58 - semi-transparent
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Column(
                children: [
                  appBar ?? SizedBox(),
                  Expanded(child: child),
                ],
              ),

              // const TestingCacheClearButton(opacity: 0.75),

              // Bottom navigation bar positioned at bottom
              // if (bottomNavBar != null)
              //   Positioned(
              //     left: 0,
              //     right: 0,
              //     bottom: 0,
              //     child: bottomNavBar!,
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
