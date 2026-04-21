import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/modules/download/controllers/download_controller.dart';
import 'package:moviepilot_mobile/modules/download/widgets/download_sheet.dart';
import 'package:moviepilot_mobile/modules/recognize/controllers/recognize_controller.dart';
import 'package:moviepilot_mobile/modules/recognize/pages/recognize_page.dart';
import 'package:moviepilot_mobile/modules/setting/controllers/setting_controller.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_controller.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';

import '../models/search_result_models.dart';

class SearchResultTorrentItem extends StatelessWidget {
  const SearchResultTorrentItem({
    super.key,
    required this.item,
    this.similarItems,
    this.immersive = false,
    this.invertColors = false,
    this.onRecognizeInfoTap,
  });

  final SearchResultItem item;
  final List<SearchResultItem>? similarItems;
  final bool immersive;
  final bool invertColors;
  final Function(SearchResultItem)? onRecognizeInfoTap;

  static final Map<int, Future<List<int>?>> _iconFutures = {};

  bool _isInverted() => immersive || invertColors;

  Color cardColor(BuildContext context) => _isInverted()
      ? Color.alphaBlend(
          Colors.black.withValues(alpha: 0.18),
          AppTheme.darkCardBackgroundColor,
        )
      : Theme.of(context).colorScheme.surface;

  Color themeColor(BuildContext context) =>
      _isInverted() ? CupertinoColors.activeBlue : context.primaryColor;

  Color primaryTextColor(BuildContext context) =>
      _isInverted() ? Colors.white : Theme.of(context).colorScheme.onSurface;

  Color secondaryTextColor(BuildContext context) => _isInverted()
      ? Colors.white.withValues(alpha: 0.72)
      : Theme.of(context).colorScheme.onSurfaceVariant;

