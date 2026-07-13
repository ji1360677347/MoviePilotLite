import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_notexists.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/app_glass_card.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class SubscribeTvSeasonSheet extends StatefulWidget {
  const SubscribeTvSeasonSheet({
    super.key,
    required this.tmdbId,
    required this.title,
    required this.year,
    required this.season,
    this.itemInfo,
  });
  final String? tmdbId;
  final String? title;
  final String? year;
  final String? season;
  final Map<String, dynamic>? itemInfo;

  @override
  State<SubscribeTvSeasonSheet> createState() => _SubscribeTvSeasonSheetState();
}

class SeasonStateInfo {
  final SeasonInfo seasonInfo;
  final MediaNotExists? mediaNotExists;
  SeasonStateInfo({required this.seasonInfo, this.mediaNotExists});

  bool get isMissing =>
      mediaNotExists != null &&
      ((mediaNotExists!.episodes?.isNotEmpty ?? false) ||
          (mediaNotExists!.total_episode ?? 0) > 0);
}

class _SubscribeTvSeasonSheetState extends State<SubscribeTvSeasonSheet> {
  final _subscribeController = Get.find<SubscribeController>();
  final _mediaDetailService = Get.find<MediaDetailService>();

  List<SeasonStateInfo> _seasonInfoList = [];
  final Set<int> _selectedSeasonNumbers = {};
  bool _loading = true;
  String? _loadError;
  String _selectedEpisodeGroupId = '';
  List<EpisodeGroupOption> _episodeGroupOptions = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initEpisodeGroups();
    _loadData();
  }

  void _initEpisodeGroups() {
    _episodeGroupOptions = [const EpisodeGroupOption(id: '', name: '默认')];
    final groups = widget.itemInfo?['episode_groups'];
    if (groups is List) {
      for (final g in groups) {
        if (g is Map<String, dynamic>) {
          final id = g['id']?.toString() ?? '';
          final name = g['name']?.toString() ?? id;
          if (id.isNotEmpty || _episodeGroupOptions.length == 1) {
            _episodeGroupOptions.add(EpisodeGroupOption(id: id, name: name));
          }
        }
      }
    }
    if (_episodeGroupOptions.isNotEmpty) {
      _selectedEpisodeGroupId = _episodeGroupOptions.first.id;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final seasonInfo = await _mediaDetailService.getSeasonInfo(
        mediaId: widget.tmdbId ?? '',
        season: widget.season ?? '',
        title: widget.title ?? '',
        year: widget.year ?? '',
      );
      final mediaNotExists = await _mediaDetailService.getMediaNotExists(
        widget.itemInfo ?? {},
      );
      final merged = <SeasonStateInfo>[];
      for (final el in seasonInfo) {
        final sn = el.season_number;
        MediaNotExists? notExists;
        if (sn != null) {
          try {
            notExists = mediaNotExists.where((e) => e.season == sn).first;
          } catch (_) {}
        }
        merged.add(SeasonStateInfo(seasonInfo: el, mediaNotExists: notExists));
      }
      if (!mounted) return;
      setState(() {
        _seasonInfoList = merged;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _seasonInfoList = [];
        _loading = false;
        _loadError = '加载季信息失败，请稍后重试';
      });
    }
  }

  void _toggleSeason(int seasonNumber) {
    setState(() {
      if (_selectedSeasonNumbers.contains(seasonNumber)) {
        _selectedSeasonNumbers.remove(seasonNumber);
      } else {
        _selectedSeasonNumbers.add(seasonNumber);
      }
    });
  }

  Future<void> _onSubmit() async {
    if (_selectedSeasonNumbers.isEmpty || _submitting) return;
    final item = widget.itemInfo ?? {};
    final doubanId = item['douban_id']?.toString() ?? '';
    final name = widget.title ?? item['name']?.toString() ?? '';
    final tmdbId = widget.tmdbId ?? item['tmdb_id']?.toString() ?? '';
    final year = widget.year ?? item['year']?.toString() ?? '';
    final mediaId = item['media_id']?.toString() ?? '';

    setState(() => _submitting = true);
    var successCount = 0;
    for (final seasonNum in _selectedSeasonNumbers) {
      final ok = await _subscribeController.submitTvSubscribe(
        doubanid: doubanId,
        episode_group: _selectedEpisodeGroupId.isEmpty
            ? ''
            : _selectedEpisodeGroupId,
        mediaid: mediaId.isEmpty ? '' : mediaId,
        name: name,
        season: seasonNum,
        tmdbid: tmdbId.isEmpty ? null : tmdbId,
        year: year.isEmpty ? null : year,
      );
      if (ok.success == true) {
        successCount++;
      } else {
        Get.snackbar('订阅失败', ok.message ?? '请稍后重试');
      }
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (successCount > 0) {
      Navigator.of(context).pop(true);
      Get.snackbar('订阅成功', '已提交 $successCount 季的订阅');
    } else {
      Get.snackbar('订阅失败', '请稍后重试');
    }
  }

  static String _formatAirDate(String? airDate) {
    if (airDate == null || airDate.isEmpty) return '';
    final parts = airDate.split('-');
    if (parts.length >= 3) {
      return '首播于 ${parts[0]}年${parts[1]}月${parts[2]}日';
    }
    return airDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('选择订阅季度'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 720
              ? 680.0
              : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSummary(theme),
                  _buildEpisodeGroupSection(theme),
                  Expanded(child: _buildBodyState(theme)),
                  _buildBottomButton(theme, bottomInset),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBodyState(ThemeData theme) {
    if (_loading) {
      return const AppLoadingCenter(message: '正在读取季度信息');
    }
    if (_loadError != null) {
      return _buildStateMessage(
        theme,
        icon: Icons.cloud_off_rounded,
        title: '加载失败',
        message: _loadError!,
        actionLabel: '重试',
        onAction: _loadData,
      );
    }
    if (_seasonInfoList.isEmpty) {
      return _buildStateMessage(
        theme,
        icon: Icons.tv_off_rounded,
        title: '暂无季度',
        message: '当前媒体没有可订阅的季度信息',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      itemCount: _seasonInfoList.length,
      itemBuilder: (context, index) =>
          _buildSeasonItem(context, _seasonInfoList[index]),
    );
  }

  Widget _buildHeaderSummary(ThemeData theme) {
    final selected = _selectedSeasonNumbers.length;
    final available = _seasonInfoList.where((e) => !e.isMissing).length;
    final total = _seasonInfoList.length;
    final title = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : '电视剧订阅';
    final subtitleParts = <String>[
      if ((widget.year ?? '').trim().isNotEmpty) widget.year!.trim(),
      if (total > 0) '$available/$total 季可订阅',
      if (selected > 0) '已选 $selected 季',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: AppGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        surfaceAlpha: theme.brightness == Brightness.dark ? 0.42 : 0.72,
        shadowAlpha: theme.brightness == Brightness.dark ? 0.14 : 0.07,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.live_tv_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.isEmpty
                        ? '选择需要订阅的季度'
                        : subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStateMessage(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 46,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeGroupSection(ThemeData theme) {
    final hasMultipleGroups = _episodeGroupOptions.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '剧集组',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasMultipleGroups ? '可切换不同分集规则' : '使用默认分集规则',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.34 : 0.66,
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedEpisodeGroupId,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _episodeGroupOptions
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedEpisodeGroupId = v ?? '');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonItem(BuildContext context, SeasonStateInfo state) {
    final theme = Theme.of(context);
    final s = state.seasonInfo;
    final seasonNum = s.season_number ?? -1;
    final canSelect = !state.isMissing;
    final selected = _selectedSeasonNumbers.contains(seasonNum);
    final imageUrl = ImageUtil.convertMediaSeasonImageUrl(s.poster_path ?? '');
    final year = s.air_date != null && s.air_date!.length >= 4
        ? s.air_date!.substring(0, 4)
        : '';
    final episodeCount = s.episode_count ?? 0;
    final rating = s.vote_average;

    final metaParts = <String>[
      if (year.isNotEmpty) year,
      if (episodeCount > 0) '$episodeCount 集',
      if (rating != null && rating > 0) '评分 ${rating.toStringAsFixed(1)}',
    ];
    final airDate = _formatAirDate(s.air_date);
    final surfaceColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.11)
        : theme.colorScheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.50 : 0.78,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: canSelect ? 1 : 0.58,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.52)
                  : theme.colorScheme.outline.withValues(alpha: 0.10),
              width: selected ? 1.2 : 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: selected
                      ? (theme.brightness == Brightness.dark ? 0.24 : 0.10)
                      : (theme.brightness == Brightness.dark ? 0.12 : 0.045),
                ),
                blurRadius: selected ? 20 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canSelect ? () => _toggleSeason(seasonNum) : null,
              borderRadius: BorderRadius.circular(18),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(18),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedImage(
                          imageUrl: imageUrl,
                          width: 72,
                          height: 100,
                          fit: BoxFit.cover,
                          errorWidget: _buildPosterFallback(theme),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 12, 10, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name ?? '第 $seasonNum 季',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildSeasonToggle(theme, selected, canSelect),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              metaParts.isEmpty
                                  ? '暂无季度信息'
                                  : metaParts.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (state.isMissing)
                              _buildMissingPill(theme)
                            else
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.72),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      airDate.isEmpty ? '暂无首播日期' : airDate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildPosterFallback(ThemeData theme) {
    return Container(
      width: 82,
      height: 116,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.50 : 0.76,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.tv_rounded,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
        size: 32,
      ),
    );
  }

  Widget _buildSeasonToggle(ThemeData theme, bool selected, bool enabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: enabled ? 0.72 : 0.32,
              ),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: 18,
              color: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildMissingPill(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        '已有缺失记录，暂不可重复选择',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme, double bottomInset) {
    final count = _selectedSeasonNumbers.length;
    final enabled = count > 0 && !_submitting;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? 8 : 16),
        child: AppGlassCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          borderRadius: 22,
          shadowAlpha: theme.brightness == Brightness.dark ? 0.16 : 0.08,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  count > 0 ? '已选择 $count 季' : '请选择要订阅的季度',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: enabled ? _onSubmit : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(count > 0 ? '提交订阅' : '未选择'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EpisodeGroupOption {
  const EpisodeGroupOption({required this.id, required this.name});
  final String id;
  final String name;
}
