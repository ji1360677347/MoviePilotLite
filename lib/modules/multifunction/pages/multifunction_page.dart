import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class MultifunctionPage extends GetView<MultifunctionController> {
  const MultifunctionPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildNavigationBar(context),
      body: Obx(() {
        final modules = controller.buildDashboardModules();
        final modulesByRoute = <String, DashboardModuleViewModel>{
          for (final module in modules) module.route: module,
        };
        final recentSearchModule = modulesByRoute['/search-result'];
        final movieModule = modulesByRoute['/subscribe-movie'];
        final tvModule = modulesByRoute['/subscribe-tv'];
        final siteModule = modulesByRoute['/site'];
        final downloaderModule = modulesByRoute['/downloader'];
        final calendarModule = modulesByRoute['/subscribe-calendar'];

        final hiddenRoutes = <String>{
          '/search-result',
          '/subscribe-movie',
          '/subscribe-tv',
          '/site',
          '/downloader',
          '/subscribe-calendar',
        };
        final restModules = modules
            .where((module) => !hiddenRoutes.contains(module.route))
            .toList();

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
            children: [
              if (recentSearchModule != null) ...[
                _sectionCard(
                  child: _simpleEntryTile(
                    context,
                    title: '最近搜索',
                    onTap: () => controller.handleRouteTap(
                      recentSearchModule.route,
                      title: recentSearchModule.title,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildSubscriptionHero(
                context,
                movieModule: movieModule,
                tvModule: tvModule,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 190,
                      child: _buildSiteCard(context, siteModule),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 190,
                      child: _buildDownloaderCard(context, downloaderModule),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCalendarCard(context, calendarModule),
              const SizedBox(height: 12),
              _sectionTitle('功能入口'),
              const SizedBox(height: 8),
              ...restModules.map((module) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _sectionCard(child: _moduleEntryTile(context, module)),
                );
              }),
              const SizedBox(height: 50),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildNavigationBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'More',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: null,
        child: const Icon(Icons.grid_view_rounded, color: Colors.white),
      ),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.toNamed('/settings'),
          child: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _buildSubscriptionHero(
    BuildContext context, {
    DashboardModuleViewModel? movieModule,
    DashboardModuleViewModel? tvModule,
  }) {
    final movieCount = controller.subscribeInfo.value.movieCount;
    final tvCount = controller.subscribeInfo.value.tvCount;
    final posterItems = controller.subscribeInfo.value.posterItems
        .map(
          (item) => SubscribePosterItem(
            poster: controller.normalizePoster(item.poster),
            route: item.route,
          ),
        )
        .where((item) => item.poster.isNotEmpty)
        .take(8)
        .toList();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '我的订阅',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '管理您的订阅内容',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (posterItems.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, index) {
                  final item = posterItems[index];
                  final poster = ImageUtil.convertCacheImageUrl(item.poster);
                  return InkWell(
                    onTap: () =>
                        controller.handleRouteTap(item.route, title: '订阅'),
                    borderRadius: BorderRadius.circular(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 94,
                        color: const Color(0xFF334155),
                        child: CachedImage(imageUrl: poster, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: posterItems.length > 6 ? 6 : posterItems.length,
              ),
            )
          else
            _emptyText(movieModule?.emptyText ?? '暂无数据，点击进入'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _heroStatTile(
                  icon: Icons.movie_outlined,
                  title: '电影',
                  value: '$movieCount 部',
                  color: const Color(0xFF3B82F6),
                  onTap: () => controller.handleRouteTap(
                    '/subscribe-movie',
                    title: '电影订阅',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroStatTile(
                  icon: Icons.tv,
                  title: '剧集',
                  value: '$tvCount 部',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => controller.handleRouteTap(
                    '/subscribe-tv',
                    title: '电视剧订阅',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(
    BuildContext context,
    DashboardModuleViewModel? module,
  ) {
    final info = controller.siteInfo.value;
    return _sectionCard(
      onTap: module == null
          ? null
          : () => controller.handleRouteTap(module.route, title: module.title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                module?.icon ?? Icons.public_outlined,
                color: module?.accent ?? const Color(0xFF60A5FA),
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  module?.title ?? '站点管理',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${info.siteCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _tinyMetric(
                  title: '上传',
                  value: _shortSize(info.totalUpload),
                  valueColor: const Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _tinyMetric(
                  title: '下载',
                  value: _shortSize(info.totalDownload),
                  valueColor: const Color(0xFF34D399),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloaderCard(
    BuildContext context,
    DashboardModuleViewModel? module,
  ) {
    final info = controller.downloaderInfo.value;
    return _sectionCard(
      onTap: module == null
          ? null
          : () => controller.handleRouteTap(module.route, title: module.title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                module?.icon ?? Icons.download_outlined,
                color: module?.accent ?? const Color(0xFF34D399),
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  module?.title ?? '下载器',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _speedLine(
            arrow: '↓',
            speed: '${_shortSize(info.totalDownloadSpeed)}/s',
            color: const Color(0xFF60A5FA),
          ),
          const SizedBox(height: 6),
          _speedLine(
            arrow: '↑',
            speed: '${_shortSize(info.totalUploadSpeed)}/s',
            color: const Color(0xFF34D399),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${info.clients.length} 个下载器在线',
              style: const TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '下载 ${_shortSize(info.totalDownloadSize)} ',
            style: TextStyle(
              color: CupertinoColors.activeBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '上传 ${_shortSize(info.totalUploadSize)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    DashboardModuleViewModel? module,
  ) {
    return _sectionCard(
      onTap: module == null
          ? null
          : () => controller.handleRouteTap(module.route, title: module.title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text(
                      '上映日历',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                ),
              ),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: controller.calendarSegment.value,
                backgroundColor: const Color(0xFF334155),
                thumbColor: const Color(0xFF3B82F6),
                children: const {
                  'today': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Text(
                      '今天',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  'week': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Text(
                      '本周',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    controller.setCalendarSegment(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (module != null && module.hasData) ...[
            _calendarSummaryBar(controller.calendarSegment.value),
            const SizedBox(height: 20),
            ..._buildCalendarRows(controller.calendarSegment.value),
          ] else
            _emptyText('暂无数据，点击进入'),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _moduleEntryTile(
    BuildContext context,
    DashboardModuleViewModel module,
  ) {
    return InkWell(
      onTap: () => controller.handleRouteTap(module.route, title: module.title),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: module.accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(module.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (module.hasData || module.emptyText != null) ...[
                  Text(
                    module.hasData
                        ? module.secondaryText
                        : module.emptyText ?? '',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _simpleEntryTile(
    BuildContext context, {
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _heroStatTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarRow({
    required String timeOrDate,
    required String title,
    required String episodeCode,
    required String poster,
    required Color dotColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            timeOrDate,
            style: const TextStyle(
              color: Color(0xFFA78BFA),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 38,
            height: 38,
            color: const Color(0xFF334155),
            child: poster.isEmpty
                ? const Icon(
                    Icons.live_tv_rounded,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  )
                : Image.network(
                    poster,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.live_tv_rounded,
                      color: Color(0xFF94A3B8),
                      size: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                episodeCode,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          width: 14,
          alignment: Alignment.centerRight,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _sectionCard({required Widget child, VoidCallback? onTap}) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tinyMetric({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _speedLine({
    required String arrow,
    required String speed,
    required Color color,
  }) {
    return Row(
      children: [
        Text(
          arrow,
          style: TextStyle(
            color: color,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          speed,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _calendarSummaryBar(String segment) {
    final info = controller.calendarInfo.value;
    final count = segment == 'today' ? info.todayCount : info.weekCount;
    final label = segment == 'today' ? '今天上映' : '本周上映';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $count 条',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildCalendarRows(String segment) {
    final info = controller.calendarInfo.value;
    final items = segment == 'today' ? info.todayItems : info.weekItems;
    if (items.isEmpty) {
      return [_emptyText('暂无数据，点击进入')];
    }
    final dotColors = <Color>[
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF60A5FA),
      const Color(0xFFA78BFA),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final leading = segment == 'today'
          ? item.episodeCode
          : _shortDate(item.airDate);
      rows.add(
        _calendarRow(
          timeOrDate: leading,
          title: item.showName,
          episodeCode: item.episodeCode,
          poster: item.poster,
          dotColor: dotColors[i % dotColors.length],
        ),
      );
      if (i != items.length - 1) {
        rows.add(const SizedBox(height: 10));
      }
    }
    return rows;
  }

  String _shortSize(double size) {
    final units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var value = size;
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    final text = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text ${units[index]}';
  }

  String _shortDate(String date) {
    if (date.length >= 10) {
      return date.substring(5, 10);
    }
    return date;
  }
}
