import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:altman_downloader_control/controller/controller_adaptor.dart';
import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/page/torrent_download_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_list_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/models/downloader_stats.dart';
import 'package:moviepilot_mobile/modules/download/utils/search_result_raw_cache.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/modules/setting/controllers/setting_controller.dart';
import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final scrollController = DraggableScrollableController();
  // 下载器列表（使用 DownloadClient）
  final downloaders = <DownloadClient>[].obs;
  final selectedDownloader = Rxn<DownloadClient>();

  /// 各下载器状态（GET /api/v1/dashboard/downloader?name=xxx）
  final downloaderStats = <String, DownloaderStats>{}.obs;
  Timer? _statsTimer;
  static const Duration _statsInterval = Duration(seconds: 8);

  // 下载目录列表和建议
  final selectedDirectory = ''.obs;
  String? _preferredDownloaderName;
  String _preferredDirectory = '';

  // TMDB ID
  final tmdbId = ''.obs;

  // 高级选项展开状态
  final showAdvanced = false.obs;

  // 加载状态
  final isDownloading = false.obs;
  final isSpecialDownloading = false.obs;

  SettingController get _settingController {
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController());
    }
    return Get.find<SettingController>();
  }

  DirectoryListController get _directoryListController {
    if (!Get.isRegistered<DirectoryListController>()) {
      Get.put(DirectoryListController(), permanent: true);
    }
    return Get.find<DirectoryListController>();
  }

  @override
  void onInit() {
    super.onInit();
    _restoreSheetSelections();
    _loadDownloaders();
    _loadDirectories();
    ever(downloaders, (_) => loadDownloaderStats());
    // 在下一帧启动定时器，避免 init 阶段被 dispose 或调度未就绪
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        _statsTimer?.cancel();
        _statsTimer = Timer.periodic(
          _statsInterval,
          (_) => loadDownloaderStats(),
        );
      }
    });
  }

  @override
  void onClose() {
    _statsTimer?.cancel();
    _statsTimer = null;
    super.onClose();
  }

  /// 加载下载器列表（从 SettingController）
  void _loadDownloaders() {
    // 监听 SettingController 的下载客户端列表
    ever(_settingController.downloadClients, (clients) {
      downloaders.value = clients;
      _applyPreferredDownloader();
    });

    // 立即同步一次
    if (_settingController.downloadClients.isNotEmpty) {
      downloaders.value = _settingController.downloadClients.toList();
      _applyPreferredDownloader();
    }
  }

  /// 加载下载目录列表（从 SettingController）
  void _loadDirectories() {
    ever(_directoryListController.directories, (_) {
      _applyPreferredDirectory();
    });
    _applyPreferredDirectory();
  }

  /// 获取目录建议列表
  List<String> get directorySuggestions {
    final seen = <String>{};
    for (final value in _settingController.directorySuggestions) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        seen.add(normalized);
      }
    }
    return seen.toList();
  }

  /// 获取目录列表（从目录设置中提取）
  List<String> get directories {
    return _settingController.directories
        .map((dir) => dir.downloadPath)
        .where((path) => path.isNotEmpty)
        .toList();
  }

  Future<void> _restoreSheetSelections() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredDownloaderName = prefs.getString(kDownloadSheetLastDownloaderKey);
    _preferredDirectory = prefs.getString(kDownloadSheetLastDirectoryKey) ?? '';
    _applyPreferredDownloader();
    _applyPreferredDirectory();
  }

  void _applyPreferredDownloader() {
    if (downloaders.isEmpty) {
      selectedDownloader.value = null;
      return;
    }

    final preferredName = _preferredDownloaderName;
    if (preferredName != null && preferredName.isNotEmpty) {
      final matched = downloaders.firstWhereOrNull(
        (item) => item.name == preferredName,
      );
      if (matched != null) {
        selectedDownloader.value = matched;
        return;
      }
    }

    selectedDownloader.value ??= downloaders.first;
  }

  void _applyPreferredDirectory() {
    final preferred = _preferredDirectory.trim();
    if (preferred.isEmpty) {
      if (selectedDirectory.value.isEmpty) return;
      selectedDirectory.value = '';
      return;
    }

    final available = directorySuggestions;
    if (available.contains(preferred)) {
      selectedDirectory.value = preferred;
      return;
    }

    if (selectedDirectory.value.isEmpty) return;
    selectedDirectory.value = '';
  }

  Future<void> _persistSheetSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaderName = selectedDownloader.value?.name ?? '';
    await prefs.setString(kDownloadSheetLastDownloaderKey, downloaderName);
    await prefs.setString(
      kDownloadSheetLastDirectoryKey,
      selectedDirectory.value,
    );
  }

  /// 获取下载器加载状态
  bool get isLoadingDownloaders =>
      _settingController.isLoadingDownloadClients.value;

  /// 刷新下载器列表（供配置列表页下拉刷新等使用）
  Future<void> refreshDownloaders() async {
    await _settingController.loadDownloadClients();
    await loadDownloaderStats();
  }

  /// 获取各下载器状态
  Future<void> loadDownloaderStats() async {
    if (downloaders.isEmpty || isClosed) return;
    final Map<String, DownloaderStats> newStats = {};
    for (final d in downloaders) {
      if (d.name.isEmpty) continue;
      try {
        final resp = await _apiClient.get<Map<String, dynamic>>(
          '/api/v1/dashboard/downloader',
          queryParameters: {'name': d.name},
        );
        if (resp.statusCode == 200 && resp.data != null) {
          newStats[d.name] = DownloaderStats.fromJson(resp.data!);
        }
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '获取下载器 ${d.name} 状态失败');
      }
    }
    if (!isClosed) {
      downloaderStats.assignAll(newStats);
      downloaderStats.refresh();
    }
  }

  DownloaderStats? statsFor(String downloaderName) =>
      downloaderStats[downloaderName];

  /// 获取目录加载状态
  bool get isLoadingDirectories => _settingController.isLoadingDirectories;

  Map<String, dynamic> _normalizeTorrentIn(Map<String, dynamic> torrent) {
    final normalized = Map<String, dynamic>.from(torrent);
    final proxy = normalized['site_proxy'];
    if (proxy is bool) {
      normalized['site_proxy'] = proxy ? 1 : 0;
    }
    return normalized;
  }

  Map<String, dynamic>? _buildDownloadTorrentIn(SearchResultItem item) {
    final raw = rawTorrentInfoFor(item);
    if (raw != null && raw.isNotEmpty) {
      return _normalizeTorrentIn(raw);
    }
    final torrent = item.torrent_info;
    if (torrent == null) return null;
    return _normalizeTorrentIn(torrent.toJson());
  }

  Map<String, dynamic>? _buildDownloadMediaIn(
    SearchResultItem item, {
    String? customTmdbId,
  }) {
    final raw = rawMediaInfoFor(item);
    final media = raw != null && raw.isNotEmpty
        ? Map<String, dynamic>.from(raw)
        : item.media_info?.toJson();
    if (media == null || media.isEmpty) return null;
    if (customTmdbId == null || customTmdbId.isEmpty) return media;
    final parsed = int.tryParse(customTmdbId.trim());
    return {...media, 'tmdb_id': parsed ?? customTmdbId.trim()};
  }

  void _logStartDownloadRequest({
    required Map<String, dynamic> payload,
    required bool torrentFromRaw,
    required bool mediaFromRaw,
  }) {
    final torrent = payload['torrent_in'];
    final media = payload['media_in'];
    final torrentMap = torrent is Map ? Map<String, dynamic>.from(torrent) : null;
    final mediaMap = media is Map ? Map<String, dynamic>.from(media) : null;
    final enclosure = torrentMap?['enclosure']?.toString() ?? '';

    _log.info(
      '下载请求 POST /api/v1/download/: '
      'downloader=${payload['downloader']}, '
      'save_path=${payload['save_path']}, '
      'tmdbid=${payload['tmdbid']}, '
      'torrentSource=${torrentFromRaw ? 'raw' : 'model'}, '
      'mediaSource=${mediaMap == null ? 'none' : (mediaFromRaw ? 'raw' : 'model')}',
    );
    if (torrentMap != null) {
      _log.info(
        'torrent_in: site=${torrentMap['site']}, '
        'site_name=${torrentMap['site_name']}, '
        'site_proxy=${torrentMap['site_proxy']}(${torrentMap['site_proxy']?.runtimeType}), '
        'category=${torrentMap['category']}, '
        'title=${_shorten(torrentMap['title']?.toString() ?? '', 100)}',
      );
      _log.info(
        'torrent_in: enclosure=${_describeEnclosureMode(enclosure)}, '
        'enclosureLen=${enclosure.length}, '
        'page_url=${_shorten(torrentMap['page_url']?.toString() ?? '', 120)}, '
        'site_cookie=${_describeSecretPresence(torrentMap['site_cookie'])}',
      );
      _log.debug('torrent_in keys(${torrentMap.length}): ${torrentMap.keys.toList()}');
    }
    if (mediaMap != null) {
      final tmdbId = mediaMap['tmdb_id'];
      _log.info(
        'media_in: source=${mediaMap['source']}, type=${mediaMap['type']}, '
        'tmdb_id=$tmdbId(${tmdbId.runtimeType}), '
        'title=${_shorten(mediaMap['title']?.toString() ?? '', 60)}, '
        'season_years=${mediaMap.containsKey('season_years')}',
      );
      _log.debug('media_in keys(${mediaMap.length}): ${mediaMap.keys.toList()}');
    }
  }

  String _describeSecretPresence(Object? value) {
    if (value == null) return 'absent';
    final text = value.toString().trim();
    if (text.isEmpty) return 'empty';
    return 'present:${text.length}chars';
  }

  /// 开始下载
  Future<void> startDownload({
    required SearchResultItem item,
    String? customTmdbId,
  }) async {
    if (selectedDownloader.value == null) {
      ToastUtil.error('请选择下载器');
      return;
    }

    final torrentFromRaw = rawTorrentInfoFor(item)?.isNotEmpty == true;
    final mediaFromRaw = rawMediaInfoFor(item)?.isNotEmpty == true;
    final torrentIn = _buildDownloadTorrentIn(item);
    if (torrentIn == null) {
      _log.warning(
        '下载中止: 缺少种子信息, torrentFromRaw=$torrentFromRaw, '
        'hasTorrentModel=${item.torrent_info != null}',
      );
      ToastUtil.error('缺少种子信息');
      return;
    }

    isDownloading.value = true;
    try {
      final payload = <String, dynamic>{
        'torrent_in': torrentIn,
        'downloader': selectedDownloader.value!.name,
        'save_path': selectedDirectory.value.isNotEmpty
            ? selectedDirectory.value
            : null,
      };
      final mediaIn = _buildDownloadMediaIn(
        item,
        customTmdbId: customTmdbId,
      );
      if (mediaIn != null) {
        payload['media_in'] = mediaIn;
      }
      if (customTmdbId != null && customTmdbId.trim().isNotEmpty) {
        payload['tmdbid'] = customTmdbId.trim();
      }

      _logStartDownloadRequest(
        payload: payload,
        torrentFromRaw: torrentFromRaw,
        mediaFromRaw: mediaFromRaw,
      );

      final response = await _apiClient.post(
        '/api/v1/download/',
        data: payload,
        timeout: 120,
      );

      _log.info(
        '下载响应: status=${response.statusCode}, '
        'success=${response.data is Map ? (response.data as Map)['success'] : 'n/a'}, '
        'data=${_shorten(response.data?.toString() ?? '', 500)}',
      );

      // 处理重定向（如果 Dio 没有自动跟随）
      if (response.statusCode == 307 ||
          response.statusCode == 301 ||
          response.statusCode == 302) {
        final location =
            response.headers.value('location') ??
            response.headers.value('Location');
        if (location != null) {
          _log.info('检测到重定向到: $location');
          // 解析重定向 URL（可能是相对路径）
          String redirectPath = location;
          if (location.startsWith('http://') ||
              location.startsWith('https://')) {
            // 绝对 URL，提取路径部分
            final uri = Uri.parse(location);
            redirectPath = uri.path;
            if (uri.queryParameters.isNotEmpty) {
              redirectPath += '?${uri.query}';
            }
          } else if (!location.startsWith('/')) {
            redirectPath = '/api/v1/download/$location';
          }

          _log.info('重定向路径: $redirectPath');
          // 对于 307，需要保持原始请求方法和请求体
          final redirectResponse = await _apiClient.post(
            redirectPath,
            data: payload,
            timeout: 120,
          );
          _log.info(
            '重定向后响应状态码: ${redirectResponse.statusCode}, 数据: ${redirectResponse.data}',
          );

          if (redirectResponse.statusCode == 200 ||
              redirectResponse.statusCode == 201) {
            final redirectData = redirectResponse.data;
            final redirectFailed =
                redirectData is Map && redirectData['success'] == false;
            if (!redirectFailed) {
              Get.back();
              Future.delayed(const Duration(seconds: 1), () {
                ToastUtil.success('下载任务已创建');
              });
            } else {
              final errorMsg = redirectData is Map
                  ? redirectData['message'] ??
                        redirectData['detail'] ??
                        '下载失败 (HTTP ${redirectResponse.statusCode})'
                  : '下载失败 (HTTP ${redirectResponse.statusCode})';
              ToastUtil.error(errorMsg.toString());
              _log.error('重定向后下载失败: $errorMsg, 响应数据: $redirectData');
            }
          } else {
            final errorMsg = redirectResponse.data is Map
                ? (redirectResponse.data as Map)['message'] ??
                      (redirectResponse.data as Map)['detail'] ??
                      '下载失败 (HTTP ${redirectResponse.statusCode})'
                : '下载失败 (HTTP ${redirectResponse.statusCode})';
            ToastUtil.error(errorMsg);
            _log.error('重定向后下载失败: $errorMsg, 响应数据: ${redirectResponse.data}');
          }
        } else {
          _log.warning('收到 ${response.statusCode} 重定向响应，但未找到 Location 头');
        }
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final explicitFailure = data is Map && data['success'] == false;
        if (!explicitFailure) {
          Get.back();
          Future.delayed(const Duration(seconds: 1), () {
            ToastUtil.success('下载任务已创建');
          });
        } else {
          final errorMsg = data is Map
              ? data['message'] ?? data['detail'] ?? '下载失败'
              : '下载失败 (HTTP ${response.statusCode})';
          ToastUtil.error(errorMsg.toString());
          _log.error('下载失败: $errorMsg, 响应数据: $data');
        }
      } else {
        final errorMsg = response.data is Map
            ? (response.data as Map)['message'] ??
                  (response.data as Map)['detail'] ??
                  '下载失败 (HTTP ${response.statusCode})'
            : '下载失败 (HTTP ${response.statusCode})';
        ToastUtil.error(errorMsg);
        _log.error('下载失败: $errorMsg, 响应数据: ${response.data}');
      }
    } catch (e, st) {
      if (e is DioException) {
        _log.error(
          '下载 Dio 异常: type=${e.type}, status=${e.response?.statusCode}, '
          'path=${e.requestOptions.uri}, '
          'response=${_shorten(e.response?.data?.toString() ?? '', 500)}',
        );
      }
      _log.handle(e, stackTrace: st, message: '下载失败');
      ToastUtil.error('下载失败，请稍后重试 $e');
    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> startSpecialDownload({
    required BuildContext context,
    required SearchResultItem item,
  }) async {
    final selected = selectedDownloader.value;
    if (selected == null) {
      ToastUtil.error('请选择下载器');
      return;
    }
    final torrent = item.torrent_info;
    final enclosure = torrent?.enclosure?.trim() ?? '';
    if (torrent == null || enclosure.isEmpty) {
      ToastUtil.error('当前资源缺少下载链接，下载器直连下载失败');
      return;
    }

    final downloaderConfig = _buildDownloaderConfig(selected);
    if (downloaderConfig == null) {
      ToastUtil.error('下载器配置不完整或类型不支持');
      return;
    }

    isSpecialDownloading.value = true;
    try {
      _log.info(
        '开始下载器直连下载: site=${torrent.site_name ?? 'unknown'}, '
        'title=${torrent.title ?? ''}, '
        'enclosureMode=${_describeEnclosureMode(enclosure)}',
      );
      final localPath = await _downloadTorrentToLocal(torrent);
      _log.info('下载器直连下载完成，已写入本地临时文件: $localPath');
      if (!context.mounted) return;
      final downloaderController = DownloaderControllerAdaptor.getController(
        downloaderConfig,
      );
      showTorrentDownloadScreen(
        context,
        controller: downloaderController,
        localFilePaths: [localPath],
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '下载器直连下载失败');
      ToastUtil.error('下载器直连下载失败，请稍后重试');
    } finally {
      isSpecialDownloading.value = false;
    }
  }

  DownloaderConfig? _buildDownloaderConfig(DownloadClient selected) {
    final host = selected.config?.host ?? '';
    if (host.isEmpty) return null;
    final type = switch (selected.type.toLowerCase()) {
      'qbittorrent' => DownloaderType.qbittorrent,
      'transmission' => DownloaderType.transmission,
      _ => null,
    };
    if (type == null) return null;
    return DownloaderConfig(
      id: selected.name,
      url: host,
      username: selected.config?.username ?? '',
      password: selected.config?.password ?? '',
      type: type,
      name: selected.name,
    );
  }

  Future<String> _downloadTorrentToLocal(SearchTorrentInfo torrent) async {
    final enclosure = torrent.enclosure?.trim() ?? '';
    if (enclosure.isEmpty) {
      throw Exception('missing enclosure');
    }
    final request = _parseTorrentRequest(torrent);
    _log.info(
      'torrent 下载请求已解析: ${request.describe()} '
      'siteProxy=${torrent.site_proxy ?? false}',
    );
    final data = await _resolveTorrentBytes(torrent, request);
    if (data.isEmpty) {
      throw Exception('empty torrent file');
    }
    final tempDir = await getTemporaryDirectory();
    final fileName = _buildLocalTorrentName(torrent);
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(data, flush: true);
    return file.path;
  }

  String _buildLocalTorrentName(SearchTorrentInfo torrent) {
    final rawTitle = torrent.title?.trim().isNotEmpty == true
        ? torrent.title!.trim()
        : 'moviepilot_torrent';
    final sanitized = rawTitle.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitized}_$timestamp.torrent';
  }

  _TorrentRequest _parseTorrentRequest(SearchTorrentInfo torrent) {
    final enclosure = torrent.enclosure?.trim() ?? '';
    if (!enclosure.startsWith('[')) {
      _log.info('检测到普通 enclosure 直链下载');
      return _TorrentRequest.direct(url: enclosure);
    }

    final closingIndex = enclosure.indexOf(']');
    if (closingIndex <= 1 || closingIndex >= enclosure.length - 1) {
      _log.warning('enclosure 格式异常，回退直链下载: ${_shorten(enclosure, 120)}');
      return _TorrentRequest.direct(url: enclosure);
    }

    final encodedConfig = enclosure.substring(1, closingIndex).trim();
    final requestUrl = enclosure.substring(closingIndex + 1).trim();
    if (encodedConfig.isEmpty || requestUrl.isEmpty) {
      _log.warning('enclosure 配置或 URL 为空，回退直链下载');
      return _TorrentRequest.direct(url: enclosure);
    }

    try {
      final decoded = _decodeBase64ToUtf8(encodedConfig);
      final dynamic json = jsonDecode(decoded);
      if (json is! Map) {
        return _TorrentRequest.direct(url: enclosure);
      }

      final map = Map<String, dynamic>.from(
        json.map((key, value) => MapEntry(key.toString(), value)),
      );
      final request = _TorrentRequest(
        url: requestUrl,
        method: _normalizeHttpMethod(map['method']),
        useCookie: _toBool(map['cookie']) ?? true,
        useProxy: _toBool(map['proxy']) ?? false,
        resultKey: map['result']?.toString().trim(),
        params: _toStringDynamicMap(map['params']),
        headers: _toStringMap(map['header']),
      );
      _log.info('解析 enclosure 成功: ${request.describe()}');
      return request;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '解析 enclosure 请求配置失败，回退直链下载');
      return _TorrentRequest.direct(url: enclosure);
    }
  }

  String _decodeBase64ToUtf8(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '');
    final padded = normalized.padRight(
      normalized.length + ((4 - normalized.length % 4) % 4),
      '=',
    );
    return utf8.decode(base64Decode(padded));
  }

  String _normalizeHttpMethod(Object? value) {
    final method = value?.toString().trim().toUpperCase();
    if (method == 'POST') return 'POST';
    if (method == 'PUT') return 'PUT';
    if (method == 'DELETE') return 'DELETE';
    return 'GET';
  }

  bool? _toBool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  Map<String, dynamic> _toStringDynamicMap(Object? value) {
    if (value is! Map) return const {};
    return Map<String, dynamic>.from(
      value.map((key, item) => MapEntry(key.toString(), item)),
    );
  }

  Map<String, String> _toStringMap(Object? value) {
    if (value is! Map) return const {};
    return Map<String, String>.fromEntries(
      value.entries.map(
        (entry) => MapEntry(entry.key.toString(), entry.value.toString()),
      ),
    );
  }

  Future<List<int>> _resolveTorrentBytes(
    SearchTorrentInfo torrent,
    _TorrentRequest request,
  ) async {
    final dio = Dio(
      BaseOptions(
        responseType: ResponseType.bytes,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 60),
        followRedirects: true,
        validateStatus: (code) => code != null && code >= 200 && code < 400,
      ),
    );

    _log.info('发起第一跳 torrent 请求: ${request.describe()}');
    var response = await _sendTorrentRequest(
      dio: dio,
      request: request,
      headers: _buildTorrentRequestHeaders(torrent, request),
      paramsInQuery: false,
    );
    var payload = response.data ?? const <int>[];
    var contentType = response.headers.value(Headers.contentTypeHeader) ?? '';
    _log.info(
      '第一跳响应: status=${response.statusCode}, '
      'contentType=${contentType.isEmpty ? 'unknown' : contentType}, '
      'bytes=${payload.length}',
    );

    if (_shouldRetryFirstHopWithQueryParams(request, payload)) {
      _log.warning('第一跳疑似参数位置不匹配，准备改用 query 参数重试: ${request.describe()}');
      response = await _sendTorrentRequest(
        dio: dio,
        request: request,
        headers: _buildTorrentRequestHeaders(torrent, request),
        paramsInQuery: true,
      );
      payload = response.data ?? const <int>[];
      contentType = response.headers.value(Headers.contentTypeHeader) ?? '';
      _log.info(
        '第一跳重试响应: status=${response.statusCode}, '
        'contentType=${contentType.isEmpty ? 'unknown' : contentType}, '
        'bytes=${payload.length}',
      );
    }

    if (_looksLikeTorrentBytes(payload, contentType)) {
      _log.info('第一跳响应已识别为 torrent 文件内容');
      return payload;
    }

    final payloadText = _decodeBytesToText(payload);
    _log.info('第一跳响应预览: ${_previewText(payloadText)}');
    final resolvedUrl = _extractDownloadUrl(
      payloadText: payloadText,
      resultKey: request.resultKey,
    );
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      _log.error(
        '未能从第一跳响应中解析出最终下载地址: '
        'resultKey=${request.resultKey ?? 'null'}, '
        'payloadPreview=${_previewText(payloadText)}',
      );
      throw Exception('unable to resolve download url');
    }
    _log.info('已解析最终下载地址: ${_maskUrl(resolvedUrl)}');

    final fileResponse = await dio.get<List<int>>(
      resolvedUrl,
      options: Options(headers: _buildFinalDownloadHeaders(torrent, request)),
    );
    final fileData = fileResponse.data;
    final finalContentType =
        fileResponse.headers.value(Headers.contentTypeHeader) ?? '';
    _log.info(
      '第二跳下载响应: status=${fileResponse.statusCode}, '
      'contentType=${finalContentType.isEmpty ? 'unknown' : finalContentType}, '
      'bytes=${fileData?.length ?? 0}',
    );
    if (fileData == null || fileData.isEmpty) {
      throw Exception('empty torrent file');
    }
    return fileData;
  }

  Future<Response<List<int>>> _sendTorrentRequest({
    required Dio dio,
    required _TorrentRequest request,
    required Map<String, String> headers,
    required bool paramsInQuery,
  }) {
    final options = Options(headers: headers);
    switch (request.method) {
      case 'POST':
        return dio.post<List<int>>(
          request.url,
          data: paramsInQuery ? null : request.params,
          queryParameters: request.params.isEmpty || !paramsInQuery
              ? null
              : request.params,
          options: options,
        );
      case 'PUT':
        return dio.put<List<int>>(
          request.url,
          data: paramsInQuery ? null : request.params,
          queryParameters: request.params.isEmpty || !paramsInQuery
              ? null
              : request.params,
          options: options,
        );
      case 'DELETE':
        return dio.delete<List<int>>(
          request.url,
          data: paramsInQuery || request.params.isEmpty ? null : request.params,
          queryParameters: request.params.isEmpty || !paramsInQuery
              ? null
              : request.params,
          options: options,
        );
      case 'GET':
      default:
        return dio.get<List<int>>(
          request.url,
          queryParameters: request.params.isEmpty ? null : request.params,
          options: options,
        );
    }
  }

  Map<String, String> _buildTorrentRequestHeaders(
    SearchTorrentInfo torrent,
    _TorrentRequest request,
  ) {
    final headers = _buildDefaultTorrentHeaders(
      torrent,
      includeCookie: request.useCookie,
    );
    headers.addAll(request.headers);
    _log.info('第一跳请求头摘要: ${_summarizeHeaders(headers)}');
    return headers;
  }

  Map<String, String> _buildFinalDownloadHeaders(
    SearchTorrentInfo torrent,
    _TorrentRequest request,
  ) {
    final headers = _buildDefaultTorrentHeaders(
      torrent,
      includeCookie: request.useCookie,
    );
    _log.info('第二跳请求头摘要: ${_summarizeHeaders(headers)}');
    return headers;
  }

  Map<String, String> _buildDefaultTorrentHeaders(
    SearchTorrentInfo torrent, {
    required bool includeCookie,
  }) {
    final headers = <String, String>{};
    final cookie = torrent.site_cookie?.trim();
    final ua = torrent.site_ua?.trim();
    final referer = torrent.page_url?.trim();
    if (includeCookie && cookie != null && cookie.isNotEmpty) {
      headers['cookie'] = cookie;
    }
    if (ua != null && ua.isNotEmpty) {
      headers['user-agent'] = ua;
    }
    if (referer != null && referer.isNotEmpty) {
      headers['referer'] = referer;
    }
    return headers;
  }

  bool _looksLikeTorrentBytes(List<int> bytes, String contentType) {
    if (bytes.isEmpty) return false;
    final normalizedType = contentType.toLowerCase();
    final text = _decodeBytesToText(bytes);
    final trimmed = text.trim();
    if (_looksLikeHttpUrl(trimmed)) {
      return false;
    }
    if (_looksLikeJsonOrText(bytes)) {
      return false;
    }
    if (normalizedType.contains('application/x-bittorrent')) {
      return true;
    }
    if (normalizedType.contains('application/octet-stream')) {
      return true;
    }
    return _looksLikeTorrentStructure(text);
  }

  bool _shouldRetryFirstHopWithQueryParams(
    _TorrentRequest request,
    List<int> payload,
  ) {
    if (request.params.isEmpty) return false;
    if (request.method != 'POST' &&
        request.method != 'PUT' &&
        request.method != 'DELETE') {
      return false;
    }
    final payloadText = _decodeBytesToText(payload);
    final trimmed = payloadText.trim();
    if (trimmed.isEmpty) return false;

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return false;
    }
    if (decoded is! Map) return false;
    final message = decoded['message']?.toString().trim() ?? '';
    return message.contains('參數錯誤') || message.contains('参数错误');
  }

  bool _looksLikeJsonOrText(List<int> bytes) {
    final text = _decodeBytesToText(bytes).trimLeft();
    if (text.isEmpty) return false;
    return text.startsWith('{') ||
        text.startsWith('[') ||
        text.startsWith('"') ||
        text.startsWith('<') ||
        text.startsWith('data:');
  }

  String _decodeBytesToText(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  bool _looksLikeTorrentStructure(String text) {
    if (text.isEmpty) return false;
    return text.startsWith('d') &&
        (text.contains('announce') ||
            text.contains('creation date') ||
            text.contains('info'));
  }

  String? _extractDownloadUrl({
    required String payloadText,
    String? resultKey,
  }) {
    final trimmed = payloadText.trim();
    if (trimmed.isEmpty) return null;
    if (_looksLikeHttpUrl(trimmed)) {
      return trimmed;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return null;
    }

    final dynamic candidate =
        _extractNestedValue(decoded, resultKey) ??
        _extractNestedValue(decoded, 'data') ??
        _extractNestedValue(decoded, 'url') ??
        _extractNestedValue(decoded, 'download_url') ??
        _extractNestedValue(decoded, 'downloadUrl') ??
        _extractNestedValue(decoded, 'link');
    return _stringifyDownloadUrl(candidate);
  }

  dynamic _extractNestedValue(dynamic source, String? path) {
    if (path == null || path.trim().isEmpty) return null;
    dynamic current = source;
    for (final segment in path.split('.')) {
      if (current is Map) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  String? _stringifyDownloadUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return _looksLikeHttpUrl(trimmed) ? trimmed : null;
    }
    if (value is Map) {
      for (final key in const [
        'url',
        'download_url',
        'downloadUrl',
        'link',
        'data',
      ]) {
        final nested = _stringifyDownloadUrl(value[key]);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  bool _looksLikeHttpUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String _describeEnclosureMode(String enclosure) {
    return enclosure.startsWith('[') ? 'encoded-request' : 'direct-url';
  }

  String _summarizeHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return '{}';
    final entries = headers.entries
        .map((entry) {
          final key = entry.key;
          final lowerKey = key.toLowerCase();
          final value = entry.value;
          if (lowerKey == 'cookie') {
            return '$key=<present:${value.length} chars>';
          }
          if (lowerKey == 'authorization' || lowerKey == 'x-api-key') {
            return '$key=${_maskSecret(value)}';
          }
          return '$key=${_shorten(value, 80)}';
        })
        .join(', ');
    return '{$entries}';
  }

  String _previewText(String text) {
    if (text.isEmpty) return '<empty>';
    return _shorten(text.replaceAll(RegExp(r'\s+'), ' ').trim(), 240);
  }

  String _shorten(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  String _maskSecret(String value) {
    if (value.isEmpty) return '<empty>';
    if (value.length <= 8) return '<hidden>';
    return '${value.substring(0, 4)}***${value.substring(value.length - 4)}';
  }

  String _maskUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return _shorten(value, 120);
    final sanitizedQuery = uri.queryParameters.keys.join('&');
    final suffix = sanitizedQuery.isEmpty ? '' : '?$sanitizedQuery';
    return '${uri.scheme}://${uri.host}${uri.path}$suffix';
  }

  void setDownloader(DownloadClient? downloader) {
    selectedDownloader.value = downloader;
    _preferredDownloaderName = downloader?.name;
    unawaited(_persistSheetSelections());
  }

  void setDirectory(String directory) {
    selectedDirectory.value = directory;
    _preferredDirectory = directory;
    unawaited(_persistSheetSelections());
  }

  void setTmdbId(String id) {
    tmdbId.value = id;
  }

  void resetSheetTransientState() {
    tmdbId.value = '';
    showAdvanced.value = false;
  }
}

class _TorrentRequest {
  const _TorrentRequest({
    required this.url,
    required this.method,
    required this.useCookie,
    required this.useProxy,
    required this.params,
    required this.headers,
    this.resultKey,
  });

  factory _TorrentRequest.direct({required String url}) {
    return _TorrentRequest(
      url: url,
      method: 'GET',
      useCookie: true,
      useProxy: false,
      params: const {},
      headers: const {},
    );
  }

  final String url;
  final String method;
  final bool useCookie;
  final bool useProxy;
  final Map<String, dynamic> params;
  final Map<String, String> headers;
  final String? resultKey;

  String describe() {
    final paramsSummary = params.isEmpty ? '{}' : params.toString();
    final headerKeys = headers.keys.isEmpty
        ? '[]'
        : headers.keys.toList().toString();
    return 'method=$method, '
        'url=$url, '
        'useCookie=$useCookie, '
        'useProxy=$useProxy, '
        'resultKey=${resultKey ?? 'null'}, '
        'params=$paramsSummary, '
        'headerKeys=$headerKeys';
  }
}
