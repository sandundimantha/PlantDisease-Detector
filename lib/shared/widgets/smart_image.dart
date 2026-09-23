import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A smart image widget that automatically detects whether the [src] is a
/// network URL or a local file path, and renders accordingly.
/// Falls back to a styled placeholder if loading fails.
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
      src.startsWith('http://') || src.startsWith('https://') || src.startsWith('blob:');

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0EDE8),
      child: Center(
        child: Icon(
          Icons.eco_rounded,
          color: const Color(0xFF81B29A),
          size: (width != null && width! < 60) ? 20 : 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (src.isEmpty) {
      image = errorWidget ?? _defaultError();
    } else if (_isUrl || kIsWeb) {
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
            color: const Color(0xFFF0EDE8),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE07A5F),
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
