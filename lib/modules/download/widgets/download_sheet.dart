import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/download/controllers/download_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/models/downloader_stats.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';

class DownloadSheet extends GetView<DownloadController> {
  const DownloadSheet({super.key, required this.item});

  final SearchResultItem item;

  AppService get _appService => Get.find<AppService>();

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      header: _buildHeader(context),
      scrollController: controller.scrollController,
      snapSizes: const [0.5, 0.7, 0.9],
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: ListView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _buildMediaHero(context),
            const SizedBox(height: 18),
            _buildDownloaderSelector(context),
            const SizedBox(height: 16),
            _buildDirectorySelector(context),
            const SizedBox(height: 16),
            _buildAdvancedOptions(context),
            const SizedBox(height: 20),
            _buildBottomActions(context),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下载资源',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.72,
                      ),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaHero(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final torrent = item.torrent_info;
    final title = torrent?.title?.trim() ?? '';
    final siteName = torrent?.site_name?.trim().isNotEmpty == true
        ? torrent!.site_name!.trim()
        : '未知站点';
    final size = torrent?.size ?? 0.0;
    final seeders = torrent?.seeders ?? 0;
    final peers = torrent?.peers ?? 0;
    final grabs = torrent?.grabs ?? 0;
    final pubdate = torrent?.pubdate ?? '';
    final volumeFactor = _displayVolumeFactor(torrent);
    final downloadFactor = torrent?.downloadvolumefactor;
    final uploadFactor = torrent?.uploadvolumefactor;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: _panelDecoration(
        context,
        tint: scheme.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTopBadge(
                      context,
                      icon: CupertinoIcons.cube_box,
                      label: siteName,
                      color: scheme.primary,
                    ),
                    _buildTopBadge(
                      context,
                      icon: CupertinoIcons.tray_arrow_down,
                      label: SizeFormatter.formatSize(size, 2),
                      color: const Color(0xFF6D5EF8),
                      filled: true,
                    ),
                    if (volumeFactor.isNotEmpty)
                      _buildTopBadge(
                        context,
                        icon: CupertinoIcons.percent,
                        label: volumeFactor,
                        color: const Color(0xFFFF8A2A),
                      ),
                  ],
                ),
              ),
              if (downloadFactor != null && downloadFactor != 1) ...[
                const SizedBox(width: 8),
                _buildCompactRateBadge(
                  context,
                  label: downloadFactor == 0
                      ? '免费'
                      : '${(downloadFactor * 100).round()}%',
                  prefix: '下',
                  color: const Color(0xFFFF6B2C),
                ),
              ],
              if (uploadFactor != null && uploadFactor != 1) ...[
                const SizedBox(width: 6),
                _buildCompactRateBadge(
                  context,
                  label: '${(uploadFactor * 100).round()}%',
                  prefix: '上',
                  color: const Color(0xFF0F9B8E),
                ),
              ],
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (seeders > 0)
                _buildMetaPill(
                  context,
                  icon: CupertinoIcons.arrow_up,
                  label: '$seeders',
                  color: const Color(0xFF84CC16),
                ),
              if (peers > 0)
                _buildMetaPill(
                  context,
                  icon: CupertinoIcons.arrow_down,
                  label: '$peers',
                  color: const Color(0xFFFB7185),
                ),
              if (grabs > 0)
                _buildMetaPill(
                  context,
                  icon: CupertinoIcons.arrow_down_circle,
                  label: '$grabs 次下载',
                  color: const Color(0xFF22C55E),
                ),
              if (pubdate.isNotEmpty)
                _buildMetaPill(
                  context,
                  icon: CupertinoIcons.clock,
                  label: _formatDate(pubdate),
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloaderSelector(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _buildSectionCard(
      context,
      icon: CupertinoIcons.cloud_download,
      title: '下载器',
      child: Obx(() {
        if (controller.isLoadingDownloaders) {
          return _buildPlaceholderState(context, label: '正在加载下载器...');
        }

        final downloaders = controller.downloaders;
        final selected = controller.selectedDownloader.value;

        if (downloaders.isEmpty) {
          return _buildPlaceholderState(
            context,
            label: '暂无可用下载器',
            icon: CupertinoIcons.exclamationmark_circle,
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: downloaders.map((downloader) {
              final isSelected = selected?.name == downloader.name;
              final stats = controller.statsFor(downloader.name);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 176,
                  child: _buildSelectableSurface(
                    context,
                    title: downloader.name,
                    subtitle: _downloaderSubtitle(downloader, stats),
                    trailing: _buildDownloaderStatChip(context, stats: stats),
                    isSelected: isSelected,
                    accentColor: scheme.primary,
                    onTap: () => controller.setDownloader(downloader),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildDirectorySelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _buildSectionCard(
      context,
      icon: CupertinoIcons.folder,
      title: '保存目录',
      child: Obx(() {
        final selected = controller.selectedDirectory.value;
        final suggestions = controller.directorySuggestions;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectableSurface(
              context,
              title: '留空自动匹配',
              subtitle: '自动',
              isSelected: selected.isEmpty,
              accentColor: scheme.secondary,
              onTap: () => controller.setDirectory(''),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...suggestions.map((dir) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSelectableSurface(
                    context,
                    title: dir,
                    subtitle: '目录',
                    isSelected: selected == dir,
                    accentColor: scheme.secondary,
                    onTap: () => controller.setDirectory(dir),
                  ),
                );
              }),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      final expanded = controller.showAdvanced.value;
      return _buildSectionCard(
        context,
        icon: CupertinoIcons.number_square,
        title: 'TMDB ID',
        trailing: GestureDetector(
          onTap: () {
            controller.showAdvanced.value = !expanded;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expanded ? '收起' : '手动输入',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        child: expanded
            ? TextFormField(
                initialValue: controller.tmdbId.value,
                onChanged: controller.setTmdbId,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'TMDB ID',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: 18,
                    color: scheme.primary,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.primary, width: 1.2),
                  ),
                ),
              )
            : null,
      );
    });
  }

  Widget _buildBottomActions(BuildContext context) {
    return Obx(() {
      final showSpecial = _appService.enableSpecialDownload.value;
      if (!showSpecial) {
        return _buildActionButton(
          context,
          label: '开始下载',
          icon: CupertinoIcons.cloud_download,
          busy: controller.isDownloading.value,
          enabled: controller.selectedDownloader.value != null,
          accentColor: Theme.of(context).colorScheme.primary,
          onTap: () => controller.startDownload(
            item: item,
            customTmdbId: controller.tmdbId.value.isEmpty
                ? null
                : controller.tmdbId.value,
          ),
        );
      }

      final scheme = Theme.of(context).colorScheme;
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              label: '直连下载',
              icon: CupertinoIcons.arrow_down_doc,
              busy: controller.isSpecialDownloading.value,
              enabled: controller.selectedDownloader.value != null,
              accentColor: scheme.secondary,
              onTap: () =>
                  controller.startSpecialDownload(context: context, item: item),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              label: '开始下载',
              icon: CupertinoIcons.cloud_download,
              busy: controller.isDownloading.value,
              enabled: controller.selectedDownloader.value != null,
              accentColor: scheme.primary,
              onTap: () => controller.startDownload(
                item: item,
                customTmdbId: controller.tmdbId.value.isEmpty
                    ? null
                    : controller.tmdbId.value,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool busy,
    required bool enabled,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isEnabled = enabled && !busy;

    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isEnabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isEnabled
                    ? [
                        accentColor.withValues(alpha: 0.96),
                        accentColor.withValues(alpha: 0.78),
                      ]
                    : [
                        scheme.surfaceContainerHighest,
                        scheme.surfaceContainerHigh,
                      ],
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: busy
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: subtitle != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: scheme.primary.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: subtitle != null
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }

  Widget _buildSelectableSurface(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSelected
                ? [
                    accentColor.withValues(alpha: 0.18),
                    accentColor.withValues(alpha: 0.10),
                  ]
                : [
                    scheme.surfaceContainerLow,
                    scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                  ],
          ),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.45)
                : scheme.outlineVariant,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accentColor
                    : scheme.surfaceContainerHighest,
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : scheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                isSelected ? CupertinoIcons.check_mark : CupertinoIcons.circle,
                size: isSelected ? 12 : 11,
                color: isSelected ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accentColor : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
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

  String _downloaderSubtitle(dynamic downloader, DownloaderStats? stats) {
    if (stats != null && stats.freeSpace > 0) {
      return '剩余 ${SizeFormatter.formatSize(stats.freeSpace, 1)}';
    }
    return downloader.type.isNotEmpty ? downloader.type.toUpperCase() : '下载器';
  }

  Widget _buildDownloaderStatChip(
    BuildContext context, {
    required DownloaderStats? stats,
  }) {
    if (stats == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = stats.downloadSpeed > 0
        ? '下行 ${_formatSpeed(stats.downloadSpeed)}'
        : stats.uploadSpeed > 0
        ? '上行 ${_formatSpeed(stats.uploadSpeed)}'
        : null;
    if (label == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPlaceholderState(
    BuildContext context, {
    required String label,
    IconData icon = CupertinoIcons.clock,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: filled
            ? color
            : color.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10,
              ),
        border: Border.all(
          color: filled ? color : color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: filled ? Colors.white : color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: filled ? Colors.white : color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRateBadge(
    BuildContext context, {
    required String label,
    required String prefix,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: prefix,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final resolvedColor = color == scheme.onSurfaceVariant
        ? scheme.onSurfaceVariant
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(
          alpha: resolvedColor == scheme.onSurfaceVariant ? 0.08 : 0.10,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: resolvedColor.withValues(
            alpha: resolvedColor == scheme.onSurfaceVariant ? 0.10 : 0.14,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: resolvedColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: resolvedColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration(BuildContext context, {Color? tint}) {
    final scheme = Theme.of(context).colorScheme;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: scheme.outlineVariant),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.surface, tint ?? scheme.surfaceContainerLow],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.14
                : 0.04,
          ),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _formatSpeed(double bytesPerSecond) {
    return '${SizeFormatter.formatSize(bytesPerSecond, 1)}/s';
  }

  String _displayVolumeFactor(SearchTorrentInfo? torrent) {
    if (torrent == null) return '';
    final volumeFactor = torrent.volume_factor?.trim() ?? '';
    final downloadFactor = torrent.downloadvolumefactor;
    if (volumeFactor.isEmpty) return '';
    if (downloadFactor != null && downloadFactor != 1) {
      return '';
    }
    return volumeFactor;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}年前';
      if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}个月前';
      if (diff.inDays > 0) return '${diff.inDays}天前';
      if (diff.inHours > 0) return '${diff.inHours}小时前';
      if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
      return '刚刚';
    } catch (_) {
      return dateStr;
    }
  }
}
