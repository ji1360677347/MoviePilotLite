import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_request_headers.dart';

/// 网络图片加载组件
/// 基于 cached_network_image 和 flutter_cache_manager
/// 使用 iOS 风格的 loading 显示进度
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheManager,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.cookie,
  });

  /// 图片 URL
  final String imageUrl;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 图片适配方式
  final BoxFit fit;

  /// 占位符（加载中显示）
  final Widget? placeholder;

  /// 错误占位符（加载失败显示）
  final Widget? errorWidget;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 自定义缓存管理器
  final CacheManager? cacheManager;

  /// 内存缓存宽度（用于优化内存）
  final int? memCacheWidth;

  /// 内存缓存高度（用于优化内存）
  final int? memCacheHeight;

  /// 淡入动画时长
  final Duration fadeInDuration;

  /// 淡出动画时长
  final Duration fadeOutDuration;

  /// Cookie
  final String? cookie;

  static const double _decodeOverscan = 1.35;
  static const int _minAutoCacheExtent = 64;
  static const int _maxAutoCacheExtent = 1600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildImage(context, constraints),
    );
  }

  Widget _buildImage(BuildContext context, BoxConstraints constraints) {
    final manager = cacheManager ?? AppImageCacheManager.instance;
    final autoCacheExtents = _autoCacheExtents(context, constraints);
    final effectiveMemCacheWidth = memCacheWidth ?? autoCacheExtents.width;
    final effectiveMemCacheHeight = memCacheHeight ?? autoCacheExtents.height;
    if (kIsWeb) {
      final imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheManager: manager,
        memCacheWidth: effectiveMemCacheWidth,
        memCacheHeight: effectiveMemCacheHeight,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        errorListener: (_) {},
        errorWidget: (context, url, error) {
          return errorWidget ?? _buildDefaultErrorWidget(error);
        },
        progressIndicatorBuilder: (context, url, progress) =>
            placeholder ?? _buildProgressIndicator(progress),
      );
      return _clipIfNeeded(imageWidget);
    }

    final headers = buildImageRequestHeaders(imageUrl, cookie: cookie);

    final cacheKey = _buildCacheKey(imageUrl);

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      width: width,
      height: height,
      fit: fit,
      cacheManager: manager,
      memCacheWidth: effectiveMemCacheWidth,
      memCacheHeight: effectiveMemCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      errorListener: (_) => _evictBrokenImage(manager, cacheKey),
      errorWidget: (context, url, error) {
        return errorWidget ?? _buildDefaultErrorWidget(error);
      },
      progressIndicatorBuilder: (context, url, progress) =>
          placeholder ?? _buildProgressIndicator(progress),
      httpHeaders: headers.isNotEmpty ? headers : null,
    );

    return _clipIfNeeded(imageWidget);
  }

  ({int? width, int? height}) _autoCacheExtents(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final logicalWidth =
        _finiteExtent(width) ?? _finiteExtent(constraints.maxWidth);
    final logicalHeight =
        _finiteExtent(height) ?? _finiteExtent(constraints.maxHeight);
    final cacheWidth = _scaledCacheExtent(context, logicalWidth);
    final cacheHeight = _scaledCacheExtent(context, logicalHeight);

    if (cacheWidth == null) return (width: null, height: cacheHeight);
    if (cacheHeight == null) return (width: cacheWidth, height: null);
    if (fit == BoxFit.cover && cacheHeight > cacheWidth) {
      return (width: null, height: cacheHeight);
    }
    return (width: cacheWidth, height: null);
  }

  int? _scaledCacheExtent(BuildContext context, double? logicalExtent) {
    if (logicalExtent == null || logicalExtent <= 0) return null;
    final raw =
        logicalExtent *
        MediaQuery.devicePixelRatioOf(context) *
        _decodeOverscan;
    return raw.ceil().clamp(_minAutoCacheExtent, _maxAutoCacheExtent);
  }

  double? _finiteExtent(double? value) {
    if (value == null || !value.isFinite) return null;
    return value;
  }

  Widget _clipIfNeeded(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  void _evictBrokenImage(CacheManager manager, String cacheKey) {
    if (cacheKey.isEmpty) return;
    unawaited(manager.removeFile(cacheKey).catchError((_) {}));
  }

  /// 构建进度指示器（iOS 风格）
  Widget _buildProgressIndicator(dynamic progress) {
    double? progressValue;
    if (progress is DownloadProgress) {
      progressValue = progress.progress;
    } else if (progress is double) {
      progressValue = progress;
    }
    return _ImageStateSurface(
      width: width,
      height: height,
      progress: progressValue,
    );
  }

  /// 构建默认错误占位符（iOS 风格）
  Widget _buildDefaultErrorWidget(Object error) {
    return _ImageStateSurface(width: width, height: height, isError: true);
  }

  String _buildCacheKey(String url) {
    if (url.isEmpty) return url;
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }
    final qp = uri.queryParameters;
    final inner = qp['url'] ?? qp['imgurl'];
    if (inner != null && inner.isNotEmpty) {
      return inner;
    }
    return url;
  }
}

class _ImageStateSurface extends StatefulWidget {
  const _ImageStateSurface({
    this.width,
    this.height,
    this.progress,
    this.isError = false,
  });

  final double? width;
  final double? height;
  final double? progress;
  final bool isError;

  @override
  State<_ImageStateSurface> createState() => _ImageStateSurfaceState();
}

