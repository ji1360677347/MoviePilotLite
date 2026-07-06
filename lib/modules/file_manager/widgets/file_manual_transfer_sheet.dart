import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/file_manager/controllers/file_manager_browser_controller.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_list_controller.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/sse_client.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/file_storage_utils.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/custom_button.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

enum FileManualTransferMode { auto, movie, tv }

class FileManualTransferSheet extends StatefulWidget {
  const FileManualTransferSheet({
    super.key,
    required this.file,
    required this.availableStorages,
    required this.defaultTargetStorage,
    required this.submitTransfer,
  });

  final MediaOrganizeFileItem file;
  final List<StorageSetting> availableStorages;
  final String defaultTargetStorage;
  final Future<FileActionResult> Function({
    required String mode,
    required String targetStorage,
    required String transferType,
    required String targetPath,
    required bool scrape,
    required bool libraryTypeFolder,
    required bool libraryCategoryFolder,
    required String tmdbId,
    required String part,
    required String minFileSize,
    required String episodeGroup,
    required String season,
    required String episodeFormat,
    required String episodeOffset,
  })
  submitTransfer;

  static Future<void> show(
    BuildContext context, {
    required MediaOrganizeFileItem file,
    required List<StorageSetting> availableStorages,
    required String defaultTargetStorage,
    required Future<FileActionResult> Function({
      required String mode,
      required String targetStorage,
      required String transferType,
      required String targetPath,
      required bool scrape,
      required bool libraryTypeFolder,
      required bool libraryCategoryFolder,
      required String tmdbId,
      required String part,
      required String minFileSize,
      required String episodeGroup,
      required String season,
      required String episodeFormat,
      required String episodeOffset,
    })
    submitTransfer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FileManualTransferSheet(
        file: file,
        availableStorages: availableStorages,
        defaultTargetStorage: defaultTargetStorage,
        submitTransfer: submitTransfer,
      ),
    );
  }

  @override
  State<FileManualTransferSheet> createState() =>
      _FileManualTransferSheetState();
}

class _FileManualTransferSheetState extends State<FileManualTransferSheet> {
  static const _progressEndpoint = '/api/v1/system/progress/filetransfer';
  static const double _fieldHeight = 48;
  static const double _fieldRadius = 12;

  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  late final DirectoryListController _directoryController =
      _resolveDirectoryController();
  final TextEditingController _targetPathController = TextEditingController();
  final TextEditingController _tmdbIdController = TextEditingController();
  final TextEditingController _partController = TextEditingController();
  final TextEditingController _minFileSizeController = TextEditingController();
  final TextEditingController _episodeGroupController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _episodeFormatController =
      TextEditingController();
  final TextEditingController _episodeOffsetController =
      TextEditingController();

  FileManualTransferMode _mode = FileManualTransferMode.auto;
  String _targetStorage = '';
  String _transferType = 'auto';
  bool _scrape = true;
  bool _libraryTypeFolder = true;
  bool _libraryCategoryFolder = true;
  bool _showAdvancedOptions = false;
  bool _isSubmitting = false;
  double _progress = 0;
  String _progressMessage = '准备整理...';
  int _progressCurrent = 0;
  int _progressTotal = 0;
  String _progressSource = '';

