// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:vizlearn/views/widgets/scrolling_dot.dart';
// import 'custom_image_view.dart';
//
// class CustomImageCarousel extends StatefulWidget {
//   final List<String> images;
//   final double? height; // make it optional
//   final bool autoPlay;
//   final bool showIndicators;
//   final bool showIndicatorsOnImage;
//
//   const CustomImageCarousel({
//     super.key,
//     required this.images,
//     this.height,
//     this.autoPlay = true,
//     this.showIndicators = false,
//     this.showIndicatorsOnImage = false,
//   });
//
//   @override
//   State<CustomImageCarousel> createState() => _CustomImageCarouselState();
// }
//
// class _CustomImageCarouselState extends State<CustomImageCarousel> {
//   int _currentIndex = 0;
//
//   double _getResponsiveHeight(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     if (screenWidth < 600) {
//       // 📱 Mobile
//       return widget.height ?? 220; // ~25% of screen height
//     } else if (screenWidth < 1024) {
//       // 📲 Tablet
//       return widget.height ?? 300;
//     } else {
//       // 💻 Desktop/Web
//       return widget.height ?? 400;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final responsiveHeight = _getResponsiveHeight(context);
//
//     final carousel = CarouselSlider(
//       options: CarouselOptions(
//         height: responsiveHeight,
//         viewportFraction: 1.0,
//         enableInfiniteScroll: widget.images.length > 1,
//         autoPlay: widget.autoPlay,
//         autoPlayInterval: const Duration(seconds: 3),
//         enlargeCenterPage: false,
//         onPageChanged: (index, reason) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//       items: widget.images.map((imagePath) {
//         return CustomImageView(
//           imagePath: imagePath,
//           height: responsiveHeight,
//           width: double.infinity,
//           fit: BoxFit.contain,
//         );
//       }).toList(),
//     );
//
//     return Stack(
//       alignment: Alignment.bottomCenter,
//       children: [
//         Column(
//           children: [
//             carousel,
//             if (widget.showIndicators && !widget.showIndicatorsOnImage)
//               const SizedBox(height: 8),
//             if (widget.showIndicators && !widget.showIndicatorsOnImage)
//               ScrollingDots(
//                 index: _currentIndex,
//                 count: widget.images.length,
//               ),
//           ],
//         ),
//         if (widget.showIndicators && widget.showIndicatorsOnImage)
//           Positioned(
//             bottom: 10,
//             left: 0,
//             right: 0,
//             child: ScrollingDots(
//               index: _currentIndex,
//               count: widget.images.length,
//             ),
//           ),
//       ],
//     );
//   }
// }