class _ImageStateSurfaceState extends State<_ImageStateSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheenController;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _ImageStateSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.isError || reduceMotion) {
      _sheenController.stop();
      return;
    }
    if (!_sheenController.isAnimating) {
      _sheenController.repeat();
    }
  }

  @override
  void dispose() {
    _sheenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C22) : const Color(0xFFF2F2F7);
    final surfaceHigh = isDark
        ? Colors.white.withValues(alpha: 0.070)
        : Colors.white.withValues(alpha: 0.72);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.075)
        : Colors.black.withValues(alpha: 0.050);
    final iconColor = widget.isError
        ? CupertinoColors.systemGrey.resolveFrom(context)
        : theme.colorScheme.primary.withValues(alpha: isDark ? 0.58 : 0.46);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [surfaceHigh, surface, surface.withValues(alpha: 0.92)],
          ),
          border: Border.all(color: border, width: 0.7),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxSide = _maxFiniteSide(constraints);
            final compact = maxSide < 88;
            final iconSize = compact ? 20.0 : 30.0;
            final showText = !compact && constraints.maxHeight >= 92;
            final showProgress =
                !widget.isError && widget.progress != null && showText;

            return AnimatedBuilder(
              animation: _sheenController,
              builder: (context, child) {
                return CustomPaint(
                  foregroundPainter: widget.isError
                      ? null
                      : _LoadingSheenPainter(
                          progress: _sheenController.value,
                          isDark: isDark,
                        ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 36 : 48,
                      height: compact ? 36 : 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.060 : 0.72,
                        ),
                        border: Border.all(color: border, width: 0.7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.018 : 0.34,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          widget.isError
                              ? CupertinoIcons.photo
                              : CupertinoIcons.photo_on_rectangle,
                          size: iconSize,
                          color: iconColor,
                        ),
                      ),
                    ),
                    if (showText) ...[
                      const SizedBox(height: 9),
                      Text(
                        widget.isError ? '图片加载失败' : '加载图片中',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: isDark ? 0.72 : 0.66,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (showProgress) ...[
                      const SizedBox(height: 8),
                      _ProgressPill(progress: widget.progress!.clamp(0.0, 1.0)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _maxFiniteSide(BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : 120.0;
    return width < height ? width : height;
  }
}

class _LoadingSheenPainter extends CustomPainter {
  const _LoadingSheenPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final bandWidth = size.width * 0.34;
    final left = -bandWidth + (size.width + bandWidth * 2) * progress;
    final rect = Rect.fromLTWH(left, 0, bandWidth, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.060 : 0.34),
          Colors.white.withValues(alpha: isDark ? 0.12 : 0.58),
          Colors.white.withValues(alpha: isDark ? 0.060 : 0.34),
          Colors.transparent,
        ],
        stops: const [0, 0.28, 0.50, 0.72, 1],
      ).createShader(rect)
      ..blendMode = isDark ? BlendMode.plus : BlendMode.softLight;

    canvas.save();
    canvas.translate(left + bandWidth / 2, size.height / 2);
    canvas.rotate(-0.28);
    canvas.translate(-left - bandWidth / 2, -size.height / 2);
    canvas.drawRect(rect.inflate(size.height * 0.28), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadingSheenPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${(progress * 100).round()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

/// 圆形头像图片组件
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
    this.cacheManager,
    this.cookie,
  });

  /// 图片 URL
  final String imageUrl;

  /// 半径
  final double radius;

  /// 占位符
  final Widget? placeholder;

  /// 错误占位符
  final Widget? errorWidget;

  /// 自定义缓存管理器
  final CacheManager? cacheManager;

  /// Cookie
  final String? cookie;

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(radius),
      placeholder: placeholder ?? _buildDefaultPlaceholder(context),
      errorWidget: errorWidget ?? _buildDefaultErrorPlaceholder(context),
      cacheManager: cacheManager,
      cookie: cookie,
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return _buildAvatarState(context, isError: false);
  }

  Widget _buildDefaultErrorPlaceholder(BuildContext context) {
    return _buildAvatarState(context, isError: true);
  }

  Widget _buildAvatarState(BuildContext context, {required bool isError}) {
    return _AvatarStateSurface(radius: radius, isError: isError);
  }
}

class _AvatarStateSurface extends StatefulWidget {
  const _AvatarStateSurface({required this.radius, required this.isError});

  final double radius;
  final bool isError;

  @override
  State<_AvatarStateSurface> createState() => _AvatarStateSurfaceState();
}

class _AvatarStateSurfaceState extends State<_AvatarStateSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheenController;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AvatarStateSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.isError || reduceMotion) {
      _sheenController.stop();
      return;
    }
    if (!_sheenController.isAnimating) {
      _sheenController.repeat();
    }
  }

  @override
  void dispose() {
    _sheenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = widget.isError
        ? CupertinoColors.systemGrey.resolveFrom(context)
        : theme.colorScheme.primary.withValues(alpha: isDark ? 0.58 : 0.46);

    return ClipOval(
      child: AnimatedBuilder(
        animation: _sheenController,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: widget.isError
                ? null
                : _LoadingSheenPainter(
                    progress: _sheenController.value,
                    isDark: isDark,
                  ),
            child: child,
          );
        },
        child: Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C22) : const Color(0xFFF2F2F7),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.075),
                      const Color(0xFF1C1C22),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.78),
                      const Color(0xFFF2F2F7),
                    ],
            ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: isDark ? 0.08 : 0.05,
              ),
              width: 0.7,
            ),
          ),
          child: Center(
            child: Icon(
              widget.isError
                  ? CupertinoIcons.person_crop_circle
                  : CupertinoIcons.person_fill,
              color: foreground,
              size: (widget.radius * 0.64).clamp(18.0, 30.0),
            ),
          ),
        ),
      ),
    );
  }
}
