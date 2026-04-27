import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_card.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/grid_layout.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/media_search_list_controller.dart';

class MediaSearchListPage extends GetView<MediaSearchListController> {
  const MediaSearchListPage({super.key});
  static const double _gridSpacing = 8;
  static const double _gridPadding = 16;
  static const double _cardAspectRatio = 1 / 1.3;
  static const double _listCardHeight = 250;
  static const double _immersiveHeaderHeight = 250;
  static const double _narrowScreenBreakpoint = 600;
  static const int _skeletonGridCount = 8;
  static const int _skeletonListCount = 6;
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.items.toList();
      final theme = _firstItemTheme(items);
      final bodyColor = AppTheme.darkBackgroundColor;
      final immersive = true;
      return Scaffold(
        backgroundColor: bodyColor,
        body: _buildBody(
          context,
          immersive: immersive,
          bodyColor: bodyColor,
          theme: theme,
        ),
      );
    });
  }

  Widget _buildBody(
    BuildContext context, {
    required bool immersive,
    required Color bodyColor,
    required ({
      Color themeColor,
      Color secondaryColor,
      List<RecommendApiItem> topItems,
    })?
    theme,
  }) {
    return Obx(() {
      final items = controller.items.toList();
      final isLoading = controller.isLoading.value;
      final error = controller.error.value;
      final hasMore = controller.hasMore.value;
      final isNarrowScreen =
          MediaQuery.sizeOf(context).width < _narrowScreenBreakpoint;
      final viewMode = controller.resolvedViewMode(
        isNarrowScreen: isNarrowScreen,
      );
      final layout = gridLayout(
        context,
        gridSpacing: _gridSpacing,
        gridPadding: _gridPadding,
      );
      final showSkeletonItems = isLoading && items.isEmpty;
      return RefreshIndicator(
        onRefresh: () => controller.search(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildImmersiveHeader(
              context,
              theme: theme,
              bodyColor: bodyColor,
              isLoading: isLoading,
              hasItems: items.isNotEmpty,
              viewMode: viewMode,
              isNarrowScreen: isNarrowScreen,
            ),
            SliverToBoxAdapter(
              child: _buildSummary(context, immersive: immersive),
            ),
            if (!showSkeletonItems && items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildPlaceholderState(
                  isLoading,
                  error,
                  immersive: immersive,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  _gridPadding,
                  0,
                  _gridPadding,
                  _gridPadding,
                ),
                sliver: viewMode == SearchResultViewMode.list
                    ? _buildListSliver(
                        items,
                        showSkeletonItems: showSkeletonItems,
                      )
                    : _buildGridSliver(
                        items,
                        layout.crossAxisCount,
                        showSkeletonItems: showSkeletonItems,
                      ),
              ),
            SliverToBoxAdapter(
              child: _buildBottomStatus(
                context,
                isLoading: isLoading,
                hasMore: hasMore,
                hasItems: items.isNotEmpty,
                error: error,
                immersive: immersive,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      );
    });
  }

  Widget _buildGridSliver(
    List<RecommendApiItem> items,
    int crossAxisCount, {
    required bool showSkeletonItems,
  }) {
    return Skeletonizer.sliver(
      enabled: showSkeletonItems,
      child: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMediaItem(
            items,
            index,
            showSkeletonItems: showSkeletonItems,
            listMode: false,
          ),
          childCount: showSkeletonItems ? _skeletonGridCount : items.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: _gridSpacing,
          crossAxisSpacing: _gridSpacing,
          childAspectRatio: _cardAspectRatio,
        ),
      ),
    );
  }

  Widget _buildListSliver(
    List<RecommendApiItem> items, {
    required bool showSkeletonItems,
  }) {
    return Skeletonizer.sliver(
      enabled: showSkeletonItems,
      child: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  index ==
                      (showSkeletonItems ? _skeletonListCount : items.length) -
                          1
                  ? 0
                  : _gridSpacing,
            ),
            child: SizedBox(
              height: _listCardHeight,
              child: _buildMediaItem(
                items,
                index,
                showSkeletonItems: showSkeletonItems,
                listMode: true,
              ),
            ),
          );
        }, childCount: showSkeletonItems ? _skeletonListCount : items.length),
      ),
    );
  }

  Widget _buildMediaItem(
    List<RecommendApiItem> items,
    int index, {
    required bool showSkeletonItems,
    required bool listMode,
  }) {
    if (showSkeletonItems) {
      return RecommendItemCard(
        item: RecommendApiItem(),
        onTap: null,
        cardHeight: listMode ? _listCardHeight : null,
      );
    }
    final item = items[index];
    return Obx(() {
      final appService = Get.find<AppService>();
      final existsOn = appService.enableFetchMediaserverLibraryStatus.value;
      final existsKey = controller.mediaserverExistsKey(item);
      final inLib =
          existsOn && (controller.mediaserverInLibrary[existsKey] ?? false);
      return RecommendItemCard(
        item: item,
        cardHeight: listMode ? _listCardHeight : null,
        inLibrary: inLib,
        onTap: () => _openDetail(item),
      );
    });
  }

  Widget _buildSummary(BuildContext context, {required bool immersive}) {
    return Obx(() {
      final count = controller.items.length;
      final total = controller.totalItems.value;
      final summary = total != null ? '共找到 $total 条结果' : '共找到 $count 条结果';
      return Skeletonizer(
        enabled: controller.isLoading.value && count == 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => controller.search(),
                child: const Text('重新搜索'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlaceholderState(
    bool isLoading,
    String? error, {
    required bool immersive,
  }) {
    if (isLoading) {
      return Skeletonizer(
        enabled: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, immersive ? 0 : 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 12),
              Text('正在搜索…', style: TextStyle(fontSize: 16)),
              SizedBox(height: 12),
              Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    final message = error ?? '暂无数据，请尝试其它关键字';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => controller.search(),
          child: const Text('重新加载'),
        ),
      ],
    );
  }

  Widget _buildBottomStatus(
    BuildContext context, {
    required bool isLoading,
    required bool hasMore,
    required bool hasItems,
    required String? error,
    required bool immersive,
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
            style: TextStyle(color: immersive ? Colors.white70 : Colors.grey),
          ),
        ],
      ),
    );
  }

  ({Color themeColor, Color secondaryColor, List<RecommendApiItem> topItems})?
  _firstItemTheme(List<RecommendApiItem> items) {
    if (items.isEmpty) return null;
    final first = items.first;
    final url = (first.poster_path ?? first.backdrop_path) ?? '';
    if (url.isEmpty) return null;
    final cache = Get.find<PluginPaletteCache>();
    final color = cache.watchColor(url) ?? cache.getCached(url);
    if (color == null) return null;
    final secondUrl = items.length > 1
        ? (items[1].poster_path ?? items[1].backdrop_path) ?? ''
        : '';
    final secondary =
        (secondUrl.isNotEmpty ? cache.watchColor(secondUrl) : null)?.withValues(
          alpha: 0.6,
        ) ??
        color.withValues(alpha: 0.9);
    return (
      themeColor: color,
      secondaryColor: secondary,
      topItems: items.take(3).toList(),
    );
  }

  SliverAppBar _buildImmersiveHeader(
    BuildContext context, {
    required ({
      Color themeColor,
      Color secondaryColor,
      List<RecommendApiItem> topItems,
    })?
    theme,
    required Color bodyColor,
    required bool isLoading,
    required bool hasItems,
    required SearchResultViewMode viewMode,
    required bool isNarrowScreen,
  }) {
    final baseA = Colors.black;
    final baseB = Colors.black.withValues(alpha: 0.5);
    final baseC = bodyColor;
    final targetA = theme?.secondaryColor ?? baseA;
    final targetB = (theme?.themeColor ?? baseA).withValues(alpha: 0.5);
    final targetC = bodyColor;
    final title = Obx(
      () => Text(
        controller.keyword.value.isEmpty
            ? '媒体搜索'
            : '搜索：${controller.keyword.value}',
        style: const TextStyle(color: Colors.white),
      ),
    );
    return SliverAppBar(
      pinned: true,
      expandedHeight: _immersiveHeaderHeight,
      backgroundColor: Colors.transparent,
      title: hasItems ? title : null,
      actions: [
        IconButton(
          tooltip: viewMode == SearchResultViewMode.list ? '切换为网格' : '切换为列表',
          onPressed: () =>
              controller.toggleViewMode(isNarrowScreen: isNarrowScreen),
          icon: Icon(
            viewMode == SearchResultViewMode.list
                ? CupertinoIcons.square_grid_2x2
                : CupertinoIcons.list_bullet,
            color: Colors.white,
          ),
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: Get.back,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: theme == null ? 0 : 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            final a = Color.lerp(baseA, targetA, t)!;
            final b = Color.lerp(baseB, targetB, t)!;
            final c = Color.lerp(baseC, targetC, t)!;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [a, b, c],
                  stops: const [0, 0.6, 1.0],
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: SizedBox(
              height: 160,
              child: (!isLoading && theme != null)
                  ? _buildPosterRow(theme.topItems)
                  : Center(
                      child: CupertinoActivityIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterRow(List<RecommendApiItem> items) {
    final posters = items
        .map((e) => e.poster_path ?? e.backdrop_path)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
    if (posters.isEmpty) return const SizedBox.shrink();
    final size = 90.0;
    if (posters.length == 1) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedImage(
            imageUrl: ImageUtil.convertCacheImageUrl(posters.first),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (posters.length == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedImage(
              imageUrl: ImageUtil.convertCacheImageUrl(posters[0]),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedImage(
              imageUrl: ImageUtil.convertCacheImageUrl(posters[1]),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    }
    final children = <Widget>[];
    for (var i = 0; i < posters.length && i < 3; i++) {
      var angleValue = 0.0;
      var offsetValue = Offset.zero;
      if (i == 0) {
        angleValue = 10;
        offsetValue = Offset(-size + 10, 0);
      } else if (i == 1) {
        angleValue = -5;
        offsetValue = Offset(0, size / 4);
      } else {
        angleValue = 8;
        offsetValue = Offset(size - 10, size - 30);
      }
      final angle = angleValue * math.pi / 180;
      children.add(
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: offsetValue,
            child: Transform.rotate(
              angle: angle,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedImage(
                  imageUrl: ImageUtil.convertCacheImageUrl(posters[i]),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: children);
  }

  void _openDetail(RecommendApiItem item) {
    final path = _buildMediaPath(item);
    if (path == null) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _bestTitle(item);
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
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

  String? _buildMediaPath(RecommendApiItem item) {
    final prefix = item.mediaid_prefix;
    final mediaId = item.media_id;
    if (prefix != null &&
        prefix.isNotEmpty &&
        mediaId != null &&
        mediaId.isNotEmpty) {
      return '$prefix:$mediaId';
    }
    final tmdbId = item.tmdb_id;
    if (tmdbId != null && tmdbId.isNotEmpty) {
      return 'tmdb:$tmdbId';
    }
    final doubanId = item.douban_id;
    if (doubanId != null && doubanId.isNotEmpty) {
      return 'douban:$doubanId';
    }
    final bangumiId = item.bangumi_id;
    if (bangumiId != null && bangumiId.isNotEmpty) {
      return 'bangumi:$bangumiId';
    }
    return null;
  }
}
