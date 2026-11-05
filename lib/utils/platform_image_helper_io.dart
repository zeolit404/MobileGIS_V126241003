import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

Widget buildPlatformSafeImage(
  String? pathOrUri, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (pathOrUri == null || pathOrUri.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26),
    );
  }

  // 1. Jika data berupa Base64
  if (pathOrUri.startsWith('data:image')) {
    try {
      final commaIndex = pathOrUri.indexOf(',');
      final base64Str = commaIndex != -1 ? pathOrUri.substring(commaIndex + 1) : pathOrUri;
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (ctx, err, stack) => _buildError(width, height),
      );
    } catch (_) {}
  }

  // 2. Jika data berupa URL web
  if (pathOrUri.startsWith('http://') || pathOrUri.startsWith('https://')) {
    return Image.network(
      pathOrUri,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder ?? (ctx, err, stack) => _buildError(width, height),
    );
  }

  // 3. File lokal native (Android/iOS)
  try {
    final file = File(pathOrUri);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (ctx, err, stack) => _buildError(width, height),
      );
    }
  } catch (_) {}

  return _buildError(width, height);
}

Widget _buildError(double? width, double? height) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
  );
}