  Color _cardBorderColor(BuildContext context) => _isInverted()
      ? Colors.white.withValues(alpha: 0.08)
      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.32);

  Color _cardBottomTint(BuildContext context) => _isInverted()
      ? const Color(0xFF101826)
      : Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.76);

  Color _footerSurface(BuildContext context) => _isInverted()
      ? Colors.white.withValues(alpha: 0.03)
      : Theme.of(
          context,
        ).colorScheme.surfaceContainerLow.withValues(alpha: 0.96);

  @override
  Widget build(BuildContext context) {
    final meta = item.meta_info;
    final torrent = item.torrent_info;
    final accent = themeColor(context);
    final title = _displayTitle(item);
    final season = _seasonLabel(item);
    final tags = _buildTags(item);
    final promotion = _promotionBadgeLabel(item);

    return GestureDetector(
      onTap: () => _openDownloadSheet(context, item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cardBorderColor(context)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor(context), _cardBottomTint(context)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isInverted() ? 0.18 : 0.06,
              ),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (promotion != null)
              Positioned(
                top: 0,
                right: 0,
                child: _buildPromotionBadge(
                  promotion,
                  prominent: true,
                  compact: true,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context,
                    title: title,
                    season: season,
                    promotion: promotion,
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  _buildSiteAndStatsRow(context, torrent),
                  const SizedBox(height: 10),
                  Text(
                    torrent?.title ?? meta?.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor(context).withValues(alpha: 0.92),
                    ),
                  ),
                  if ((meta?.subtitle ?? torrent?.description)?.isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 8),
                    Text(
                      meta?.subtitle ?? torrent?.description ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14.5,
                        height: 1.45,
                        color: secondaryTextColor(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildMetaRow(context, item),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: tags),
                  ],
                  const SizedBox(height: 14),
                  _buildMoreFooter(context, item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String? season,
    required String? promotion,
    required Color accent,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: promotion != null ? 70 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: primaryTextColor(context),
            ),
          ),
          if (season != null) ...[
            const SizedBox(height: 10),
            _buildSeasonChip(season, accent: accent),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreFooter(BuildContext context, SearchResultItem item) {
    final accent = themeColor(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: _footerSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isInverted()
              ? Colors.white.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (onRecognizeInfoTap != null) {
                onRecognizeInfoTap?.call(item);
                return;
              }
              await _showRecognizeSheet(context, item);
            },
            child: _buildFooterAction(
              context,
              icon: CupertinoIcons.sparkles,
              label: '识别',
              color: accent,
            ),
          ),
          if (similarItems != null && similarItems!.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildFooterHint(
              context,
              label: '相似 ${similarItems!.length}',
              icon: CupertinoIcons.square_stack_3d_up,
            ),
          ],
          const Spacer(),
          _buildSizePill(context, item, compact: true),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openInfoSheet(context, item),
            child: _buildFooterIconAction(
              context,
              icon: Icons.info_outline_rounded,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: _isInverted() ? 0.22 : 0.16),
              color.withValues(alpha: _isInverted() ? 0.14 : 0.10),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: _isInverted() ? 0.26 : 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _isInverted() ? 0.10 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterIconAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: _isInverted() ? 0.18 : 0.14),
            color.withValues(alpha: _isInverted() ? 0.10 : 0.08),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: _isInverted() ? 0.26 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: _isInverted() ? 0.10 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildFooterHint(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final color = secondaryTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isInverted()
              ? [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.04),
                ]
              : [
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.78),
                ],
        ),
        border: Border.all(
          color: _isInverted()
              ? Colors.white.withValues(alpha: 0.06)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteAndStatsRow(
    BuildContext context,
    SearchTorrentInfo? torrent,
  ) {
    final seeders = torrent?.seeders ?? 0;
    final peers = torrent?.peers ?? 0;

    return Row(
      children: [
        Flexible(fit: FlexFit.loose, child: _buildSiteIndicator(context)),
        if (seeders > 0 || peers > 0) const SizedBox(width: 12),
        if (seeders > 0 || peers > 0) const Spacer(),
        if (seeders > 0)
          _buildStatPill(
            context,
            icon: Icons.arrow_upward_rounded,
            label: '$seeders',
            color: const Color(0xFF84CC16),
            prominent: true,
          ),
        if (seeders > 0 && peers > 0) const SizedBox(width: 8),
        if (peers > 0)
          _buildStatPill(
            context,
            icon: Icons.arrow_downward_rounded,
            label: '$peers',
            color: const Color(0xFFFB7185),
          ),
      ],
    );
  }

  Future<void> _showRecognizeSheet(
    BuildContext context,
    SearchResultItem item,
  ) async {
    final initialTitle = item.torrent_info?.title?.trim().isNotEmpty == true
        ? item.torrent_info?.title?.trim()
        : item.meta_info?.title?.trim();
    final initialSubtitle = item.meta_info?.subtitle?.trim().isNotEmpty == true
        ? item.meta_info?.subtitle?.trim()
        : item.torrent_info?.description?.trim();

    if (Get.isRegistered<RecognizeController>()) {
      Get.delete<RecognizeController>();
    }
    Get.put(
      RecognizeController(
        initialTitle: initialTitle,
        initialSubtitle: initialSubtitle,
      ),
    );
    await showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (_) => const RecognizePage(),
    );
    if (Get.isRegistered<RecognizeController>()) {
      Get.delete<RecognizeController>();
    }
  }

  Widget _buildSiteIndicator(BuildContext context) {
    final siteName = _siteName(item);
    final siteId = item.torrent_info?.site;
    final theme = Theme.of(context);
    final controller = Get.isRegistered<SiteController>()
        ? Get.find<SiteController>()
        : Get.put(SiteController());

    return Obx(() {
      SiteItem? siteItem;
      if (siteId != null) {
        for (final value in controller.items) {
          if (value.site.id == siteId) {
            siteItem = value;
            break;
          }
        }
      }

      final icon = _buildSiteIcon(context, controller, siteItem);
      return Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isInverted()
              ? Colors.white.withValues(alpha: 0.06)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.72,
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isInverted()
                ? Colors.white.withValues(alpha: 0.06)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                siteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor(context),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSiteIcon(
    BuildContext context,
    SiteController controller,
    SiteItem? siteItem,
  ) {
    final bytes = siteItem?.iconBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return _imageFromBytes(bytes);
    }
    if (siteItem != null) {
      final future = _iconFutures.putIfAbsent(
        siteItem.site.id,
        () => controller.loadIcon(siteItem.site),
      );
      return FutureBuilder<List<int>?>(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data != null && data.isNotEmpty) {
            return _imageFromBytes(data);
          }
          return _placeholderIcon(context);
        },
      );
    }
    return _placeholderIcon(context);
  }

  Widget _imageFromBytes(List<int> bytes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.memory(
        Uint8List.fromList(bytes),
        width: 20,
        height: 20,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        Icons.public,
        size: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSeasonChip(
    String text, {
    required Color accent,
    bool dense = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _isInverted() ? 0.26 : 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: _isInverted() ? 0.26 : 0.12),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 11 : 12.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, SearchResultItem item) {
    final timeLabel = _timeLabel(item);
    final grabs = item.torrent_info?.grabs ?? 0;
    final freeLabel = _freeDeadlineLabel(item);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildMetaPill(
          context,
          icon: CupertinoIcons.clock,
          label: timeLabel,
          color: const Color(0xFF94A3B8),
        ),
        if (grabs > 0)
          _buildMetaPill(
            context,
            icon: CupertinoIcons.arrow_down_circle,
            label: '$grabs 次下载',
            color: const Color(0xFF22C55E),
          ),
        if (freeLabel != null)
          _buildMetaPill(
            context,
            icon: CupertinoIcons.gift,
            label: freeLabel,
            color: const Color(0xFFF59E0B),
          ),
      ],
    );
  }

  Widget _buildMetaPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isInverted()
            ? color.withValues(alpha: 0.14)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: _isInverted() ? 0.20 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool prominent = false,
  }) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    if (prominent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: textStyle?.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isInverted() ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: textStyle?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizePill(
    BuildContext context,
    SearchResultItem item, {
    bool dense = false,
    bool compact = false,
  }) {
    final accent = themeColor(context);
    final size = item.torrent_info?.size;
    final label = size == null ? '--' : SizeFormatter.formatSize(size, 2);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : (dense ? 10 : 14),
        vertical: compact ? 7 : (dense ? 5 : 8),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: _isInverted() ? 0.82 : 0.74),
            accent.withValues(alpha: _isInverted() ? 0.64 : 0.58),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: _isInverted() ? 0.12 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12 : (dense ? 11.5 : 13),
        ),
      ),
    );
  }

  List<Widget> _buildTags(SearchResultItem item, {int? maxCount}) {
    final meta = item.meta_info;
    final torrent = item.torrent_info;
    final tags = <String>[
      if ((meta?.web_source ?? '').isNotEmpty) meta!.web_source!,
      if ((meta?.resource_type ?? '').isNotEmpty) meta!.resource_type!,
      if ((meta?.resource_pix ?? '').isNotEmpty) meta!.resource_pix!,
      if ((meta?.video_encode ?? '').isNotEmpty) meta!.video_encode!,
      if ((meta?.audio_encode ?? '').isNotEmpty) meta!.audio_encode!,
      if ((meta?.resource_effect ?? '').isNotEmpty) meta!.resource_effect!,
      if ((meta?.edition ?? '').isNotEmpty) meta!.edition!,
      if ((meta?.resource_team ?? '').isNotEmpty) meta!.resource_team!,
      ...?torrent?.labels,
    ];

    final unique = <String>{};
    final result = <Widget>[];
    for (final tag in tags) {
      final cleaned = tag.trim();
      if (cleaned.isEmpty || unique.contains(cleaned)) continue;
      unique.add(cleaned);
      result.add(_buildTagChip(cleaned));
      if (maxCount != null && result.length >= maxCount) break;
    }
    return result;
  }

  Widget _buildTagChip(String text) {
    final style = _tagStyle(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: style.background.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: style.foreground,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPromotionBadge(
    String text, {
    bool dense = false,
    bool prominent = false,
    bool compact = false,
  }) {
    final color = _promotionColor(text);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? (compact ? 12 : 16) : (dense ? 8 : 10),
        vertical: prominent ? (compact ? 8 : 10) : (dense ? 4 : 6),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(prominent ? (compact ? 13 : 16) : 12),
          bottomRight: Radius.circular(prominent ? 0 : 12),
          topLeft: Radius.circular(prominent ? 0 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: compact ? 8 : 12,
            offset: Offset(0, compact ? 4 : 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: prominent ? (compact ? 12 : 13.5) : (dense ? 11 : 12),
        ),
      ),
    );
  }

  _ChipStyle _tagStyle(String text) {
    final normalized = text.toLowerCase();
    if (normalized.contains('apple tv')) {
      return const _ChipStyle(
        background: Color(0xFF7C3AED),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('web-dl') || normalized.contains('webrip')) {
      return const _ChipStyle(
        background: Color(0xFFFF5B3A),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('2160') || normalized == '4k') {
      return const _ChipStyle(
        background: Color(0xFF6D5EF8),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('h265') ||
        normalized.contains('x265') ||
        normalized.contains('10bit')) {
      return const _ChipStyle(
        background: Color(0xFFF59E0B),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('hdr') || normalized.contains('dolby')) {
      return const _ChipStyle(
        background: Color(0xFF8B2BBF),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('atmos') ||
        normalized.contains('ddp') ||
        normalized.contains('dts')) {
      return const _ChipStyle(
        background: Color(0xFFEF4444),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('中字') ||
        normalized.contains('字幕') ||
        normalized.contains('简') ||
        normalized.contains('繁')) {
      return const _ChipStyle(
        background: Color(0xFF6274D8),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('cmctv') ||
        normalized.contains('mteam') ||
        normalized.contains('team') ||
        normalized.contains('aru')) {
      return const _ChipStyle(
        background: Color(0xFF0F9B8E),
        foreground: Colors.white,
      );
    }

    final palette = [
      const _ChipStyle(background: Color(0xFF7C3AED), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFF2563EB), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFF059669), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFFF97316), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFFDB2777), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFF0EA5E9), foreground: Colors.white),
    ];
    final index = text.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[index % palette.length];
  }

  String? _promotionBadgeLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    if (torrent == null) return null;

    final downloadFactor = torrent.downloadvolumefactor;
    if (downloadFactor != null) {
      if (downloadFactor == 0) return '免费';
      if (downloadFactor > 0 && downloadFactor < 1) {
        return '${(downloadFactor * 100).round()}%';
      }
    }

    final volume = torrent.volume_factor ?? '';
    if (volume.contains('%')) return volume;
    if (volume.contains('免费')) return '免费';
    return null;
  }

  Color _promotionColor(String text) {
    if (text.contains('免费')) return const Color(0xFF94C83D);
    return const Color(0xFFFF6B2C);
  }

  String? _freeDeadlineLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    final freeDiff = torrent?.freedate_diff?.trim();
    if (freeDiff != null && freeDiff.isNotEmpty) {
      return '限免 $freeDiff';
    }
    final freeDate = torrent?.freedate?.trim();
    if (freeDate != null && freeDate.isNotEmpty) {
      return '限免中';
    }
    if ((torrent?.downloadvolumefactor ?? 1) == 0) {
      return '免费';
    }
    return null;
  }

  String _displayTitle(SearchResultItem item) {
    final mediaTitle = item.media_info?.title?.trim().isNotEmpty == true
        ? item.media_info!.title!.trim()
        : null;
    if (mediaTitle != null) return mediaTitle;

    final meta = item.meta_info;
    return meta?.name?.trim().isNotEmpty == true
        ? meta!.name!.trim()
        : meta?.cn_name?.trim().isNotEmpty == true
        ? meta!.cn_name!.trim()
        : meta?.en_name?.trim().isNotEmpty == true
        ? meta!.en_name!.trim()
        : meta?.title?.trim().isNotEmpty == true
        ? meta!.title!.trim()
        : item.torrent_info?.title ?? '未知标题';
  }

  String? _seasonLabel(SearchResultItem item) {
    final season = item.meta_info?.season_episode?.trim();
    if (season != null && season.isNotEmpty) return season;

    final value = item.meta_info?.begin_season ?? item.meta_info?.total_season;
    if (value != null && value > 0) {
      return 'S${value.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String _siteName(SearchResultItem item) {
    return item.torrent_info?.site_name ?? '未知站点';
  }

  String _timeLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    final elapsed = torrent?.date_elapsed?.replaceAll('\n', ' ').trim();
    if (elapsed != null && elapsed.isNotEmpty) {
      return elapsed;
    }

    final raw = torrent?.pubdate;
    if (raw == null || raw.isEmpty) return '未知时间';

    final parsed = _parseDate(raw);
    if (parsed == null) return raw;

    final diff = DateTime.now().difference(parsed);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}年前';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}个月前';
    if (diff.inDays >= 1) return '${diff.inDays}天前';
    if (diff.inHours >= 1) return '${diff.inHours}小时前';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }

  DateTime? _parseDate(String raw) {
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    try {
      return format.parseUtc(raw).toLocal();
    } catch (_) {
      try {
        return format.parse(raw);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _openInfoSheet(
    BuildContext context,
    SearchResultItem item,
  ) async {
    WebUtil.open(url: item.torrent_info?.page_url);
  }

  void _openDownloadSheet(BuildContext context, SearchResultItem item) {
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController());
    }
    final downloadController = Get.isRegistered<DownloadController>()
        ? Get.find<DownloadController>()
        : Get.put(DownloadController());
    downloadController.resetSheetTransientState();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadSheet(item: item),
    );
  }
}

class _ChipStyle {
  const _ChipStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
