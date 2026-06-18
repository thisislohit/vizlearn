// import 'package:flutter/material.dart';
// import 'package:vizlearn/utils/app_export.dart';
// import 'package:file_picker/file_picker.dart';
//
// import '../../gen/assets.gen.dart';
//
//
// class DocUploadContainer extends StatefulWidget {
//   final Function(List<PlatformFile>)? onFilesSelected;
//   final List<PlatformFile> existingFiles;
//   final int? fileCount;
//   final bool allowMultiple;
//
//   const DocUploadContainer({
//     super.key,
//     this.onFilesSelected,
//     this.existingFiles = const [],
//     this.fileCount,
//     this.allowMultiple = true,
//   });
//
//   @override
//   DocUploadContainerState createState() => DocUploadContainerState();
// }
//
// class DocUploadContainerState extends State<DocUploadContainer> {
//   late List<PlatformFile> selectedFiles;
//   late int? fileCount;
//
//   @override
//   void initState() {
//     super.initState();
//     selectedFiles = widget.existingFiles;
//     fileCount = widget.fileCount;
//   }
//
//   Future<void> _pickFiles() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       allowMultiple: widget.allowMultiple ? true : false,
//       type: FileType.any,
//     );
//
//     if (result != null) {
//       List<PlatformFile> selected = result.files;
//
//       if (fileCount != null && selected.length > fileCount!) {
//         selected = selected.take(fileCount!).toList();
//         AppUtils.showSnackbar(context, 'Only ${widget.fileCount} file(s) is allowed for this category');
//       }
//
//       setState(() {
//         if(fileCount!= null &&  !widget.allowMultiple){
//           fileCount = fileCount! - selected.length;
//         }
//         if(widget.allowMultiple){
//           selectedFiles.addAll(selected);
//         }else{
//           selectedFiles = selected;
//         }
//       });
//       widget.onFilesSelected?.call(selectedFiles);
//     }
//   }
//
//   void _removeFile(int index) {
//     setState(() {
//       if(fileCount!= null && !widget.allowMultiple){
//         fileCount = fileCount! + 1;
//       }
//       selectedFiles.removeAt(index);
//     });
//     widget.onFilesSelected?.call(selectedFiles);
//   }
//
//   void _showFileListDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadiusStyle.radius8,
//           ),
//           title: const Text('Selected Files'),
//           content: StatefulBuilder(
//             builder: (context, setState) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Scrollbar(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: selectedFiles.asMap().entries.map((entry) {
//                           int index = entry.key;
//                           PlatformFile file = entry.value;
//                           return ListTile(
//                             contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
//                             leading: fileThumbNail(
//                               onTap: () {
//                                 setState((){});
//                                 _removeFile(index);
//                               },
//                             ),
//                             title: Text(file.name),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(
//                     height: AppSizes.spaceBtwItems,
//                   ),
//                   CustomOutlinedButton(
//                     text: 'Add Another File(s)',
//                     leftIcon: Container(
//                         decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(4)),
//                         child: CustomImageView(
//                           imagePath: Assets.icons.add,
//                           color: AppColors.primary,
//                         )),
//                     height: 40,
//                     onPressed: () async{
//                       await _pickFiles();
//                       setState((){});
//                     },
//                   ),
//                   const SizedBox(
//                     height: AppSizes.spaceBtwItems,
//                   ),
//                   CustomElevatedButton(
//                     text: 'Close',
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ],
//               );
//             }
//           ),
//         );
//       },
//     );
//   }
//
//   Widget fileThumbNail({required VoidCallback onTap}) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           height: 50,
//           width: 50,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadiusStyle.radius8,
//             border: Border.all(color: AppColors.primary2),
//           ),
//           child: Center(
//             child: CustomImageView(
//               imagePath: Assets.icons.add,
//             ),
//           ),
//         ),
//         Positioned(
//           top: -5,
//           right: -5,
//           child: InkWell(
//             onTap: onTap,
//             child: Container(
//               height: 20,
//               width: 20,
//               decoration: const BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.close,
//                 color: Colors.white,
//                 size: 16,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       painter: DashedBorderPainter(
//         color: AppColors.primary2,
//         strokeWidth: 1,
//         gap: 10,
//         borderRadius: BorderRadiusStyle.radius8,
//       ),
//       child: InkWell(
//         onTap: _pickFiles,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 56),
//           height: 180,
//           decoration: BoxDecoration(
//             color: AppColors.background2,
//             borderRadius: BorderRadiusStyle.radius8,
//           ),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (selectedFiles.isEmpty)
//                   CustomImageView(imagePath: Assets.icons.add)
//                 else
//                   Wrap(
//                     alignment: WrapAlignment.center,
//                     spacing: 10,
//                     children: [
//                       fileThumbNail(onTap: () => _removeFile(0)),
//                       if (selectedFiles.isNotEmpty)
//                         InkWell(
//                           onTap: selectedFiles.length == 1 ? _pickFiles : _showFileListDialog,
//                           child: Container(
//                             height: 50,
//                             width: 50,
//                             decoration: BoxDecoration(
//                               color: AppColors.primary.withOpacity(0.6),
//                               shape: BoxShape.circle,
//                             ),
//                             child: selectedFiles.length == 1
//                                 ? Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: CustomImageView(
//                                       imagePath: Assets.icons.add,
//                                       color: Colors.white,
//                                     ),
//                                 )
//                                 : Center(
//                                     child: Text(
//                                       '+${selectedFiles.length - 1}',
//                                       style: CustomTextStyles.b2.copyWith(
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 const SizedBox(height: AppSizes.spaceSmall),
//                 Flexible(
//                   child: Wrap(
//                     alignment: WrapAlignment.start,
//                     children: [
//                       Text(
//                         selectedFiles.isNotEmpty ? selectedFiles.first.name : 'lbl_tap_upload_doc',
//                         style: CustomTextStyles.b4,
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
