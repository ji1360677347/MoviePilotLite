import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/subtitle_manual_upload_form_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';
import 'package:url_launcher/url_launcher.dart';

void registerSubtitleManualUploadRenderer() {
  PluginFormAdapterRegistry.registerRenderer('SubtitleManualUpload', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    final adapter = controller.pluginAdapter;
    if (adapter is! SubtitleManualUploadFormController) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: blocks.map((block) => buildBlock(context, block)).toList(),
      );
    }
    return SubtitleManualUploadRenderer(
      controller: adapter,
      formMode: formMode,
    );
  });
}

class SubtitleManualUploadRenderer extends StatelessWidget {
  const SubtitleManualUploadRenderer({
    super.key,
    required this.controller,
    required this.formMode,
  });

  final SubtitleManualUploadFormController controller;
  final bool formMode;

  @override
  Widget build(BuildContext context) {
    return formMode
        ? _SubtitleConfigView(controller: controller)
        : _SubtitlePageView(controller: controller);
  }
}

class _SubtitlePageView extends StatelessWidget {
  const _SubtitlePageView({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _FeedbackBanner(controller: controller),
          _HomeHeader(controller: controller),
          const SizedBox(height: 12),
          _StatusSection(controller: controller),
          const SizedBox(height: 12),
          _QuickActions(controller: controller),
          const SizedBox(height: 12),
          _SearchPanel(controller: controller),
          const SizedBox(height: 12),
          _MediaResults(controller: controller),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.status.value['enabled'] == true;
      final colors = Theme.of(context).colorScheme;
      return _Panel(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.subtitles_outlined, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '字幕匹配',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '选择资源，匹配字幕，确认后写入媒体目录',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _StatusDot(label: enabled ? '运行中' : '未启用', active: enabled),
          ],
        ),
      );
    });
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.history,
            label: '匹配历史',
            onTap: () {
              _push(
                context,
                '匹配历史',
                (_) => _HistoryPanelLoader(controller: controller),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: Icons.queue,
            label: '自动队列',
            onTap: () {
              _push(
                context,
                '自动入库队列',
                (_) => _AutoQueuePanelLoader(controller: controller),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final error = controller.errorText.value;
      final message = controller.messageText.value;
      if (error == null && message == null) return const SizedBox.shrink();
      final isError = error != null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _Panel(
          color: isError
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            isError ? error : message!,
            style: TextStyle(
              color: isError
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    });
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.status.value;
      final busy = controller.busy.value;
      final index =
          SubtitleManualUploadFormController.asMap(status['index']) ?? {};
      final archive =
          SubtitleManualUploadFormController.asMap(status['archive_support']) ??
          {};
      final timeline =
          SubtitleManualUploadFormController.asMap(status['timeline_fixer']) ??
          {};
      final ai =
          SubtitleManualUploadFormController.asMap(status['ai_subtitle']) ?? {};
      return Section(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        header: SectionHeader(
          title: '运行概览',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '刷新状态',
                onPressed: controller.load,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: '自动入库队列',
                onPressed: () {
                  _push(
                    context,
                    '自动入库队列',
                    (_) => _AutoQueuePanelLoader(controller: controller),
                  );
                },
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.queue),
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  icon: Icons.power_settings_new,
                  label: status['enabled'] == true ? '插件已启用' : '插件未启用',
                  color: status['enabled'] == true ? Colors.green : Colors.grey,
                ),
                _StatusPill(
                  icon: Icons.video_library_outlined,
                  label:
                      '${index['media_count'] ?? 0} 媒体 · ${index['entry_count'] ?? 0} 视频',
                  color: index['ready'] == true ? Colors.blue : Colors.orange,
                ),
                _StatusPill(
                  icon: Icons.inventory_2_outlined,
                  label: archive['rar'] == true ? 'RAR 可用' : 'RAR 不可用',
                  color: archive['rar'] == true ? Colors.green : Colors.orange,
                ),
                _StatusPill(
                  icon: Icons.graphic_eq,
                  label: timeline['available'] == true ? '智能调轴可用' : '调轴不可用',
                  color: timeline['available'] == true
                      ? Colors.green
                      : Colors.grey,
                ),
                _StatusPill(
                  icon: Icons.auto_awesome,
                  label: ai['available'] == true ? 'AI 可用' : 'AI 未就绪',
                  color: ai['available'] == true ? Colors.purple : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : controller.refreshIndex,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('刷新资源清单'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mediaType = controller.mediaType.value;
      return Section(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        header: const SectionHeader(title: '搜索资源', subtitle: '本地媒体库'),
        child: Column(
          children: [
            TextField(
              decoration: _fieldDecoration(
                context,
                label: '搜索本地资源',
                icon: Icons.search,
              ),
              onChanged: (value) => controller.searchKeyword.value = value,
              onSubmitted: (_) => controller.runSearch(reset: true),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: mediaType,
                    decoration: _fieldDecoration(context, label: '类型'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('全部')),
                      DropdownMenuItem(value: 'movie', child: Text('电影')),
                      DropdownMenuItem(value: 'tv', child: Text('剧集')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      controller.mediaType.value = value;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => controller.runSearch(reset: true),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('搜索'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _MediaResults extends StatelessWidget {
  const _MediaResults({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final medias = controller.medias;
      final hasMore = controller.mediaHasMore.value;
      final total = controller.mediaTotal.value;
      if (medias.isEmpty) {
        return const _EmptyPanel(text: '暂无资源，刷新清单或输入关键词试试');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: '本地资源', trailing: '$total 个结果'),
          const SizedBox(height: 8),
          for (final media in medias)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ListCard(
                onTap: () {
                  _push(
                    context,
                    controller.mediaLabel(media),
                    (_) => _TargetDetailLoader(
                      controller: controller,
                      media: media,
                    ),
                  ).then((_) => controller.resetSelection());
                },
                child: ListTile(
                  minVerticalPadding: 12,
                  leading: _Poster(url: _mediaPoster(media)),
                  title: Text(
                    controller.mediaLabel(media),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(_mediaSubtitle(media)),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          if (hasMore)
            OutlinedButton.icon(
              onPressed: controller.loadMoreMedia,
              icon: const Icon(Icons.expand_more),
              label: Text('加载更多 · 共 $total'),
            ),
        ],
      );
    });
  }
}

class _TargetDetail extends StatelessWidget {
  const _TargetDetail({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final media = controller.selectedMedia.value;
      final targetCount = controller.targets.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FeedbackBanner(controller: controller),
          _TargetSummaryPanel(controller: controller, media: media),
          const SizedBox(height: 12),
          _SectionHeader(
            title: '视频目标',
            trailing: targetCount == 0 ? null : '$targetCount 个',
          ),
          const SizedBox(height: 12),
          if (controller.busy.value && controller.targets.isEmpty)
            const _LoadingPanel(text: '正在读取本地视频目标')
          else if (controller.targets.isEmpty)
            const _EmptyPanel(text: '没有可写入目标')
          else
            for (final target in controller.targets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TargetCard(controller: controller, target: target),
              ),
        ],
      );
    });
  }
}

class _TargetSummaryPanel extends StatelessWidget {
  const _TargetSummaryPanel({required this.controller, required this.media});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic>? media;

  @override
  Widget build(BuildContext context) {
    final selectedCount = controller.selectedTargetIds.length;
    final targetCount = controller.targets.length;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.mediaLabel(media),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCount == 0
                          ? '$targetCount 个视频目标'
                          : '已选择 $selectedCount / $targetCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusDot(
                label: selectedCount == 0 ? '未选择' : '已选择',
                active: selectedCount > 0,
              ),
            ],
          ),
          if (controller.seasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SeasonPill(
                    label: '全部',
                    selected: controller.selectedSeason.value == 'all',
                    onTap: () => controller.changeSeason('all'),
                  ),
                  for (final season in controller.seasons)
                    _SeasonPill(
                      label: _seasonLabel(season),
                      selected:
                          controller.selectedSeason.value ==
                          '${season['value'] ?? season['season']}',
                      onTap: () => controller.changeSeason(
                        '${season['value'] ?? season['season']}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ActionPill(
                  icon: Icons.upload_file,
                  label: '上传',
                  primary: true,
                  onTap: () {
                    controller.openBatchUpload();
                    _push(
                      context,
                      controller.uploadTitle.value,
                      (_) => _UploadPanel(controller: controller),
                    );
                  },
                ),
                _ActionPill(
                  icon: Icons.travel_explore,
                  label: '在线',
                  onTap: () {
                    _push(
                      context,
                      '在线字幕',
                      (_) => _OnlinePanelLoader(
                        controller: controller,
                        start: controller.openBatchOnlineSearch,
                      ),
                    );
                  },
                ),
                _ActionPill(
                  icon: Icons.auto_awesome,
                  label: 'AI',
                  confirm: true,
                  onTap: controller.aiAvailable
                      ? () => controller.submitAiForTargets()
                      : null,
                ),
                _ActionPill(
                  icon: Icons.graphic_eq,
                  label: '调轴',
                  confirm: true,
                  onTap: controller.timelineAvailable
                      ? () => controller.fixTimelineForTargets()
                      : null,
                ),
                _ActionPill(
                  icon: Icons.delete_sweep_outlined,
                  label: '清空',
                  confirm: true,
                  destructive: true,
                  onTap: controller.clearSelectedSubtitles,
                ),
                _ActionPill(
                  icon: Icons.cancel_outlined,
                  label: '取消 AI',
                  confirm: true,
                  onTap: controller.cancelAiForTargets,
                ),
                _ActionPill(
                  icon: Icons.select_all,
                  label: '全选',
                  onTap: controller.toggleSelectAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetDetailLoader extends StatefulWidget {
  const _TargetDetailLoader({required this.controller, required this.media});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> media;

  @override
  State<_TargetDetailLoader> createState() => _TargetDetailLoaderState();
}

class _TargetDetailLoaderState extends State<_TargetDetailLoader> {
  @override
  void initState() {
    super.initState();
    widget.controller.selectedMedia.value = widget.media;
    widget.controller.clearTargetState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.loadTargets(media: widget.media, season: 'all');
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TargetDetail(controller: widget.controller);
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.controller, required this.target});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> target;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = '${target['id'] ?? ''}';
      final selected = controller.selectedTargetIds.contains(id);
      final expanded = controller.expandedTargetIds.contains(id);
      final disabled = controller.isTargetActionDisabled(target);
      final subtitles = SubtitleManualUploadFormController.asMapList(
        target['subtitles'],
      );
      final colors = Theme.of(context).colorScheme;
      final theme = Theme.of(context);
      final path = _targetPath(target);
      final sizeText = '${target['size_text'] ?? ''}'.trim();
      final pathLine = [
        if (path.isNotEmpty) path,
        if (sizeText.isNotEmpty) sizeText,
      ].join(' · ');

      return _ListCard(
        selected: selected,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => controller.toggleExpandedTarget(id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 2, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TargetSelectMark(
                          selected: selected,
                          onTap: () =>
                              controller.toggleTarget(id, !selected),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      controller.compactTargetName(target),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  if (subtitles.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${subtitles.length}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  Icon(
                                    expanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              if (pathLine.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  pathLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                              if (target['writable'] == false) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '不可写',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Row(
                  children: [
                    Expanded(
                      child: _TargetCardAction(
                        icon: Icons.upload_file,
                        label: '上传',
                        primary: true,
                        onTap: disabled
                            ? null
                            : () {
                                controller.openSingleUpload(target);
                                _push(
                                  context,
                                  controller.uploadTitle.value,
                                  (_) => _UploadPanel(controller: controller),
                                );
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TargetCardAction(
                        icon: Icons.travel_explore,
                        label: '在线',
                        onTap: disabled
                            ? null
                            : () {
                                _push(
                                  context,
                                  '在线字幕',
                                  (_) => _OnlinePanelLoader(
                                    controller: controller,
                                    start: () => controller
                                        .openSingleOnlineSearch(target),
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
              if (expanded || subtitles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.outline.withValues(alpha: 0.2)),
                if (subtitles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                    child: Text(
                      '暂无外挂字幕',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final subtitle in subtitles)
                    _SubtitleRow(
                      controller: controller,
                      target: target,
                      subtitle: subtitle,
                    ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _TargetSelectMark extends StatelessWidget {
  const _TargetSelectMark({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 18,
        height: 18,
        child: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: selected ? colors.primary : colors.outline,
        ),
      ),
    );
  }
}

class _TargetCardAction extends StatelessWidget {
  const _TargetCardAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final compactStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStatePropertyAll(shape),
    );

    if (primary) {
      return FilledButton.icon(
        style: compactStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.surfaceContainerHighest.withValues(alpha: 0.7);
            }
            return colors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.onSurface.withValues(alpha: 0.38);
            }
            return colors.onPrimary;
          }),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      style: compactStyle.copyWith(
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: colors.outline.withValues(alpha: 0.25),
            );
          }
          return BorderSide(color: colors.outline.withValues(alpha: 0.55));
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(alpha: 0.38);
          }
          return colors.primary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.surfaceContainerHighest.withValues(alpha: 0.35);
          }
          return colors.surface.withValues(alpha: 0.72);
        }),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.matchHistoryItems.isEmpty) {
        return const _EmptyPanel(text: '暂无匹配历史');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '已有外挂字幕',
            trailing: '${controller.matchHistoryTotal.value} 条',
          ),
          const SizedBox(height: 8),
          for (final item in controller.matchHistoryItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryCard(controller: controller, item: item),
            ),
          if (controller.matchHistoryHasMore.value)
            OutlinedButton.icon(
              onPressed: controller.loadMoreMatchHistory,
              icon: const Icon(Icons.expand_more),
              label: Text('加载更多 · 共 ${controller.matchHistoryTotal.value}'),
            ),
        ],
      );
    });
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.controller, required this.item});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = '${item['id'] ?? item['title'] ?? ''}';
      final expanded = controller.expandedHistoryIds.contains(id);
      final targets = SubtitleManualUploadFormController.asMapList(
        item['targets'],
      );
      return _ListCard(
        child: Column(
          children: [
            ListTile(
              leading: _Poster(url: _mediaPoster(item)),
              title: Text(
                controller.mediaLabel(item),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('${targets.length} 个目标有外挂字幕'),
              trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => controller.toggleHistoryExpanded(id),
            ),
            if (expanded) const Divider(height: 1),
            if (expanded)
              for (final target in targets)
                ListTile(
                  dense: true,
                  title: Text(
                    controller.compactTargetName(target),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${SubtitleManualUploadFormController.asMapList(target['subtitles']).length} 个字幕',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: '在线搜索',
                        onPressed: () {
                          _push(
                            context,
                            '在线字幕',
                            (_) => _OnlinePanelLoader(
                              controller: controller,
                              start: () =>
                                  controller.openSingleOnlineSearch(target),
                            ),
                          );
                        },
                        icon: const Icon(Icons.travel_explore),
                      ),
                      IconButton(
                        tooltip: '调轴',
                        onPressed: controller.timelineAvailable
                            ? () => _confirmAction(
                                context,
                                title: '历史字幕调轴',
                                onConfirm: () =>
                                    controller.fixExistingTimeline([
                                      {'target_id': target['id']},
                                    ], '历史字幕'),
                              )
                            : null,
                        icon: const Icon(Icons.graphic_eq),
                      ),
                      IconButton(
                        tooltip: '删除外挂字幕',
                        onPressed: () => _confirmAction(
                          context,
                          title: '删除外挂字幕',
                          message: '此操作会删除该目标的外挂字幕，是否继续？',
                          destructive: true,
                          onConfirm: () =>
                              controller.clearHistoryTarget(target),
                        ),
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      );
    });
  }
}

class _HistoryPanelLoader extends StatefulWidget {
  const _HistoryPanelLoader({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  State<_HistoryPanelLoader> createState() => _HistoryPanelLoaderState();
}

class _HistoryPanelLoaderState extends State<_HistoryPanelLoader> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.loadMatchHistory(reset: true);
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && widget.controller.matchHistoryItems.isEmpty) {
      return const _LoadingPanel(text: '正在读取匹配历史');
    }
    return _HistoryPanel(controller: widget.controller);
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.uploadPreview.value;
      final items = preview == null
          ? <Map<String, dynamic>>[]
          : SubtitleManualUploadFormController.asMapList(preview['items']);
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(
              title: controller.uploadTitle.value,
              icon: Icons.upload_file,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: controller.preparing.value
                      ? null
                      : controller.pickUploadFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('选择字幕/压缩包'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.pickedFiles.isEmpty
                      ? null
                      : controller.prepareUpload,
                  icon: const Icon(Icons.preview),
                  label: const Text('重新预览'),
                ),
              ],
            ),
            if (controller.pickedFiles.isEmpty && items.isEmpty) ...[
              const SizedBox(height: 12),
              const _InlineHint(
                icon: Icons.attach_file,
                text: '选择字幕文件或压缩包后，会先生成可确认的写入预览。',
              ),
            ],
            if (controller.pickedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final file in controller.pickedFiles)
                _PickedFileRow(
                  file: file,
                  onRemove: () => controller.removePickedFile(file),
                ),
            ],
            if (items.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: _fieldDecoration(
                        context,
                        label: '批量语言后缀',
                        dense: true,
                      ),
                      onChanged: (value) =>
                          controller.batchLanguageSuffix.value = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: controller.applyBatchLanguageSuffix,
                    child: const Text('应用'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.fixTimeline.value,
                onChanged: controller.timelineAvailable
                    ? (value) => controller.fixTimeline.value = value
                    : null,
                title: const Text('写入后智能调轴'),
                subtitle: Text(
                  controller.timelineAvailable ? '流媒体目标会自动跳过' : '调轴依赖不可用',
                ),
              ),
              for (final item in items)
                _PreviewItem(controller: controller, item: item),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.applying.value
                      ? null
                      : () async {
                          await controller.applyUpload();
                          if (!context.mounted ||
                              controller.uploadPreview.value != null) {
                            return;
                          }
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                  icon: controller.applying.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.done),
                  label: const Text('确认写入'),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({required this.controller, required this.item});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final uploadId = '${item['upload_id'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _ListCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: item['selected'] != false,
                onChanged: (value) =>
                    controller.togglePreviewItem(uploadId, value == true),
                title: Text(
                  '${item['source_name'] ?? '字幕文件'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('${item['output_name'] ?? ''}'),
              ),
              DropdownButtonFormField<String>(
                initialValue: '${item['target_id'] ?? ''}'.isEmpty
                    ? null
                    : '${item['target_id']}',
                decoration: _fieldDecoration(
                  context,
                  label: '目标视频',
                  dense: true,
                ),
                items: controller.uploadScopeTargets
                    .map(
                      (target) => DropdownMenuItem(
                        value: '${target['id']}',
                        child: Text(controller.compactTargetName(target)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updatePreviewTarget(uploadId, value);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: '${item['language_suffix'] ?? ''}',
                decoration: _fieldDecoration(
                  context,
                  label: '语言后缀',
                  dense: true,
                ),
                onChanged: (value) =>
                    controller.updatePreviewLanguage(uploadId, value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlinePanel extends StatelessWidget {
  const _OnlinePanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final results = controller.filteredOnlineResults;
      final selectedCount = controller.onlineSelectedResultKeys.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelTitle(
                  title: controller.onlineTitle.value,
                  icon: Icons.travel_explore,
                ),
                TextField(
                  decoration: _fieldDecoration(
                    context,
                    label: '关键词',
                    icon: Icons.search,
                  ),
                  onChanged: (value) => controller.onlineKeyword.value = value,
                  onSubmitted: (_) => controller.runOnlineSearch(),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final provider in const [
                        'subhd',
                        'zimuku',
                        'assrt',
                        'opensubtitles',
                      ])
                        _ProviderChip(
                          label: _providerName(provider),
                          selected: controller.onlineSelectedProviders.contains(
                            provider,
                          ),
                          onTap: () {
                            if (controller.onlineSelectedProviders.contains(
                              provider,
                            )) {
                              controller.onlineSelectedProviders.remove(
                                provider,
                              );
                            } else {
                              controller.onlineSelectedProviders.add(provider);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ActionPill(
                        icon: Icons.search,
                        label: '搜索',
                        primary: true,
                        onTap: controller.onlineSearching.value
                            ? null
                            : controller.runOnlineSearch,
                      ),
                      _ActionPill(
                        icon: Icons.download,
                        label: selectedCount == 0
                            ? '下载预览'
                            : '预览 $selectedCount',
                        onTap: () async {
                          await controller.downloadOnlinePreview();
                          if (!context.mounted ||
                              controller.uploadPreview.value == null) {
                            return;
                          }
                          _push(
                            context,
                            controller.uploadTitle.value,
                            (_) => _UploadPanel(controller: controller),
                          );
                        },
                      ),
                      _ActionPill(
                        icon: Icons.auto_awesome,
                        label: 'AI 翻译',
                        confirm: true,
                        onTap: controller.aiAvailable
                            ? () => controller.downloadOnlinePreview(
                                submitAi: true,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (controller.onlineManualLinks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Panel(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final link in controller.onlineManualLinks)
                    _ManualLinkChip(
                      label: Text(
                        '${link['title'] ?? link['provider'] ?? '手动搜索'}',
                      ),
                      onTap: () => _launch('${link['url'] ?? ''}'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SectionHeader(
            title: '搜索结果',
            trailing: controller.onlineSearching.value
                ? '搜索中'
                : '${results.length} 条',
          ),
          const SizedBox(height: 8),
          if (controller.onlineSearching.value)
            const _LoadingPanel(text: '正在搜索在线字幕')
          else if (results.isEmpty)
            const _EmptyPanel(text: '暂无在线字幕结果，可调整关键词或使用手动搜索链接。')
          else
            for (final item in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OnlineResultCard(controller: controller, item: item),
              ),
        ],
      );
    });
  }
}

class _OnlinePanelLoader extends StatefulWidget {
  const _OnlinePanelLoader({required this.controller, required this.start});

  final SubtitleManualUploadFormController controller;
  final Future<void> Function() start;

  @override
  State<_OnlinePanelLoader> createState() => _OnlinePanelLoaderState();
}

class _OnlinePanelLoaderState extends State<_OnlinePanelLoader> {
  bool _preparing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.start();
      if (!mounted) return;
      setState(() => _preparing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_preparing) {
      return const _OnlinePreparingView();
    }
    return _OnlinePanel(controller: widget.controller);
  }
}

class _AutoQueuePanel extends StatelessWidget {
  const _AutoQueuePanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final queue = controller.autoTransferQueue.value;
      final tasks = SubtitleManualUploadFormController.asMapList(
        queue['tasks'],
      );
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelTitle(title: '自动入库队列', icon: Icons.queue),
            if (tasks.isEmpty)
              const _InlineHint(icon: Icons.done_all, text: '暂无队列任务')
            else
              for (final task in tasks.take(20))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ListCard(
                    child: ListTile(
                      leading: const Icon(Icons.task_alt),
                      title: Text('${task['title'] ?? task['name'] ?? '任务'}'),
                      subtitle: Text(
                        '${task['status'] ?? task['message'] ?? ''}',
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
    });
  }
}

class _AutoQueuePanelLoader extends StatefulWidget {
  const _AutoQueuePanelLoader({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  State<_AutoQueuePanelLoader> createState() => _AutoQueuePanelLoaderState();
}

class _AutoQueuePanelLoaderState extends State<_AutoQueuePanelLoader> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.loadAutoTransferQueue();
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = SubtitleManualUploadFormController.asMapList(
      widget.controller.autoTransferQueue.value['tasks'],
    );
    if (_loading && tasks.isEmpty) {
      return const _LoadingPanel(text: '正在读取自动入库队列');
    }
    return _AutoQueuePanel(controller: widget.controller);
  }
}

class _SubtitleConfigView extends StatelessWidget {
  const _SubtitleConfigView({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final model = controller.formModel.value;
      return ListView(
        key: ValueKey(model),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _FeedbackBanner(controller: controller),
          _ConfigSection(
            title: '基础与自动处理',
            children: [
              _SwitchField(controller, 'enabled', '启用插件'),
              _SwitchField(controller, 'show_sidebar_nav', '显示侧边栏入口'),
              _SwitchField(controller, 'ai_link_enabled', '启用 AI 字幕联动'),
              _SwitchField(controller, 'traditional_to_simplified', '写入前繁体转简体'),
              _SwitchField(
                controller,
                'auto_search_on_transfer',
                '入库后自动搜索匹配字幕',
              ),
              _SwitchField(
                controller,
                'auto_skip_chinese_media_on_transfer',
                '入库自动处理跳过中文资源',
              ),
              _SwitchField(
                controller,
                'trust_transfer_history_paths',
                '信任整理历史路径',
              ),
              _SelectField(
                controller,
                'auto_transfer_subtitle_strategy',
                '入库后字幕处理策略',
                const {
                  'online_then_ai_source': '在线优先，AI 兜底',
                  'online_source_only': '只用在线匹配',
                  'ai_source_only': '只用 AI 生成',
                },
              ),
              _SelectField(
                controller,
                'auto_multi_subtitle_mode',
                '自动多字幕处理',
                const {
                  'best': '按偏好选择最佳',
                  'chinese_all': '中文/双语全部入库',
                  'all': '全部入库',
                },
              ),
              _ChipListField(
                controller,
                'auto_subtitle_language_priority',
                '语言优先级',
                const {
                  'bilingual': '双语',
                  'chi': '简中',
                  'cht': '繁中',
                  'eng': '英文',
                  'jpn': '日文',
                },
              ),
              _ChipListField(
                controller,
                'auto_subtitle_format_priority',
                '格式优先级',
                const {'ass': 'ASS', 'srt': 'SRT', 'ssa': 'SSA', 'vtt': 'VTT'},
              ),
              _SwitchField(
                controller,
                'auto_ass_to_srt_for_ai',
                '英文 ASS 转临时 SRT 后提交 AI',
              ),
            ],
          ),
          _ConfigSection(
            title: '在线字幕搜索',
            children: [
              _ChipListField(controller, 'online_providers', '启用字幕源', const {
                'subhd': 'SubHD',
                'zimuku': 'Zimuku',
                'assrt': '射手网(伪)',
                'opensubtitles': 'OpenSubtitles',
              }),
              _SwitchField(controller, 'online_use_proxy', 'API 搜索和下载使用系统代理'),
              _TextField(controller, 'subhd_url', 'SubHD 站点地址'),
              _TextField(controller, 'zimuku_url', 'Zimuku 站点地址'),
              _TextField(controller, 'assrt_url', '射手网(伪) 手动搜索地址'),
              _TextField(controller, 'assrt_api_url', '射手网(伪) API 地址'),
              _TextField(
                controller,
                'assrt_api_key',
                '射手网(伪) API Key',
                obscure: true,
              ),
              _TextField(
                controller,
                'opensubtitles_url',
                'OpenSubtitles 手动搜索地址',
              ),
              _TextField(
                controller,
                'opensubtitles_api_url',
                'OpenSubtitles API 地址',
              ),
              _TextField(
                controller,
                'opensubtitles_api_key',
                'OpenSubtitles API Key',
                obscure: true,
              ),
              _TextField(
                controller,
                'opensubtitles_username',
                'OpenSubtitles 用户名',
              ),
              _TextField(
                controller,
                'opensubtitles_password',
                'OpenSubtitles 密码',
                obscure: true,
              ),
            ],
          ),
          _ConfigSection(
            title: '智能调轴',
            children: [
              _NumberField(
                controller,
                'timeline_max_offset_seconds',
                '智能调轴最大偏移秒数',
              ),
              _NumberField(controller, 'timeline_min_offset_seconds', '最小应用阈值'),
              _SelectField(controller, 'timeline_vad_mode', '音频 VAD 模式', const {
                'webrtc': 'WebRTC VAD',
                'rms': 'RMS 能量阈值',
              }),
              _SwitchField(
                controller,
                'timeline_allow_risky_offset',
                '全局允许高风险偏移',
              ),
            ],
          ),
          _ConfigSection(
            title: 'RAR / 7Z 解压器',
            children: [
              _SelectField(
                controller,
                'rar_dependency_mode',
                '压缩包解压器处理方式',
                const {
                  'none': '不处理，仅检测',
                  'container_install': '加载插件时尝试安装',
                  'mapped_binary': '使用宿主机映射文件',
                },
              ),
              _TextField(controller, 'rar_tool_path', '容器内映射路径'),
            ],
          ),
        ],
      );
    });
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Section(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      header: SectionHeader(title: title),
      separatorBuilder: (_) => const SizedBox(height: 10),
      children: children,
    );
  }
}

class _SwitchField extends StatelessWidget {
  const _SwitchField(this.controller, this.name, this.label);

  final SubtitleManualUploadFormController controller;
  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: controller.formModel.value[name] == true,
      onChanged: (value) => controller.formModel.value = {
        ...controller.formModel.value,
        name: value,
      },
      title: Text(label),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField(
    this.controller,
    this.name,
    this.label, {
    this.obscure = false,
  });

  final SubtitleManualUploadFormController controller;
  final String name;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(name),
      initialValue: '${controller.formModel.value[name] ?? ''}',
      obscureText: obscure,
      decoration: _fieldDecoration(context, label: label),
      onChanged: (value) => controller.formModel.value = {
        ...controller.formModel.value,
        name: value,
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField(this.controller, this.name, this.label);

  final SubtitleManualUploadFormController controller;
  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(name),
      initialValue: '${controller.formModel.value[name] ?? ''}',
      keyboardType: TextInputType.number,
      decoration: _fieldDecoration(context, label: label),
      onChanged: (value) => controller.formModel.value = {
        ...controller.formModel.value,
        name: num.tryParse(value) ?? value,
      },
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField(this.controller, this.name, this.label, this.options);

  final SubtitleManualUploadFormController controller;
  final String name;
  final String label;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    final value = '${controller.formModel.value[name] ?? options.keys.first}';
    return DropdownButtonFormField<String>(
      initialValue: options.containsKey(value) ? value : options.keys.first,
      decoration: _fieldDecoration(context, label: label),
      items: options.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        controller.formModel.value = {
          ...controller.formModel.value,
          name: value,
        };
      },
    );
  }
}

class _ChipListField extends StatelessWidget {
  const _ChipListField(this.controller, this.name, this.label, this.options);

  final SubtitleManualUploadFormController controller;
  final String name;
  final String label;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    final selected = controller.asStringList(controller.formModel.value[name]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in options.entries)
              FilterChip(
                label: Text(entry.value),
                selected: selected.contains(entry.key),
                onSelected: (checked) {
                  final next = selected.toList();
                  if (checked) {
                    if (!next.contains(entry.key)) next.add(entry.key);
                  } else {
                    next.remove(entry.key);
                  }
                  controller.formModel.value = {
                    ...controller.formModel.value,
                    name: next,
                  };
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
    this.confirm = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool confirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final fg = primary ? Colors.white : theme.primaryColor;
    final bg = primary
        ? theme.primaryColor
        : theme.primaryColor.withValues(alpha: 0.10);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: enabled
            ? bg
            : Theme.of(context).disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  if (!confirm) {
                    onTap?.call();
                    return;
                  }
                  _confirmAction(
                    context,
                    title: label,
                    destructive: destructive,
                    onConfirm: () async => onTap?.call(),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled
                      ? fg
                      : Theme.of(context).disabledColor.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enabled
                        ? fg
                        : Theme.of(
                            context,
                          ).disabledColor.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeasonPill extends StatelessWidget {
  const _SeasonPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.primaryColor.withValues(alpha: 0.14),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected ? theme.primaryColor : null,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final bg = selected ? theme.primaryColor : theme.cardColor;
    final borderColor = selected
        ? theme.primaryColor
        : Theme.of(context).dividerColor.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 0.7),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualLinkChip extends StatelessWidget {
  const _ManualLinkChip({required this.label, required this.onTap});

  final Widget label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.primaryColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 15, color: theme.primaryColor),
              const SizedBox(width: 5),
              DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                child: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  const _SubtitleRow({
    required this.controller,
    required this.target,
    required this.subtitle,
  });

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> target;
  final Map<String, dynamic> subtitle;

  @override
  Widget build(BuildContext context) {
    final title = '${subtitle['name'] ?? subtitle['path'] ?? '字幕'}';
    final meta = '${subtitle['language'] ?? subtitle['size_text'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.closed_caption_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (meta.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _IconAction(
            tooltip: '调轴',
            icon: Icons.graphic_eq,
            onTap: controller.timelineAvailable
                ? () => controller.fixExistingTimeline([
                    {
                      'target_id': target['id'],
                      'subtitle_path': subtitle['path'],
                    },
                  ], '单个字幕')
                : null,
          ),
          _IconAction(
            tooltip: '恢复备份',
            icon: Icons.restore,
            onTap: () => controller.restoreSubtitleBackup(target, subtitle),
          ),
          _IconAction(
            tooltip: '删除',
            icon: Icons.delete_outline,
            onTap: () => controller.deleteSubtitle(target, subtitle),
          ),
        ],
      ),
    );
  }
}

class _OnlineResultCard extends StatelessWidget {
  const _OnlineResultCard({required this.controller, required this.item});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final key = controller.onlineResultKey(item);
    final selected = controller.onlineSelectedResultKeys.contains(key);
    final provider = _providerName('${item['provider'] ?? ''}');
    final language = '${item['language'] ?? item['language_name'] ?? ''}';
    return _ListCard(
      onTap: () => controller.toggleOnlineResult(item, !selected),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              visualDensity: VisualDensity.compact,
              onChanged: (value) =>
                  controller.toggleOnlineResult(item, value == true),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['title'] ?? item['name'] ?? '在线字幕'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MetaChip(label: provider),
                      if (language.trim().isNotEmpty)
                        _MetaChip(label: language),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlinePreparingView extends StatelessWidget {
  const _OnlinePreparingView();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            '准备在线字幕搜索',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            '正在读取字幕源状态并生成搜索条件',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.tooltip, required this.icon, this.onTap});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      onPressed: onTap == null
          ? null
          : () => _confirmAction(
              context,
              title: tooltip,
              destructive: tooltip.contains('删除'),
              onConfirm: () async => onTap?.call(),
            ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color ?? theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.child, this.onTap, this.selected = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderColor = selected
        ? colors.primary.withValues(alpha: 0.55)
        : colors.outline.withValues(alpha: 0.32);
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.16)
          : theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.2 : 0.6,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title, subtitle: trailing);
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
  bool dense = false,
}) {
  final primary = Theme.of(context).primaryColor;
  final enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.42),
    ),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: primary.withValues(alpha: 0.65)),
  );
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: dense ? 10 : 12,
    ),
    enabledBorder: enabledBorder,
    focusedBorder: focusedBorder,
    border: enabledBorder,
    filled: true,
    fillColor: Colors.transparent,
    prefixIcon: icon == null ? null : Icon(icon, size: 18),
    isDense: dense,
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (url.isEmpty) {
      return Container(
        width: 48,
        height: 64,
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.movie_outlined, color: theme.primaryColor),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 48,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 48,
          height: 64,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.movie_outlined, color: theme.primaryColor),
        ),
      ),
    );
  }
}

class _PickedFileRow extends StatelessWidget {
  const _PickedFileRow({required this.file, required this.onRemove});

  final fp.PlatformFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(file.name),
      subtitle: Text(_formatBytes(file.size)),
      trailing: IconButton(
        tooltip: '移除',
        onPressed: onRemove,
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
      ),
    );
  }
}

String _mediaPoster(Map<String, dynamic> item) {
  return '${item['poster_thumb_url'] ?? item['poster_url'] ?? ''}';
}

String _mediaSubtitle(Map<String, dynamic> item) {
  final parts = [
    '${item['media_type'] ?? ''}',
    '${item['season_count'] ?? item['episode_count'] ?? ''}',
    '${item['path_count'] ?? item['target_count'] ?? ''}',
  ].where((e) => e.trim().isNotEmpty).toList();
  return parts.join(' · ');
}

String _targetPath(Map<String, dynamic> target) {
  return '${target['path'] ?? ''}'.trim();
}

String _seasonLabel(Map<String, dynamic> season) {
  final title = '${season['title'] ?? season['label'] ?? ''}';
  if (title.isNotEmpty) return title;
  final value = '${season['value'] ?? season['season'] ?? ''}';
  return value == 'all' ? '全部' : '第 $value 季';
}

String _providerName(String provider) {
  switch (provider) {
    case 'subhd':
      return 'SubHD';
    case 'zimuku':
      return 'Zimuku';
    case 'assrt':
      return '射手网(伪)';
    case 'opensubtitles':
      return 'OpenSubtitles';
    default:
      return provider;
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

Future<void> _confirmAction(
  BuildContext context, {
  required String title,
  required Future<void> Function() onConfirm,
  String? message,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message ?? '确认执行此操作？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('确认'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await onConfirm();
}

Future<void> _launch(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<T?> _push<T>(
  BuildContext context,
  String title,
  WidgetBuilder childBuilder,
) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [childBuilder(context)],
          ),
        ),
      ),
    ),
  );
}
