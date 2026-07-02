import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_file_service_factory_stub.dart'
    if (dart.library.io) 'package:moviepilot_mobile/utils/image_file_service_factory_io.dart'
    if (dart.library.js_interop) 'package:moviepilot_mobile/utils/image_file_service_factory_web.dart';

/// 全局图片缓存管理器（缓存 7 天）
class AppImageCacheManager {
  AppImageCacheManager._();

  static const int decodedImageMaximumSize = 80;
  static const int decodedImageMaximumSizeBytes = 48 * 1024 * 1024;

  static final CacheManager instance = CacheManager(
    Config(
      'appImageCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 300,
      fileService: createAppImageFileService(),
    ),
  );

  static void configureGlobalDecodedCache() {
    final cache = PaintingBinding.instance.imageCache;
    if (cache.maximumSize > decodedImageMaximumSize) {
      cache.maximumSize = decodedImageMaximumSize;
    }
    if (cache.maximumSizeBytes > decodedImageMaximumSizeBytes) {
      cache.maximumSizeBytes = decodedImageMaximumSizeBytes;
    }
  }
}
