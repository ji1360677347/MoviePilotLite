import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/theme/section.dart';

enum PluginHandleType {
  settings,
  // repeat,
  reset,
  uninstall,
  log,
  web,
}

/// 插件卡片，两段式布局：深色渐变区 + 浅色信息区，主题色由 PluginPaletteCache 缓存
class PluginItemCard extends StatelessWidget {
  const PluginItemCard({
    super.key,
    required this.item,
    required this.iconUrl,
    required this.installCount,
    this.onHandleTap,
  });

  final PluginItem item;
  final String iconUrl;
  final int installCount;
  final Function(PluginHandleType type)? onHandleTap;

  static const double _cardRadius = 16;
  static const double _iconSize = 52;

  @override
  Widget build(BuildContext context) {
    final themeColor = _resolveThemeColor();
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Section(
          padding: const EdgeInsets.all(0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDarkSection(context, themeColor),
                _buildLightSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 仅读缓存，不订阅 Rx，避免任一 palette 更新导致所有卡片重建引发卡顿
  Color _resolveThemeColor() {
    try {
      final cache = Get.find<PluginPaletteCache>();
      return cache.getCached(iconUrl) ?? PluginPaletteCache.defaultColor;
    } catch (_) {
      return PluginPaletteCache.defaultColor;
    }
  }

  Widget _buildDarkSection(BuildContext context, Color themeColor) {
    return SizedBox(
      height: 108,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.92),
              themeColor.withValues(alpha: 0.72),
              themeColor.withValues(alpha: 0.88),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: item.state ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.pluginName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (item.pluginVersion != null &&
                          item.pluginVersion!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          'v${item.pluginVersion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.pluginDesc != null &&
                      item.pluginDesc!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.pluginDesc!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_labelList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _labelList
                          .map(
                            (l) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildIcon(themeColor),
          ],
        ),
      ),
    );
  }

  List<String> get _labelList {
    final raw = item.pluginLabel;
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Widget _buildLightSection(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: outline.withValues(alpha: 0.08)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.pluginAuthor ?? '-',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.download_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            _formatInstallCount(installCount),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          if (onHandleTap != null) ...[
            const SizedBox(width: 8),
            PopupMenuButton(
              padding: EdgeInsets.zero,
              onSelected: onHandleTap,
              itemBuilder: (context) {
                return PluginHandleType.values
                    .map(
                      (type) => PopupMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getHandleTypeIcon(type),
                              size: 16,
                              color: _getHandleTypeColor(context, type),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getHandleTypeLabel(type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getHandleTypeColor(context, type),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList();
              },
              child: Icon(
                Icons.more_vert,
                size: 20,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatInstallCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  Widget _buildIcon(Color fallbackColor) {
    if (iconUrl.isEmpty) {
      return Container(
        width: _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          color: fallbackColor.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(Icons.extension_outlined, size: 24, color: Colors.white),
      );
    }
    return Container(
      width: _iconSize,
      height: _iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: iconUrl,
          width: _iconSize,
          height: _iconSize,
          fit: BoxFit.cover,
          memCacheWidth: 96,
          memCacheHeight: 96,
          placeholder: (_, __) => Container(
            color: fallbackColor.withValues(alpha: 0.5),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: fallbackColor.withValues(alpha: 0.5),
            child: Icon(Icons.extension_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }

  String _getHandleTypeLabel(PluginHandleType type) {
    switch (type) {
      case PluginHandleType.settings:
        return '设置';
      case PluginHandleType.log:
        return '日志';
      case PluginHandleType.reset:
        return '重置';
      case PluginHandleType.uninstall:
        return '卸载';
      case PluginHandleType.web:
        return '查看作者主页';
    }
  }

  IconData _getHandleTypeIcon(PluginHandleType type) {
    switch (type) {
      case PluginHandleType.settings:
        return Icons.settings;
      case PluginHandleType.log:
        return Icons.event_note;
      case PluginHandleType.reset:
        return Icons.refresh;
      case PluginHandleType.uninstall:
        return Icons.delete;
      case PluginHandleType.web:
        return Icons.web;
    }
  }

  Color _getHandleTypeColor(BuildContext context, PluginHandleType type) {
    switch (type) {
      case PluginHandleType.settings:
        return Theme.of(context).colorScheme.primary;
      case PluginHandleType.log:
        return Theme.of(context).colorScheme.onSurface;
      case PluginHandleType.reset:
        return Theme.of(context).colorScheme.secondary;
      case PluginHandleType.uninstall:
        return Theme.of(context).colorScheme.error;
      case PluginHandleType.web:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
