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
      snap: false,
      snapSizes: const [],
      initialChildSize: 0.7,
      minChildSize: 0.28,
      maxChildSize: 0.8,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _buildCompactSummary(context),
          const SizedBox(height: 10),
          _buildDownloadSettingsSection(context),
          const SizedBox(height: 10),
          _buildTmdbInput(context),
          const SizedBox(height: 12),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '下载资源',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummary(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final torrent = item.torrent_info;
    final title = torrent?.title?.trim() ?? '';
    final siteName = torrent?.site_name?.trim().isNotEmpty == true
        ? torrent!.site_name!.trim()
        : '未知站点';
    final size = torrent?.size ?? 0.0;
    final volumeFactor = _displayVolumeFactor(torrent);
    final downloadFactor = torrent?.downloadvolumefactor;
    final uploadFactor = torrent?.uploadvolumefactor;
    final sizeLabel = SizeFormatter.formatSize(size, 2);
    final trafficSummary = _buildTrafficSummary(
      volumeFactor: volumeFactor,
      downloadFactor: downloadFactor,
      uploadFactor: uploadFactor,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              thickness: 0.6,
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSummaryMetaItem(
                context,
                icon: CupertinoIcons.globe,
                text: siteName,
              ),
              _buildSummaryMetaItem(
                context,
                icon: CupertinoIcons.tray_arrow_down,
                text: sizeLabel,
                emphasize: true,
              ),
              if (trafficSummary.isNotEmpty)
                _buildSummaryMetaItem(
                  context,
                  icon: CupertinoIcons.arrow_up_arrow_down_circle,
                  text: trafficSummary,
                  tintColor: theme.colorScheme.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetaItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    bool emphasize = false,
    Color? tintColor,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color =
        tintColor ?? (emphasize ? scheme.onSurface : scheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadSettingsSection(BuildContext context) {
    return _buildSection(
      context,
      title: '下载设置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => _buildSubsectionLabel(
              context,
              '下载器',
              controller.selectedDownloader.value?.name ?? '未选择',
            ),
          ),
          _buildDownloaderSelector(context),
          const SizedBox(height: 10),
          Obx(
            () => _buildSubsectionLabel(
              context,
              '保存目录',
              controller.selectedDirectory.value.isEmpty
                  ? '自动匹配'
                  : controller.selectedDirectory.value,
            ),
          ),
          _buildDirectorySelector(context),
        ],
      ),
    );
  }

  Widget _buildDownloaderSelector(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingDownloaders) {
        return _buildPlaceholderState(context, label: '正在加载');
      }

      final downloaders = controller.downloaders;
      final selected = controller.selectedDownloader.value;

      if (downloaders.isEmpty) {
        return _buildPlaceholderState(context, label: '暂无可用下载器');
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: downloaders.map((downloader) {
            final stats = controller.statsFor(downloader.name);
            final isSelected = selected?.name == downloader.name;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 188,
                height: 70,
                child: _buildChoiceTile(
                  context,
                  title: downloader.name,
                  subtitle: _downloaderSubtitle(downloader, stats),
                  isSelected: isSelected,
                  accentColor: Theme.of(context).colorScheme.primary,
                  onTap: () => controller.setDownloader(downloader),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildDirectorySelector(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDirectory.value;
      final suggestions = controller.directorySuggestions;
      final entries = <String>['', ...suggestions];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: entries.map((dir) {
            final isAuto = dir.isEmpty;
            final label = isAuto ? '自动匹配' : dir;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: isAuto ? 132 : 220,
                height: 50,
                child: _buildChoiceTile(
                  context,
                  title: label,
                  subtitle: null,
                  isSelected: selected == dir,
                  accentColor: Theme.of(context).colorScheme.secondary,
                  onTap: () => controller.setDirectory(dir),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildTmdbInput(BuildContext context) {
    return Obx(() {
      final expanded = controller.showAdvanced.value;
      final theme = Theme.of(context);
      if (!expanded) {
        return Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            onPressed: () => controller.showAdvanced.value = true,
            child: Text(
              '手动填写 TMDB ID',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: _panelDecoration(context),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TMDB ID',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => controller.showAdvanced.value = false,
                  child: Text(
                    '收起',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: controller.tmdbId.value,
                  selection: TextSelection.collapsed(
                    offset: controller.tmdbId.value.length,
                  ),
                ),
              ),
              onChanged: controller.setTmdbId,
              keyboardType: TextInputType.number,
              placeholder: '输入 TMDB ID',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              clearButtonMode: OverlayVisibilityMode.editing,
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.tertiarySystemGroupedBackground,
                  context,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomActions(BuildContext context) {
    return Obx(() {
      final showSpecial = _appService.enableSpecialDownload.value;
      final enabled = controller.selectedDownloader.value != null;
      final tmdbId = controller.tmdbId.value.isEmpty
          ? null
          : controller.tmdbId.value;

      if (!showSpecial) {
        return _buildPrimaryButton(
          context,
          label: '开始下载',
          busy: controller.isDownloading.value,
          enabled: enabled,
          onTap: () =>
              controller.startDownload(item: item, customTmdbId: tmdbId),
        );
      }

      return Row(
        children: [
          Expanded(
            child: _buildSecondaryButton(
              context,
              label: '直连下载',
              busy: controller.isSpecialDownloading.value,
              enabled: enabled,
              onTap: () =>
                  controller.startSpecialDownload(context: context, item: item),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildPrimaryButton(
              context,
              label: '开始下载',
              busy: controller.isDownloading.value,
              enabled: enabled,
              onTap: () =>
                  controller.startDownload(item: item, customTmdbId: tmdbId),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required String label,
    required bool busy,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 46,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(14),
        color: enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        onPressed: enabled && !busy ? onTap : null,
        child: busy
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required String label,
    required bool busy,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 46,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.secondary.withValues(
          alpha: enabled ? 0.14 : 0.08,
        ),
        onPressed: enabled && !busy ? onTap : null,
        child: busy
            ? CupertinoActivityIndicator(color: theme.colorScheme.secondary)
            : Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          child,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSubsectionLabel(
    BuildContext context,
    String title,
    String selectedValue,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? trailingText,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : CupertinoDynamicColor.resolve(
                    CupertinoColors.tertiarySystemGroupedBackground,
                    context,
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.22)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? accentColor : scheme.outline,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? accentColor : scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null && trailingText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  trailingText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderState(BuildContext context, {required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.tertiarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _downloaderSubtitle(dynamic downloader, DownloaderStats? stats) {
    if (stats != null && stats.freeSpace > 0) {
      return '剩余 ${SizeFormatter.formatSize(stats.freeSpace, 1)}';
    }
    return downloader.type.isNotEmpty ? downloader.type.toUpperCase() : '';
  }

  BoxDecoration _panelDecoration(BuildContext context) {
    return BoxDecoration(
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondarySystemGroupedBackground,
        context,
      ),
      borderRadius: BorderRadius.circular(18),
    );
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

  String _buildTrafficSummary({
    required String volumeFactor,
    required double? downloadFactor,
    required double? uploadFactor,
  }) {
    final parts = <String>[];
    if (volumeFactor.isNotEmpty) {
      parts.add(volumeFactor);
    }
    if (downloadFactor != null && downloadFactor != 1) {
      parts.add(
        downloadFactor == 0 ? '下载免费' : '下载 ${(downloadFactor * 100).round()}%',
      );
    }
    if (uploadFactor != null && uploadFactor != 1) {
      parts.add('上传 ${(uploadFactor * 100).round()}%');
    }
    return parts.join('  /  ');
  }
}
