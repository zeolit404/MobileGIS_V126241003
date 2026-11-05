import 'package:flutter/widgets.dart';

// Conditional export: gunakan stub pada web, dan gunakan io pada native
import 'platform_image_helper_stub.dart'
    if (dart.library.io) 'platform_image_helper_io.dart' as helper;

class PlatformImageHelper {
  /// Membangun widget gambar yang aman di Web dan Mobile (tidak pernah crash _Namespace)
  static Widget buildImage(
    String? pathOrUri, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    return helper.buildPlatformSafeImage(
      pathOrUri,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