  SseClient? _sseClient;
  StreamSubscription<SseEvent>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _targetStorage = _resolveDefaultStorage();
    if (_directoryController.directories.isEmpty &&
        !_directoryController.isLoading.value) {
      _directoryController.loadDirectories();
    }
    _syncTargetPathWithSuggestions();
  }

  DirectoryListController _resolveDirectoryController() {
    if (Get.isRegistered<DirectoryListController>()) {
      return Get.find<DirectoryListController>();
    }
    return Get.put(DirectoryListController());
  }

  @override
  void dispose() {
    _stopProgressTracking();
    _targetPathController.dispose();
    _tmdbIdController.dispose();
    _partController.dispose();
    _minFileSizeController.dispose();
    _episodeGroupController.dispose();
    _seasonController.dispose();
    _episodeFormatController.dispose();
    _episodeOffsetController.dispose();
    super.dispose();
  }

  String _resolveDefaultStorage() {
    final preferred = widget.defaultTargetStorage.trim();
    if (preferred.isNotEmpty) {
      final matched = widget.availableStorages.firstWhere(
        (item) => item.type == preferred,
        orElse: () => StorageSetting(type: preferred, name: preferred),
      );
      return matched.type;
    }
    if (widget.availableStorages.isNotEmpty) {
      return widget.availableStorages.first.type;
    }
    return widget.file.storage ?? 'local';
  }

  bool get _isTvMode => _mode == FileManualTransferMode.tv;

  String get _modeKey {
    switch (_mode) {
      case FileManualTransferMode.movie:
        return 'movie';
      case FileManualTransferMode.tv:
        return 'tv';
      case FileManualTransferMode.auto:
        return 'auto';
    }
  }

  void _onModeChanged(FileManualTransferMode? mode) {
    if (mode == null || mode == _mode) return;
    setState(() => _mode = mode);
  }

  List<String> get _targetPathOptions {
    final directories = _directoryController.directories;
    final exactMatches = directories
        .where(
          (dir) =>
              dir.libraryStorage.trim().isNotEmpty &&
              dir.libraryStorage.trim() == _targetStorage &&
              dir.libraryPath.trim().isNotEmpty,
        )
        .map((dir) => dir.libraryPath.trim())
        .toList();
    if (exactMatches.isNotEmpty) {
      return exactMatches.toSet().toList();
    }
    return directories
        .map((dir) => dir.libraryPath.trim())
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList();
  }

  void _syncTargetPathWithSuggestions() {
    final options = _targetPathOptions;
    if (options.isEmpty) {
      return;
    }
    final current = _targetPathController.text.trim();
    if (current.isEmpty || !options.contains(current)) {
      _targetPathController.text = options.first;
    }
  }

  Future<void> _submit() async {
    if (_targetStorage.trim().isEmpty) {
      ToastUtil.info('请选择目标存储');
      return;
    }
    if (_targetPathController.text.trim().isEmpty) {
      ToastUtil.info('请选择目标目录');
      return;
    }

    setState(() => _isSubmitting = true);
    await _startProgressTracking();
    final result = await widget.submitTransfer(
      mode: _modeKey,
      targetStorage: _targetStorage,
      transferType: _transferType,
      targetPath: _targetPathController.text,
      scrape: _scrape,
      libraryTypeFolder: _libraryTypeFolder,
      libraryCategoryFolder: _libraryCategoryFolder,
      tmdbId: _tmdbIdController.text,
      part: _partController.text,
      minFileSize: _minFileSizeController.text,
      episodeGroup: _episodeGroupController.text,
      season: _seasonController.text,
      episodeFormat: _episodeFormatController.text,
      episodeOffset: _episodeOffsetController.text,
    );
    await _stopProgressTracking();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final message = result.message.trim();
    if (result.success) {
      ToastUtil.success(message.isNotEmpty ? message : '整理任务已提交');
      Navigator.of(context).pop();
    } else {
      if (message.isNotEmpty) {
        ToastUtil.error(message);
      } else {
        ToastUtil.error('整理失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      header: SectionHeader(title: '文件整理'),
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            _buildCompactForm(context),
            const SizedBox(height: 16),
            _buildActionSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactForm(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = widget.file.name?.trim().isNotEmpty == true
        ? widget.file.name!.trim()
        : (widget.file.basename ?? '未命名文件');
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.doc_text,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '确认类型、目标位置和整理方式',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFieldLabel('媒体类型'),
          const SizedBox(height: 8),
          _buildSegmentContainer(
            context: context,
            child: CupertinoSlidingSegmentedControl<FileManualTransferMode>(
              groupValue: _mode,
              onValueChanged: _onModeChanged,
              backgroundColor: Colors.transparent,
              thumbColor: _segmentThumbColor(context),
              children: {
                FileManualTransferMode.auto: _buildSegmentText(
                  context,
                  '自动',
                  _mode == FileManualTransferMode.auto,
                ),
                FileManualTransferMode.movie: _buildSegmentText(
                  context,
                  '电影',
                  _mode == FileManualTransferMode.movie,
                ),
                FileManualTransferMode.tv: _buildSegmentText(
                  context,
                  '电视剧',
                  _mode == FileManualTransferMode.tv,
                ),
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildStorageField(context),
          const SizedBox(height: 14),
          _buildTargetPathField(context),
          _buildTargetPathStatus(),
          _buildFieldLabel('整理方式'),
          const SizedBox(height: 8),
          _buildSegmentContainer(
            context: context,
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _transferType,
              backgroundColor: Colors.transparent,
              thumbColor: _segmentThumbColor(context),
              onValueChanged: (value) {
                if (value == null) return;
                setState(() => _transferType = value);
              },
              children: {
                'auto': _buildSegmentText(
                  context,
                  '自动',
                  _transferType == 'auto',
                ),
                'copy': _buildSegmentText(
                  context,
                  '复制',
                  _transferType == 'copy',
                ),
                'move': _buildSegmentText(
                  context,
                  '移动',
                  _transferType == 'move',
                ),
                'softlink': _buildSegmentText(
                  context,
                  '软链',
                  _transferType == 'softlink',
                ),
                'hardlink': _buildSegmentText(
                  context,
                  '硬链',
                  _transferType == 'hardlink',
                ),
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildCompactToggles(context),
          const SizedBox(height: 16),
          _buildAdvancedToggle(context),
          if (_showAdvancedOptions) ...[
            const SizedBox(height: 14),
            _buildAdvancedFields(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_fieldRadius),
        onTap: () {
          setState(() => _showAdvancedOptions = !_showAdvancedOptions);
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _controlSurface(context),
            borderRadius: BorderRadius.circular(_fieldRadius),
            border: Border.all(color: _outlineColor(context)),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.slider_horizontal_3,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '高级参数',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _showAdvancedOptions ? '收起' : '可选',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _showAdvancedOptions
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFields(BuildContext context) {
    return Column(
      children: [
        _buildResponsivePair(
          context,
          first: _buildTextField(
            label: 'TheMovieDB',
            controller: _tmdbIdController,
            placeholder: 'TMDB ID',
            keyboardType: TextInputType.number,
          ),
          second: _buildTextField(
            label: '指定 Part',
            controller: _partController,
            placeholder: '可选',
          ),
        ),
        const SizedBox(height: 14),
        _buildResponsivePair(
          context,
          first: _buildTextField(
            label: '最小文件尺寸(MB)',
            controller: _minFileSizeController,
            placeholder: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          second: _isTvMode
              ? _buildTextField(
                  label: 'Season',
                  controller: _seasonController,
                  placeholder: '季',
                  keyboardType: TextInputType.number,
                )
              : null,
        ),
        if (_isTvMode) ...[
          const SizedBox(height: 14),
          _buildResponsivePair(
            context,
            first: _buildTextField(
              label: '指定剧集组',
              controller: _episodeGroupController,
              placeholder: '可选',
            ),
            second: _buildTextField(
              label: '集数定位',
              controller: _episodeFormatController,
              placeholder: '可选',
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: '集数偏移',
            controller: _episodeOffsetController,
            placeholder: '可选',
            keyboardType: const TextInputType.numberWithOptions(signed: true),
          ),
        ],
      ],
    );
  }

  Widget _buildResponsivePair(
    BuildContext context, {
    required Widget first,
    Widget? second,
  }) {
    if (second == null) {
      return first;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(children: [first, const SizedBox(height: 14), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Future<void> _startProgressTracking() async {
    await _stopProgressTracking();

    final baseUrl = _apiClient.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return;
    }

    final cookieHeader = await _apiClient.getCookieHeader();
    final headers = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      if (cookieHeader != null && cookieHeader.isNotEmpty)
        'Cookie': cookieHeader,
      if (_apiClient.token != null && _apiClient.token!.isNotEmpty)
        'authorization': 'Bearer ${_apiClient.token!}',
    };

    final sseClient = SseClient(baseUrl: baseUrl, headers: headers);
    final subscription = sseClient
        .connect(_progressEndpoint)
        .listen(
          _handleProgressEvent,
          onError: (error) => _log.warning('手动整理进度 SSE 失败: $error'),
        );

    if (!mounted) {
      await subscription.cancel();
      sseClient.disconnect();
      return;
    }

    setState(() {
      _sseClient = sseClient;
      _progressSubscription = subscription;
      _progress = 0;
      _progressMessage = '正在连接整理进度...';
      _progressCurrent = 0;
      _progressTotal = 0;
      _progressSource = '';
    });
  }

  Future<void> _stopProgressTracking() async {
    await _progressSubscription?.cancel();
    _progressSubscription = null;
    _sseClient?.disconnect();
    _sseClient = null;
    if (!mounted) return;
    setState(() {});
  }

  void _handleProgressEvent(SseEvent event) {
    final json = event.jsonData;
    if (json == null || !mounted) return;
    try {
      final progress = SearchProgressEvent.fromJson(json);
      setState(() {
        _progress = progress.progress;
        _progressMessage = progress.message?.trim().isNotEmpty == true
            ? progress.message!.trim()
            : _progressMessage;
        final data = progress.data;
        if (data != null) {
          _progressCurrent = _readInt(data['current']) ?? _progressCurrent;
          _progressTotal = _readInt(data['total']) ?? _progressTotal;
          _progressSource = data['source']?.toString() ?? _progressSource;
        }
      });
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '解析手动整理进度失败');
    }
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Widget _buildCompactToggles(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _controlSurface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _outlineColor(context)),
      ),
      child: Column(
        children: [
          _buildSwitchRow(
            title: '刮削',
            value: _scrape,
            onChanged: (value) => setState(() => _scrape = value),
          ),
          const SizedBox(height: 10),
          _buildSwitchRow(
            title: '按类型分类',
            value: _libraryTypeFolder,
            onChanged: (value) => setState(() => _libraryTypeFolder = value),
          ),
          const SizedBox(height: 10),
          _buildSwitchRow(
            title: '按类别分类',
            value: _libraryCategoryFolder,
            onChanged: (value) =>
                setState(() => _libraryCategoryFolder = value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    final footerParts = <String>[
      if (_progressTotal > 0) '$_progressCurrent/$_progressTotal',
      if (_progressSource.trim().isNotEmpty) _progressSource.trim(),
    ];
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isSubmitting ? '整理进度' : '开始整理',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_isSubmitting)
                Text(
                  '$percent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isSubmitting) ...[
            Text(
              _progressMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: _controlSurface(context),
                color: scheme.primary,
              ),
            ),
            if (footerParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                footerParts.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ] else ...[
            Text(
              '确认目标信息后发起整理任务',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _isSubmitting ? '整理中...' : '开始整理',
                  icon: CupertinoIcons.arrow_2_circlepath_circle,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('目标存储'),
        const SizedBox(height: 8),
        _buildStorageSelector(context),
      ],
    );
  }

  Widget _buildStorageSelector(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final storages = widget.availableStorages.isEmpty
        ? [StorageSetting(type: _targetStorage, name: _targetStorage)]
        : widget.availableStorages;
    final selected = storages.firstWhere(
      (item) => item.type == _targetStorage,
      orElse: () => StorageSetting(type: _targetStorage, name: _targetStorage),
    );
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        onSelected: (value) {
          setState(() {
            _targetStorage = value;
            _syncTargetPathWithSuggestions();
          });
        },
        itemBuilder: (_) => [
          for (final storage in storages)
            PopupMenuItem<String>(
              value: storage.type,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: FileStorageUtils.storageIconWidget(
                      storage.type,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      storage.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (storage.type == _targetStorage)
                    Icon(
                      CupertinoIcons.checkmark,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
        child: _buildFieldSurface(
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: FileStorageUtils.storageIconWidget(
                  selected.type,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ).copyWith(color: scheme.onSurface),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_up_chevron_down,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetPathField(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final options = _targetPathOptions;
      final current = _targetPathController.text.trim();
      final resolvedValue = options.contains(current)
          ? current
          : (options.isNotEmpty ? options.first : '');
      if (resolvedValue.isNotEmpty && resolvedValue != current) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _targetPathController.text = resolvedValue;
        });
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('目标目录'),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              enabled: options.isNotEmpty,
              onSelected: (value) {
                setState(() => _targetPathController.text = value);
              },
              itemBuilder: (_) => [
                for (final path in options)
                  PopupMenuItem<String>(
                    value: path,
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.folder,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (path == resolvedValue)
                          Icon(
                            CupertinoIcons.checkmark,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
              ],
              child: _buildFieldSurface(
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.folder,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resolvedValue.isNotEmpty ? resolvedValue : '暂无可用目录',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: options.isNotEmpty
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      options.isNotEmpty
                          ? CupertinoIcons.chevron_up_chevron_down
                          : CupertinoIcons.exclamationmark_circle,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTargetPathStatus() {
    return Obx(() {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final error = _directoryController.errorText.value?.trim() ?? '';
      final isLoading = _directoryController.isLoading.value;
      final hasOptions = _targetPathOptions.isNotEmpty;
      if (error.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        );
      }
      if (isLoading && !hasOptions) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '目录加载中...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return const SizedBox(height: 14);
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        SizedBox(
          height: _fieldHeight,
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            cursorColor: scheme.primary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
            placeholderStyle: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _controlSurface(context),
              borderRadius: BorderRadius.circular(_fieldRadius),
              border: Border.all(color: _outlineColor(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildFieldSurface({required Widget child}) {
    return Container(
      height: _fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _controlSurface(context),
        borderRadius: BorderRadius.circular(_fieldRadius),
        border: Border.all(color: _outlineColor(context)),
      ),
      child: SizedBox(width: double.infinity, child: child),
    );
  }

  Widget _buildSegmentContainer({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _controlSurface(context),
        borderRadius: BorderRadius.circular(_fieldRadius),
        border: Border.all(color: _outlineColor(context)),
      ),
      child: SizedBox(width: double.infinity, child: child),
    );
  }

  Widget _buildSegmentText(BuildContext context, String text, bool isSelected) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: scheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Color _controlSurface(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.72 : 0.64,
    );
  }

  Color _segmentThumbColor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surface;
  }

  Color _outlineColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.72);
  }
}
