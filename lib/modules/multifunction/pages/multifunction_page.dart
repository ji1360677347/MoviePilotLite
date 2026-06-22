import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class MultifunctionPage extends GetView<MultifunctionController> {
  const MultifunctionPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const Color _background = Color(0xFF131315);
  static const Color _surface = Color(0x4D1F1F21);
  static const Color _surfaceHighest = Color(0xFF353437);
  static const Color _outlineSoft = Color(0x1A8B91A0);
  static const Color _textPrimary = Color(0xFFE4E2E4);
  static const Color _textSecondary = Color(0xFFC0C6D6);
  static const Color _textMuted = Color(0xFF8B91A0);
  static const Color _primary = Color(0xFFAAC7FF);
  static const Color _primaryStrong = Color(0xFF3E90FF);
  static const Color _secondary = Color(0xFFE9B3FF);
  static const Color _secondaryStrong = Color(0xFF7D01B1);
  static const Color _error = Color(0xFFFFB4AB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildNavigationBar(),
      body: Obx(() {
        final modules = controller.buildDashboardModules();
        final modulesByRoute = <String, DashboardModuleViewModel>{
          for (final module in modules) module.route: module,
        };
        final calendarSegment = controller.calendarSegment.value;
        final calendarInfo = controller.calendarInfo.value;
        final calendarItems = calendarSegment == 'today'
            ? calendarInfo.todayItems
            : calendarInfo.weekItems;
        final hiddenRoutes = <String>{
          '/subscribe-movie',
          '/subscribe-tv',
          '/site',
          '/downloader',
          '/subscribe-calendar',
        };
        final utilityModules = modules
            .where((module) => !hiddenRoutes.contains(module.route))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth;
            final horizontalPadding = pageWidth >= 720 ? 24.0 : 20.0;
            final contentMaxWidth = pageWidth >= 1100 ? 1024.0 : 920.0;

            return Stack(
              children: [
                const Positioned.fill(child: _PageBackdrop()),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: RefreshIndicator(
                      onRefresh: controller.refreshDashboard,
                      color: _primaryStrong,
                      backgroundColor: const Color(0xFF1B1B1D),
                      child: ListView(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          104,
                        ),
                        children: [
                          if (controller.canAccessSubscribe) ...[
                            _buildSubscriptionSection(
                              pageWidth: pageWidth,
                              movieModule: modulesByRoute['/subscribe-movie'],
                              tvModule: modulesByRoute['/subscribe-tv'],
                            ),
                            const SizedBox(height: 16),
                            _buildReleasesSection(
                              pageWidth: pageWidth,
                              segment: calendarSegment,
                              items: calendarItems,
                              module: modulesByRoute['/subscribe-calendar'],
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (modulesByRoute['/site'] != null) ...[
                            _buildSitesSection(modulesByRoute['/site']!),
                            const SizedBox(height: 16),
                          ],
                          if (modulesByRoute['/downloader'] != null) ...[
                            _buildDownloaderSection(
                              pageWidth: pageWidth,
                              module: modulesByRoute['/downloader']!,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (utilityModules.isNotEmpty)
                            _buildUtilitiesSection(
                              pageWidth: pageWidth,
                              modules: utilityModules,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  PreferredSizeWidget _buildNavigationBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: Builder(
        builder: (buttonContext) => CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: Icon(
            CupertinoIcons.square_grid_2x2_fill,
            size: 18,
            color: _textPrimary,
          ),
        ),
      ),
      title: const Text(
        'More',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
        ),
      ),
      centerTitle: false,
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.toNamed('/settings'),
          child: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection({
    required double pageWidth,
    DashboardModuleViewModel? movieModule,
    DashboardModuleViewModel? tvModule,
  }) {
    final info = controller.subscribeInfo.value;
    final moviePoster = _posterForRoute('/subscribe-movie');
    final tvPoster = _posterForRoute('/subscribe-tv');
    final total = (info.movieCount + info.tvCount).clamp(1, 999999);
    final columns = pageWidth >= 760 ? 2 : 1;

    final cards = <Widget>[
      _subscriptionCard(
        title: '电影',
        poster: moviePoster,
        subtitle: '已订阅 ${info.movieCount} 部',
        progress: info.movieCount / total,
        progressColor: _primaryStrong,
        onTap: movieModule == null
            ? null
            : () => controller.handleRouteTap(
                movieModule.route,
                title: movieModule.title,
              ),
      ),
      _subscriptionCard(
        title: '剧集',
        poster: tvPoster,
        subtitle: '已订阅 ${info.tvCount} 部',
        progress: info.tvCount / total,
        progressColor: _secondaryStrong,
        onTap: tvModule == null
            ? null
            : () => controller.handleRouteTap(
                tvModule.route,
                title: tvModule.title,
              ),
      ),
    ];

    if (columns == 1) {
      return Column(children: [cards[0], const SizedBox(height: 16), cards[1]]);
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _subscriptionCard({
    required String title,
    required String poster,
    required String subtitle,
    required double progress,
    required Color progressColor,
    VoidCallback? onTap,
  }) {
    return _glassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 80,
              color: _surfaceHighest,
              child: poster.isEmpty
                  ? const Icon(Icons.movie_creation_outlined, color: _textMuted)
                  : CachedImage(
                      imageUrl: ImageUtil.convertCacheImageUrl(poster),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 4,
                    color: _surfaceHighest,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.08, 1.0),
                      child: Container(color: progressColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleasesSection({
    required double pageWidth,
    required String segment,
    required List<DashboardCalendarEntry> items,
    DashboardModuleViewModel? module,
  }) {
    final cardWidth = pageWidth >= 720 ? 144.0 : 128.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '上映日历',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            _segmentedControl(
              value: segment,
              onChanged: (next) {
                controller.setCalendarSegment(next);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          key: ValueKey('release-$segment'),
          height: items.isEmpty ? 88 : 206,
          child: items.isEmpty
              ? _emptyReleasesCard(module)
              : ListView.separated(
                  key: ValueKey('release-list-$segment'),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return _releasePosterCard(
                      width: cardWidth,
                      entry: item,
                      chipText: segment == 'today'
                          ? item.episodeCode
                          : _shortDate(item.airDate),
                      seasonEpisodeTag: segment == 'week'
                          ? item.episodeCode
                          : null,
                      onTap: module == null
                          ? null
                          : () => controller.handleRouteTap(
                              module.route,
                              title: module.title,
                            ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemCount: items.length,
                ),
        ),
      ],
    );
  }

  Widget _segmentedControl({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return CupertinoTheme(
      data: const CupertinoThemeData(primaryColor: _textPrimary),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: value,
        backgroundColor: const Color(0xFF1F1F21),
        thumbColor: const Color(0xFF353437),
        children: const {
          'today': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '今天',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
          'week': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '本周',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        },
        onValueChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }

  Widget _releasePosterCard({
    required double width,
    required DashboardCalendarEntry entry,
    required String chipText,
    String? seasonEpisodeTag,
    VoidCallback? onTap,
  }) {
    final poster = controller.normalizePoster(entry.poster);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceHighest,
                    border: Border.all(color: _outlineSoft),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (poster.isNotEmpty)
                        CachedImage(
                          imageUrl: ImageUtil.convertCacheImageUrl(poster),
                          fit: BoxFit.cover,
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.live_tv_rounded,
                            color: _textMuted,
                            size: 28,
                          ),
                        ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: seasonEpisodeTag == null
                            ? const SizedBox.shrink()
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Text(
                                  seasonEpisodeTag,
                                  style: const TextStyle(
                                    color: _primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Text(
                            chipText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.showName,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyReleasesCard(DashboardModuleViewModel? module) {
    return GestureDetector(
      onTap: module == null
          ? null
          : () => controller.handleRouteTap(module.route, title: module.title),
      child: _glassCard(
        child: const Center(
          child: Text(
            '暂无上映日历数据',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSitesSection(DashboardModuleViewModel module) {
    final info = controller.siteInfo.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '站点',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        _glassCard(
          onTap: () =>
              controller.handleRouteTap(module.route, title: module.title),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _siteRow(
                icon: Icons.dns_rounded,
                iconColor: _primary,
                title: '站点数量',
                subtitle: '当前已接入并启用的站点',
                value: '${info.siteCount} 个',
                valueColor: _textPrimary,
                showDivider: true,
              ),
              _siteRow(
                icon: Icons.north_east_rounded,
                iconColor: _primaryStrong,
                title: '累计上传',
                subtitle: '站点用户数据汇总流量',
                value: _shortSize(info.totalUpload),
                valueColor: _primary,
                showDivider: true,
              ),
              _siteRow(
                icon: Icons.south_east_rounded,
                iconColor: _secondary,
                title: '累计下载',
                subtitle: '站点用户数据汇总流量',
                value: _shortSize(info.totalDownload),
                valueColor: _secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _siteRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required Color valueColor,
    bool showDivider = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: _outlineSoft, width: 0.5))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: iconColor == _error ? _error : _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 28,
                height: 2,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloaderSection({
    required double pageWidth,
    required DashboardModuleViewModel module,
  }) {
    final info = controller.downloaderInfo.value;
    final isCompact = pageWidth < 360;

    return _glassCard(
      onTap: () => controller.handleRouteTap(module.route, title: module.title),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_download_rounded,
                color: _primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '下载器',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _primary.withValues(alpha: 0.20)),
                ),
                child: Text(
                  '${info.clients.length} 个活跃',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _downloaderMetricCard(
                  icon: Icons.arrow_downward_rounded,
                  label: '下载',
                  value: _metricNumber(info.totalDownloadSpeed),
                  unit: _metricUnit(info.totalDownloadSpeed),
                  accent: _primary,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: _downloaderMetricCard(
                  icon: Icons.arrow_upward_rounded,
                  label: '上传',
                  value: _metricNumber(info.totalUploadSpeed),
                  unit: _metricUnit(info.totalUploadSpeed),
                  accent: _secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _downloaderMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: 22,
            height: 2,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilitiesSection({
    required double pageWidth,
    required List<DashboardModuleViewModel> modules,
  }) {
    final crossAxisCount = pageWidth >= 960
        ? 5
        : pageWidth >= 760
        ? 4
        : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '实用工具',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: modules.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, index) => _utilityCard(modules[index]),
        ),
      ],
    );
  }

  Widget _utilityCard(DashboardModuleViewModel module) {
    return _glassCard(
      onTap: () => controller.handleRouteTap(module.route, title: module.title),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(module.icon, size: 28, color: module.accent),
          const SizedBox(height: 10),
          Text(
            _utilityTitle(module.title),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _outlineSoft, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }

  String _posterForRoute(String route) {
    final item = controller.subscribeInfo.value.posterItems.firstWhereOrNull(
      (item) => item.route == route && item.poster.trim().isNotEmpty,
    );
    if (item == null) return '';
    return controller.normalizePoster(item.poster);
  }

  String _metricNumber(double value) {
    final units = _sizeParts(value);
    return units.$1;
  }

  String _metricUnit(double value) {
    final units = _sizeParts(value);
    return '${units.$2}/s';
  }

  (String, String) _sizeParts(double value) {
    final units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final amount = size >= 100
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return (amount, units[unitIndex]);
  }

  String _shortSize(double value) {
    final parts = _sizeParts(value);
    return '${parts.$1} ${parts.$2}';
  }

  String _utilityTitle(String title) {
    if (title == '媒体整理') return '媒体整理';
    if (title == '文件管理') return '文件管理';
    if (title == '工作流') return '工作流';
    if (title == '插件') return '插件';
    if (title == '用户管理') return '用户管理';
    return title;
  }

  static String _shortDate(String date) {
    if (date.length >= 10) {
      return date.substring(5, 10);
    }
    return date;
  }
}

class _PageBackdrop extends StatelessWidget {
  const _PageBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111214), Color(0xFF131315), Color(0xFF0E0E10)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -60,
            child: _SoftGlow(
              size: 220,
              color: const Color(0xFF3E90FF).withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 260,
            right: -80,
            child: _SoftGlow(
              size: 240,
              color: const Color(0xFF7D01B1).withValues(alpha: 0.07),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
