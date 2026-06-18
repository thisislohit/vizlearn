// import 'package:country_pickers/country_pickers.dart';
// import 'package:country_pickers/country.dart';
// import 'package:flutter/material.dart';
// import 'package:vizlearn/utils/app_export.dart';
//
// import '../../gen/assets.gen.dart';
// import 'custom_image_view.dart';
// import 'custom_text_form_field.dart';
//
// // ignore: must_be_immutable
// class CustomPhoneNumber extends StatelessWidget {
//   CustomPhoneNumber(
//       {super.key,
//       required this.country,
//       required this.onTap,
//       required this.controller,
//       this.handleTextFieldFocus,
//       this.validator,
//       this.isDisabled = false,
//       this.hintText,
//       this.validationError,
//       this.suffix,
//       this.width,
//       required this.isFocussed});
//
//   Country country;
//
//   Function(Country) onTap;
//
//   TextEditingController phoneController = TextEditingController();
//   TextEditingController? controller;
//   Function(bool)? handleTextFieldFocus;
//   String? Function(String?)? validator;
//   bool isDisabled;
//   String? hintText;
//   String? validationError;
//   Widget? suffix;
//   bool isFocussed;
//   double? width;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           height: 56,
//           width: width,
//           padding: const EdgeInsets.only(left: 8),
//           decoration: BoxDecoration(
//               color: isFocussed ? Colors.white : Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isDisabled
//                     ? Colors.transparent
//                     : (validationError != null && validationError != '')
//                         ? AppColors.red
//                         : isFocussed
//                             ? AppColors.primary
//                             : Colors.transparent,
//                 width: 1,
//               ),
//               boxShadow: const [
//                 BoxShadow(
//                     blurRadius: 2, color: AppColors.grey),
//                 BoxShadow(
//                     blurRadius: 4, color: AppColors.grey),
//               ]),
//           child: Row(
//             children: [
//               InkWell(
//                 onTap: isDisabled
//                     ? null
//                     : () {
//                         _openCountryPicker(context);
//                       },
//                 child: Container(
//                   decoration: const BoxDecoration(
//                       // border: Border(
//                       //   right: BorderSide(
//                       //     color: isDisabled ? AppColors.darkerGrey : AppColors.black,
//                       //     width: 1,
//                       //   ),
//                       // ),
//                       ),
//                   child: Row(
//                     children: [
//                       isDisabled
//                           ? ColorFiltered(
//                               colorFilter: ColorFilter.mode(
//                                 Colors.grey.withOpacity(0.5),
//                                 // Adjust opacity and color as needed
//                                 BlendMode.lighten,
//                               ),
//                               child: CountryPickerUtils.getDefaultFlagImage(
//                                   country),
//                             )
//                           : SizedBox(
//                               width: 25,
//                               height: 15,
//                               child: CountryPickerUtils.getDefaultFlagImage(
//                                   country)),
//                       CustomImageView(
//                           imagePath: Assets.icons.arrowDown,
//                           height: 6,
//                           width: 8,
//                           margin: const EdgeInsets.fromLTRB(9, 6, 8, 6),
//                           color: isDisabled
//                               ? AppColors.primary
//                               : AppColors.primary),
//                       Text(
//                         "+${country.phoneCode}",
//                         style: CustomTextStyles.b4Primary2.copyWith(
//                             color: isDisabled
//                                 ? AppColors.darkerGrey
//                                 : AppColors.darkGrey),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: CustomTextFormField(
//                   allowShadow: false,
//                   contentPadding: const EdgeInsets.only(
//                       left: AppSizes.xs,
//                       top: AppSizes.sm2,
//                       bottom: AppSizes.sm2),
//                   borderColor: Colors.transparent,
//                   filled: false,
//                   borderDecoration: InputBorder.none,
//                   // width: 198,
//                   controller: controller,
//                   hintText: hintText ?? "9000000000",
//
//                   textInputType: TextInputType.phone,
//                   onFocusChange: handleTextFieldFocus,
//                   enabled: !isDisabled,
//                   disabledBorderColor: Colors.transparent,
//                   suffix: suffix,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (validationError != null && validationError != '')
//           Padding(
//             padding: const EdgeInsets.only(top: 4.0, left: 16.0),
//             child: Text(
//               validationError!,
//               style: CustomTextStyles.b5.copyWith(color: Colors.red),
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildDialogItem(Country country) => Row(
//         children: <Widget>[
//           CountryPickerUtils.getDefaultFlagImage(country),
//           Container(
//             margin: const EdgeInsets.only(
//               left: 10,
//             ),
//             width: 60,
//             child: Text(
//               "+${country.phoneCode}",
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//           const SizedBox(width: AppSizes.spaceSmall),
//           Flexible(
//             child: Text(
//               country.name,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       );
//
//   void _openCountryPicker(BuildContext context) => showDialog(
//         context: context,
//         builder: (context) => CountryPickerDialog(
//           searchInputDecoration: const InputDecoration(
//             hintText: 'Search...',
//             hintStyle: TextStyle(fontSize: 14),
//           ),
//           isSearchable: true,
//           title: const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Text('Select your phone code',
//                 style: TextStyle(fontSize: 14)),
//           ),
//           onValuePicked: (Country country) => onTap(country),
//           itemBuilder: _buildDialogItem,
//         ),
//       );
// }
