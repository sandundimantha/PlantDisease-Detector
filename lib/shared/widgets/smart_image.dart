import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';

/// A smart image widget that automatically detects whether the [src] is an
/// asset path, network URL, or local file path, and renders accordingly.
/// Gracefully falls back to a clean, styled placeholder if loading fails.
class SmartImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SmartImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.borderRadius,
  });

  bool get _isUrl =>
      src.startsWith('http://') || src.startsWith('https://');

  bool get _isAsset =>
      src.startsWith('assets/') || src.startsWith('packages/');

  Widget _defaultError() {
    return Image.asset(
      'assets/images/hero_leaf.jpg',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.imagePlaceholder,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Icon(
            Icons.grass_rounded,
            color: AppColors.imageIcon,
            size: (width != null && width! < 60) ? 20 : 32,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (src.isEmpty) {
      image = errorWidget ?? _defaultError();
    } else if (_isAsset) {
      image = Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _defaultError(),
      );
    } else if (_isUrl) {
      image = Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.imageLoadingBg,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.imageLoadingSpinner,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _defaultError(),
      );
    } else {
      final file = File(src);
      image = Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _defaultError(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

