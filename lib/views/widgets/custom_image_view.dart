// ignore_for_file: must_be_immutable

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:load_it/load_it.dart';

class CustomImageView extends StatelessWidget {
  /// [imagePath] is required parameter for showing image
  String? imagePath;

  double? height;
  double? width;
  Color? color;
  BoxFit? fit;
  final String placeHolder;
  Alignment? alignment;
  VoidCallback? onTap;
  EdgeInsetsGeometry? margin;
  BorderRadius? radius;
  BoxBorder? border;
  double? rotationAngle; // New property for rotation angle
  bool circularSplash; // New property for circular splash effect

  /// A [CustomImageView] can be used for showing any type of images.
  /// It will show the placeholder image if image is not found on network image.
  CustomImageView({
    super.key,
    this.imagePath,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.rotationAngle, // Initialize rotationAngle in constructor
    this.circularSplash = false, // Default to false for backward compatibility
    this.placeHolder = 'assets/images/icon_img_not_found.png',
  });

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(alignment: alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    if (onTap == null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: _buildCircleImage(),
      );
    }
    
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: circularSplash && width != null && height != null
              ? BorderRadius.circular((width! < height! ? width! : height!) / 2)
              : null,
          child: _buildCircleImage(),
        ),
      ),
    );
  }

  /// Build the image with border radius
  _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  /// Build the image with border and border radius style
  _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(border: border, borderRadius: radius),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    Widget imageWidget;
    if (imagePath != null) {
      switch (imagePath!.imageType) {
        case ImageType.svg:
          imageWidget = SvgPicture.asset(
            imagePath!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.contain,
            colorFilter: color != null
                ? ColorFilter.mode(color ?? Colors.transparent, BlendMode.srcIn)
                : null,
            errorBuilder: (context, url, error) => const Icon(Icons.error),
          );
          break;
        case ImageType.file:
          imageWidget = Image.file(
            File(imagePath!),
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            errorBuilder: (context, url, error) => const Icon(Icons.error),
          );
          break;
        case ImageType.network:
          imageWidget = CachedNetworkImage(
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            imageUrl: imagePath!,
            color: color,
            placeholder: (context, url) => SizedBox(
              height: height,
              width: width,
              child: PulsingCircleIndicator(color: Colors.white.withOpacity(0.5),),
            ),
            errorWidget: (context, url, error) => Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: radius ?? BorderRadius.zero,
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey.shade300,
                size: (width != null && height != null)
                    ? (width! < height! ? width! * 0.3 : height! * 0.3)
                    : 24,
              ),
            ),
          );
          break;
        case ImageType.png:
        default:
          imageWidget = Image.asset(
            imagePath!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            errorBuilder: (context, url, error) => const Icon(Icons.error),
          );
          break;
      }

      // Apply rotation if rotationAngle is provided
      if (rotationAngle != null) {
        imageWidget = Transform.rotate(
          angle: rotationAngle!,
          child: imageWidget,
        );
      }

      return imageWidget;
    }

    return const SizedBox();
  }
}

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http') || startsWith('https')) {
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('/')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, unknown }
