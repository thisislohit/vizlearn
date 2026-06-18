// import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view_gallery.dart';
// import 'package:vizlearn/utils/app_export.dart';
//
// class FullScreenImage extends StatefulWidget {
//   final String title;
//   final List<String> images;
//
//   const FullScreenImage({super.key, required this.images, required this.title});
//
//   @override
//   State<FullScreenImage> createState() => _FullScreenImageState();
// }
//
// class _FullScreenImageState extends State<FullScreenImage> {
//   late PageController _pageController;
//   int _currentIndex = 0;
//
//   bool _isNetworkImage(String path) {
//     return path.startsWith('http://') || path.startsWith('https://');
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController();
//   }
//
//   void _goToPrevious() {
//     if (_currentIndex > 0) {
//       _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
//     }
//   }
//
//   void _goToNext() {
//     if (_currentIndex < widget.images.length - 1) {
//       _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(title: widget.title),
//       body: Stack(
//         children: [
//           GestureDetector(
//             onTap: () => Navigator.pop(context),
//             child: Center(
//               child: PhotoViewGallery.builder(
//                 backgroundDecoration: const BoxDecoration(color: AppColors.primary2),
//                 itemCount: widget.images.length,
//                 builder: (BuildContext context, int index) {
//                   return PhotoViewGalleryPageOptions(imageProvider: _isNetworkImage(widget.images[index]) ? NetworkImage(widget.images[index]) : AssetImage(widget.images[index]) as ImageProvider);
//                 },
//                 pageController: _pageController,
//                 onPageChanged: (index) {
//                   setState(() {
//                     _currentIndex = index;
//                   });
//                 },
//               ),
//             ),
//           ),
//
//           /// Left arrow
//           if (_currentIndex > 0)
//             Positioned(
//               left: 10,
//               top: MediaQuery.of(context).size.height * 0.45,
//               child: IconButton(
//                 icon: Container(
//                   padding: EdgeInsets.all(AppSizes.sm),
//                   decoration: BoxDecoration(color: AppColors.white.withOpacity(0.7), shape: BoxShape.circle),
//                   child: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 28),
//                 ),
//                 onPressed: _goToPrevious,
//               ),
//             ),
//
//           /// Right arrow
//           if (_currentIndex < widget.images.length - 1)
//             Positioned(
//               right: 10,
//               top: MediaQuery.of(context).size.height * 0.45,
//               child: IconButton(
//                 icon: Container(
//                   decoration: BoxDecoration(color: AppColors.white.withOpacity(0.7), shape: BoxShape.circle),
//                   padding: EdgeInsets.all(AppSizes.sm),
//                   child: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 28),
//                 ),
//                 onPressed: _goToNext,
//               ),
//             ),
//
//           /// Numbering at the bottom center
//           Positioned(
//             bottom: 56,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
//                 child: Text("${_currentIndex + 1} / ${widget.images.length}", style: const TextStyle(color: Colors.white, fontSize: 14)),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
