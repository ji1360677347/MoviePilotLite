import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_category_list_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_base_card.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/utils/grid_layout.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/app_glass_card.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RecommendCategoryListPage
    extends GetView<RecommendCategoryListController> {
  const RecommendCategoryListPage({super.key});

  static const double _gridSpacing = 8;
  static const double _gridPadding = 16;
  static const double _cardAspectRatio = 1 / 1.3;
  static const double _listPosterWidth = 78;
  static const double _listPosterHeight = 110;
  static const double _narrowScreenBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final themeColor = controller.appBarThemeColor;
    if (themeColor == null) {
      return Obx(
        () => Scaffold(
          appBar: _buildPlainAppBar(context),
          body: _buildBody(context, immersive: false),
        ),
      );
    }

    final bodyColor = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: bodyColor,
      body: _buildBody(context, immersive: true, bodyColor: bodyColor),
    );
  }

  AppBar _buildPlainAppBar(BuildContext context) {
    final isNarrowScreen =
        MediaQuery.sizeOf(context).width < _narrowScreenBreakpoint;
    controller.preferredViewMode.value;
    final viewMode = controller.resolvedViewMode(
      isNarrowScreen: isNarrowScreen,
    );
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: Get.back,
      ),
      title: Text(controller.categoryTitle),
      centerTitle: false,
      actions: [
        IconButton(
          tooltip: viewMode == SearchResultViewMode.list ? '切换为网格' : '切换为列表',
          onPressed: () =>
              controller.toggleViewMode(isNarrowScreen: isNarrowScreen),
          icon: Icon(
            viewMode == SearchResultViewMode.list
                ? CupertinoIcons.square_grid_2x2
                : CupertinoIcons.list_bullet,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool immersive,
    Color? bodyColor,
  }) {
    return Obx(() {
      final items = controller.items.toList();
      final isInitialLoading = items.isEmpty && controller.isLoading.value;
      final isNarrowScreen =
          MediaQuery.sizeOf(context).width < _narrowScreenBreakpoint;
      controller.preferredViewMode.value;
      final viewMode = controller.resolvedViewMode(
        isNarrowScreen: isNarrowScreen,
      );
      final layout = gridLayout(
        context,
        gridSpacing: _gridSpacing,
        gridPadding: _gridPadding,
      );

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: CustomScrollView(
          cacheExtent: 160,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (immersive)
              _buildImmersiveHeader(
                context,
                items,
                bodyColor: bodyColor,
                viewMode: viewMode,
                isNarrowScreen: isNarrowScreen,
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),

            immersive
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        controller.categoryTitle,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(child: SizedBox.shrink()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _gridPadding,
                immersive ? 0 : 8,
                _gridPadding,
                _gridPadding,
              ),
              sliver: Skeletonizer.sliver(
                enabled: isInitialLoading,
                child: viewMode == SearchResultViewMode.list
                    ? _buildListSliver(context, items)
                    : _buildGridSliver(items, layout.crossAxisCount),
              ),
            ),
            SliverToBoxAdapter(child: _buildBottomStatusHost(context)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      );
    });
  }

  Widget _buildGridSliver(List<RecommendApiItem> items, int crossAxisCount) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _buildGridItem(context, item);
        },
        childCount: items.length,
        addAutomaticKeepAlives: false,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: _gridSpacing,
        crossAxisSpacing: _gridSpacing,
        childAspectRatio: _cardAspectRatio,
      ),
    );
  }

  Widget _buildListSliver(BuildContext context, List<RecommendApiItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildListItem(context, item),
          );
        },
        childCount: items.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, RecommendApiItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _bestTitle(item) ?? '';
    final year = _displayYear(item);
    final overview = item.overview?.trim();
    final type = item.type?.trim();
    final vote = item.vote_average;
    final accent = _pageAccent(context, fallbackItem: item);
    final metaChips = <Widget>[
      if (type != null && type.isNotEmpty)
        _buildMetaPill(context, type, accent: accent),
      if (year.isNotEmpty)
        _buildMetaPill(
          context,
          year,
          accent: colorScheme.secondary,
          quiet: true,
        ),
      if (vote != null && vote > 0)
        _buildMetaPill(
          context,
          vote.toStringAsFixed(1),
          accent: const Color(0xFFFFC857),
        ),
    ];

    return RecommendItemBaseCard(
      item: item,
      child: AppGlassCard(
        onTap: () => _openDetail(item),
        padding: EdgeInsets.zero,
        borderRadius: 20,
        blurSigma: 14,
        surfaceAlpha: isDark ? 0.30 : 0.70,
        borderAlpha: isDark ? 0.18 : 0.54,
        shadowAlpha: isDark ? 0.18 : 0.08,
        accentColor: accent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RecommendCategoryItemGlowPainter(
                    accent: accent,
                    isDark: isDark,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPosterFrame(
                      context,
                      item,
                      width: _listPosterWidth,
                      height: _listPosterHeight,
                      radius: 15,
                      showScore: false,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                            if (metaChips.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 7,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: metaChips,
                              ),
                            ],
                            if (overview != null && overview.isNotEmpty) ...[
                              const SizedBox(height: 9),
                              Text(
                                overview,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: isDark ? 0.78 : 0.86),
                                  fontSize: 12,
                                  height: 1.38,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, RecommendApiItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final title = _bestTitle(item) ?? '';
    final year = _displayYear(item);
    final type = item.type?.trim();
    final vote = item.vote_average;
    final accent = _pageAccent(context, fallbackItem: item);

    return RecommendItemBaseCard(
      item: item,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 160.0;
          final height = width / _cardAspectRatio;
          return SizedBox(
            width: width,
            height: height,
            child: AppGlassCard(
              onTap: () => _openDetail(item),
              padding: EdgeInsets.zero,
              borderRadius: 20,
              blurSigma: 14,
              surfaceAlpha: isDark ? 0.24 : 0.68,
              borderAlpha: isDark ? 0.16 : 0.48,
              shadowAlpha: isDark ? 0.20 : 0.10,
              accentColor: accent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPosterImage(
                      context,
                      item,
                      fit: BoxFit.cover,
                      memCacheWidth: _scaledCacheExtent(context, width),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.black.withValues(alpha: 0.12),
                            Colors.black.withValues(alpha: 0.76),
                          ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RecommendCategoryItemGlowPainter(
                          accent: accent,
                          isDark: true,
                          strongBottom: true,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      top: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (type != null && type.isNotEmpty)
                            Flexible(
                              child: _buildOverlayPill(
                                type,
                                background: Colors.black.withValues(
                                  alpha: 0.36,
                                ),
                              ),
                            ),
                          const Spacer(),
                          if (vote != null && vote > 0)
                            _buildOverlayPill(
                              vote.toStringAsFixed(1),
                              background: const Color(
                                0xFFFFC857,
                              ).withValues(alpha: 0.92),
                              foreground: Colors.black87,
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.14,
                            ),
                          ),
                          if (year.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              year,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: isDark ? 0.12 : 0.22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosterFrame(
    BuildContext context,
    RecommendApiItem item, {
    required double width,
    required double height,
    required double radius,
    bool showScore = true,
  }) {
    final vote = item.vote_average;
    final borderRadius = BorderRadius.circular(radius);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPosterImage(
              context,
              item,
              fit: BoxFit.cover,
              memCacheWidth: _scaledCacheExtent(context, width),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
            if (showScore && vote != null && vote > 0)
              Positioned(
                left: 7,
                bottom: 7,
                child: _buildOverlayPill(
                  vote.toStringAsFixed(1),
                  background: Colors.black.withValues(alpha: 0.48),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterImage(
    BuildContext context,
    RecommendApiItem item, {
    required BoxFit fit,
    int? memCacheWidth,
  }) {
    final raw = item.poster_path ?? item.backdrop_path;
    if (raw != null && raw.isNotEmpty) {
      return CachedImage(
        imageUrl: ImageUtil.convertCacheImageUrl(raw),
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        memCacheWidth: memCacheWidth,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.primaryContainer.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.54),
          size: 30,
        ),
      ),
    );
  }

  int _scaledCacheExtent(BuildContext context, double logicalExtent) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final value = (logicalExtent * devicePixelRatio * 1.25).ceil();
    return value.clamp(96, 900);
  }

  Widget _buildMetaPill(
    BuildContext context,
    String text, {
    required Color accent,
    bool quiet = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: quiet
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.52)
            : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: quiet
              ? colorScheme.outlineVariant.withValues(alpha: 0.28)
              : accent.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: quiet ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOverlayPill(
    String text, {
    required Color background,
    Color foreground = Colors.white,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _accentForItem(BuildContext context, RecommendApiItem item) {
    final source = (item.source ?? item.type ?? item.category ?? '')
        .toLowerCase()
        .trim();
    if (source.contains('douban')) return const Color(0xFF42A75C);
    if (source.contains('imdb')) return const Color(0xFFF5C518);
    if (source.contains('bangumi')) return const Color(0xFFF09199);
    if (source.contains('tmdb') || source.contains('themoviedb')) {
      return const Color(0xFF01B4E4);
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _pageAccent(BuildContext context, {RecommendApiItem? fallbackItem}) {
    return controller.appBarThemeColor ??
        (fallbackItem == null
            ? Theme.of(context).colorScheme.primary
            : _accentForItem(context, fallbackItem));
  }

  Color _pageSecondaryAccent(BuildContext context) {
    return controller.appBarSecondaryThemeColor ?? _pageAccent(context);
  }

  String _displayYear(RecommendApiItem item) {
    final year = item.year?.trim() ?? '';
    if (year.isNotEmpty) return year;
    return item.title_year?.trim() ?? '';
  }

  SliverAppBar _buildImmersiveHeader(
    BuildContext context,
    List<RecommendApiItem> items, {
    Color? bodyColor,
    required SearchResultViewMode viewMode,
    required bool isNarrowScreen,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _pageAccent(context);
    final secondaryAccent = _pageSecondaryAccent(context);
    final surface = bodyColor ?? colorScheme.surface;
    final headerTop = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.34 : 0.22),
      colorScheme.surfaceContainerHighest,
    );
    final headerMid = Color.alphaBlend(
      secondaryAccent.withValues(alpha: isDark ? 0.20 : 0.12),
      surface,
    );
    final headerForeground = _readableOnColor(headerTop);
    final topItems = items.take(3).toList();
    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: headerTop,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: headerForeground),
        onPressed: Get.back,
      ),
      actions: [
        IconButton(
          tooltip: viewMode == SearchResultViewMode.list ? '切换为网格' : '切换为列表',
          onPressed: () =>
              controller.toggleViewMode(isNarrowScreen: isNarrowScreen),
          icon: Icon(
            viewMode == SearchResultViewMode.list
                ? CupertinoIcons.square_grid_2x2
                : CupertinoIcons.list_bullet,
            color: headerForeground,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [headerTop, headerMid, surface],
              stops: const [0, 0.34, 1.0],
            ),
          ),
          child: Center(
            child: SizedBox(
              height: 184,
              child: _buildPosterRow(context, topItems),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterRow(BuildContext context, List<RecommendApiItem> items) {
    final posters = items
        .map((e) => e.poster_path ?? e.backdrop_path)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
    if (posters.isEmpty) {
      return const SizedBox.shrink();
    }
    const posterWidth = 94.0;
    const posterHeight = 142.0;
    final children = <Widget>[];
    for (var i = 0; i < posters.length && i < 3; i++) {
      var angleValue = 0.0;
      var offsetValue = Offset(0, 0);
      if (i == 0) {
        angleValue = 8;
        offsetValue = const Offset(-82, 8);
      } else if (i == 1) {
        angleValue = -4;
        offsetValue = const Offset(0, 18);
      } else {
        angleValue = 6;
        offsetValue = const Offset(82, 8);
      }

      final angle = angleValue * math.pi / 180;

      children.add(
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: offsetValue,
            child: Transform.rotate(
              angle: angle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedImage(
                    imageUrl: ImageUtil.convertCacheImageUrl(posters[i]),
                    width: posterWidth,
                    height: posterHeight,
                    fit: BoxFit.cover,
                    memCacheWidth: _scaledCacheExtent(context, posterWidth),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(
      children: [if (children.length == 1) children[0] else ...children],
    );
  }

  Widget _buildBottomStatusHost(BuildContext context) {
    return Obx(
      () => _buildBottomStatus(
        context,
        isLoading: controller.isLoading.value,
        hasMore: controller.hasMore.value,
        hasItems: controller.items.isNotEmpty,
        error: controller.error.value,
      ),
    );
  }

  Widget _buildBottomStatus(
    BuildContext context, {
    required bool isLoading,
    required bool hasMore,
    required bool hasItems,
    required String? error,
  }) {
    if (!hasItems) {
      return const SizedBox.shrink();
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: OutlinedButton(
          onPressed: controller.loadMore,
          child: const Text('加载更多'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Text(
            '已经到底啦',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  void _openDetail(RecommendApiItem item) {
    final path = HttpPathBuilderUtil.buildMediaPath(item);
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _bestTitle(item);
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
      if (item.poster_path != null && item.poster_path!.isNotEmpty)
        'poster_path': item.poster_path!,
      if (item.backdrop_path != null && item.backdrop_path!.isNotEmpty)
        'backdrop_path': item.backdrop_path!,
      if (item.vote_average != null && item.vote_average! > 0)
        'vote_average': item.vote_average!.toStringAsFixed(1),
    };
    Get.toNamed('/media-detail', parameters: params);
  }

  String? _bestTitle(RecommendApiItem item) {
    final title = item.title;
    if (title != null && title.trim().isNotEmpty) return title.trim();
    final enTitle = item.en_title;
    if (enTitle != null && enTitle.trim().isNotEmpty) return enTitle.trim();
    final original = item.original_title ?? item.original_name;
    if (original != null && original.trim().isNotEmpty) {
      return original.trim();
    }
    return null;
  }

  Color _readableOnColor(Color color) {
    return color.computeLuminance() > 0.48 ? Colors.black87 : Colors.white;
  }
}

class _RecommendCategoryItemGlowPainter extends CustomPainter {
  const _RecommendCategoryItemGlowPainter({
    required this.accent,
    required this.isDark,
    this.strongBottom = false,
  });

  final Color accent;
  final bool isDark;
  final bool strongBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(bounds, const Radius.circular(20));

    final topGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.9, -0.82),
        radius: 1.08,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.12 : 0.30),
          accent.withValues(alpha: isDark ? 0.08 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(bounds);
    canvas.drawRRect(rrect, topGlow);

    final bottomGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.92, 0.94),
        radius: strongBottom ? 1.1 : 0.86,
        colors: [
          accent.withValues(alpha: strongBottom ? 0.18 : 0.10),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawRRect(rrect, bottomGlow);

    canvas.drawRRect(
      rrect.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.34),
    );
  }

  @override
  bool shouldRepaint(covariant _RecommendCategoryItemGlowPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.isDark != isDark ||
        oldDelegate.strongBottom != strongBottom;
  }
}
