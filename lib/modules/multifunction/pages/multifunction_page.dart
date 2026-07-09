import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/modules/multifunction/models/multifunction_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/app_glass_card.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/dashboard_scaffold.dart';

class MultifunctionPage extends GetView<MultifunctionController> {
  const MultifunctionPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static bool get _isDark => Get.isDarkMode;
  static Color get _surface =>
      _isDark ? const Color(0xE619191F) : const Color(0xF7FFFFFF);
  static Color get _surfaceHighest =>
      _isDark ? const Color(0xFF2B2B33) : const Color(0xFFE2E8F0);
  static Color get _outlineSoft =>
      _isDark ? const Color(0x14FFFFFF) : const Color(0x1F0F172A);
  static Color get _textPrimary =>
      _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get _textSecondary =>
      _isDark ? const Color(0xFFC7C7CC) : const Color(0xFF475569);
  static Color get _textMuted =>
      _isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B);
  static Color get _primary =>
      _isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
  static Color get _primaryStrong =>
      _isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
  static Color get _secondary =>
      _isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7C3AED);
  static Color get _secondaryStrong =>
      _isDark ? const Color(0xFFA855F7) : const Color(0xFF6D28D9);
  static Color get _error =>
      _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB42318);

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      appBar: _buildNavigationBar(context),
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
          '/plugin',
        };
        final utilityModules = modules
            .where((module) => !hiddenRoutes.contains(module.route))
            .toList();
        final sidebarNavItems = controller.sidebarNavItems;

        return LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth;
            final horizontalPadding = pageWidth >= 720 ? 24.0 : 20.0;
            final contentMaxWidth = pageWidth >= 1100 ? 1024.0 : 920.0;
            final topPadding =
                MediaQuery.paddingOf(context).top + kToolbarHeight + 12;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: RefreshIndicator(
                  onRefresh: controller.refreshDashboard,
                  color: _primaryStrong,
                  backgroundColor: _surfaceHighest,
                  child: ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
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
                        _buildDownloaderSection(pageWidth: pageWidth),
                        const SizedBox(height: 16),
                      ],
                      if (controller.canAccessManage) ...[
                        _buildPluginSidebarSection(
                          pageWidth: pageWidth,
                          items: sidebarNavItems,
                          pluginModule: modulesByRoute['/plugin'],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (utilityModules.isNotEmpty)
                        _buildUtilitiesSection(modules: utilityModules),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  PreferredSizeWidget _buildNavigationBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
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
      title: Text(
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
    final moviePosters = _postersForRoute('/subscribe-movie');
    final tvPosters = _postersForRoute('/subscribe-tv');
    final useColumns = pageWidth >= 700;

    final movieCard = _subscriptionCategoryCard(
      title: '电影订阅',
      count: info.movieCount,
      accent: _primaryStrong,
      posters: moviePosters,
      onTap: movieModule == null
          ? null
          : () => controller.handleRouteTap(
              movieModule.route,
              title: movieModule.title,
            ),
    );
    final tvCard = _subscriptionCategoryCard(
      title: '剧集订阅',
      count: info.tvCount,
      accent: _secondaryStrong,
      posters: tvPosters,
      onTap: tvModule == null
          ? null
          : () => controller.handleRouteTap(
              tvModule.route,
              title: tvModule.title,
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '订阅',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (!controller.subscribeDataReady.value)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 14, color: _textMuted),
                  const SizedBox(width: 5),
                  Text(
                    '数据暂不可用',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (useColumns)
          Row(
            children: [
              Expanded(child: movieCard),
              const SizedBox(width: 12),
              Expanded(child: tvCard),
            ],
          )
        else
          Column(children: [movieCard, const SizedBox(height: 12), tvCard]),
      ],
    );
  }

  Widget _subscriptionCategoryCard({
    required String title,
    required int count,
    required Color accent,
    required List<String> posters,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: '$title，共 $count 部',
      child: AppGlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderRadius: 18,
        accentColor: accent,
        child: SizedBox(
          height: 132,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(17),
                ),
                child: SizedBox(
                  width: 108,
                  height: double.infinity,
                  child: _buildSubscriptionPosterCollage(
                    title: title,
                    accent: accent,
                    posters: posters,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$count 部',
                        style: TextStyle(
                          color: accent,
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '查看订阅',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionPosterCollage({
    required String title,
    required Color accent,
    required List<String> posters,
  }) {
    if (posters.isEmpty) {
      return ColoredBox(
        color: _surfaceHighest.withValues(alpha: _isDark ? 0.58 : 0.46),
        child: Icon(
          title.startsWith('电影')
              ? Icons.movie_filter_rounded
              : Icons.live_tv_rounded,
          color: accent,
          size: 30,
        ),
      );
    }

    final visiblePosters = posters.take(3).toList();
    final leftOffsets = switch (visiblePosters.length) {
      1 => const [19.0],
      2 => const [10.0, 30.0],
      _ => const [5.0, 21.0, 37.0],
    };
    final topOffsets = switch (visiblePosters.length) {
      1 => const [13.0],
      2 => const [17.0, 11.0],
      _ => const [20.0, 15.0, 10.0],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _isDark ? 0.08 : 0.055),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: _isDark ? 0.16 : 0.11),
            _surfaceHighest.withValues(alpha: _isDark ? 0.54 : 0.70),
          ],
        ),
      ),
      child: Stack(
        children: [
          for (var index = 0; index < visiblePosters.length; index++)
            Positioned(
              left: leftOffsets[index],
              top: topOffsets[index],
              child: Container(
                width: 66,
                height: 102,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.92),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDark ? 0.26 : 0.14,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedImage(
                  imageUrl: visiblePosters[index],
                  fit: BoxFit.cover,
                ),
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
            Expanded(
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
      data: CupertinoThemeData(primaryColor: _textPrimary),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: value,
        backgroundColor: _surface,
        thumbColor: _surfaceHighest,
        children: {
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
                        Center(
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
                                  style: TextStyle(
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
                            style: TextStyle(
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
              style: TextStyle(
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
        child: Center(
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
        Text(
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
                  style: TextStyle(
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

  Widget _buildDownloaderSection({required double pageWidth}) {
    final info = controller.downloaderInfo.value;
    final clients = info.clients;
    final isCompact = pageWidth < 360;
    final ready = controller.downloaderDataReady.value;

    return _glassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.openDownloaderList,
            child: Row(
              children: [
                Icon(Icons.cloud_download_rounded, color: _primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _primary.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    ready ? '${clients.length} 个' : '加载中',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 20, color: _textMuted),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
          if (!ready)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CupertinoActivityIndicator(color: _primary)),
            )
          else if (clients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '暂无下载器',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
            )
          else
            for (var i = 0; i < clients.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildDownloaderClientRow(clients[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildDownloaderClientRow(DownloaderClientInfo client) {
    final typeLabel = _downloaderTypeLabel(client.type);
    return Material(
      color: _surfaceHighest.withValues(alpha: _isDark ? 0.34 : 0.72),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.openDownloaderClient(client),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.download_for_offline_outlined,
                  size: 18,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (typeLabel.isNotEmpty) typeLabel,
                        '↓ ${_formatSpeedText(client.downloadSpeed)}',
                        '↑ ${_formatSpeedText(client.uploadSpeed)}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _downloaderTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'qbittorrent':
        return 'qB';
      case 'transmission':
        return 'TR';
      default:
        return type.trim();
    }
  }

  String _formatSpeedText(double value) {
    final parts = _sizeParts(value);
    return '${parts.$1} ${parts.$2}/s';
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
        color: _surfaceHighest.withValues(alpha: _isDark ? 0.34 : 0.72),
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
                style: TextStyle(
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
                style: TextStyle(
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
                  style: TextStyle(
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

  Widget _buildPluginSidebarSection({
    required double pageWidth,
    required List<PluginSidebarNavItem> items,
    DashboardModuleViewModel? pluginModule,
  }) {
    final crossAxisCount = pageWidth >= 960
        ? 4
        : pageWidth >= 640
        ? 3
        : 2;
    final childAspectRatio = pageWidth >= 640 ? 1.65 : 1.35;
    final pluginMeta = pluginModule?.primaryText.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.handleRouteTap('/plugin', title: '插件'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '插件中心',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (pluginMeta.isNotEmpty) ...[
                    Text(
                      pluginMeta,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: _textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (_, index) =>
                _pluginSidebarCard(items[index], index: index),
          ),
        ],
      ],
    );
  }

  Widget _pluginSidebarCard(PluginSidebarNavItem item, {required int index}) {
    final accent = _sidebarAccent(item.section, index);
    final icon =
        VuetifyMappings.iconFromMdi(item.icon) ?? Icons.extension_outlined;
    final softAccent = _softUtilityAccent(accent);
    final iconBackground = _isDark
        ? accent.withValues(alpha: 0.14)
        : softAccent.withValues(alpha: 0.72);
    final arrowBackground = _surfaceHighest.withValues(
      alpha: _isDark ? 0.36 : 0.54,
    );
    final subtitle = _sidebarSectionLabel(item.section);

    return Semantics(
      button: true,
      label: '${item.title}，$subtitle',
      child: AppGlassCard(
        onTap: () => controller.handleSidebarNavTap(item),
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        accentColor: accent,
        surfaceAlpha: _isDark ? 0.54 : 0.70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: _isDark ? 0.08 : 0.14),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(icon, size: 21, color: accent),
                ),
                const Spacer(),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: arrowBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _sidebarAccent(String section, int index) {
    switch (section) {
      case 'organize':
        return const Color(0xFF8E44AD);
      case 'system':
        return const Color(0xFF8F67FF);
      default:
        return index.isEven ? _primaryStrong : _secondaryStrong;
    }
  }

  String _sidebarSectionLabel(String section) {
    switch (section) {
      case 'organize':
        return '整理插件';
      case 'system':
        return '系统插件';
      default:
        return '插件功能';
    }
  }

  Widget _buildUtilitiesSection({
    required List<DashboardModuleViewModel> modules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '实用工具',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        _glassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < modules.length; index++)
                _utilityRow(
                  module: modules[index],
                  showDivider: index < modules.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _utilityRow({
    required DashboardModuleViewModel module,
    required bool showDivider,
  }) {
    final title = _utilityTitle(module.title);
    final meta = module.primaryText.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            controller.handleRouteTap(module.route, title: module.title),
        child: Container(
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: _outlineSoft, width: 0.5))
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: module.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(module.icon, size: 18, color: module.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (meta.isNotEmpty) ...[
                Text(
                  meta,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded, size: 20, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return AppGlassCard(
      onTap: onTap,
      padding: padding,
      borderRadius: 18,
      surfaceAlpha: _isDark ? 0.56 : 0.74,
      child: child,
    );
  }

  List<String> _postersForRoute(String route) {
    return controller.subscribeInfo.value.posterItems
        .where((item) => item.route == route && item.poster.trim().isNotEmpty)
        .map((item) => controller.normalizePoster(item.poster))
        .where((poster) => poster.isNotEmpty)
        .take(3)
        .toList();
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

  Color _softUtilityAccent(Color accent) {
    if (_isDark) return accent;
    return Color.lerp(_surface, accent, 0.11) ?? accent.withValues(alpha: 0.11);
  }

  static String _shortDate(String date) {
    if (date.length >= 10) {
      return date.substring(5, 10);
    }
    return date;
  }
}
