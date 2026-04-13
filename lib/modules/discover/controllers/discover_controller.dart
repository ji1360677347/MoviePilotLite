import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/discover/defines/discover_filter_defines.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_filters.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search/services/search_keyword_hints_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

enum DiscoverSource {
  tmdb('TheMovieDB'),
  douban('豆瓣'),
  bangumi('Bangumi');

  const DiscoverSource(this.label);

  final String label;
}

class DiscoverController extends GetxController {
  static const Duration _minRefreshInterval = Duration(seconds: 30);
  static const Duration _forceRefreshInterval = Duration(seconds: 10);
  static const Duration _throttleGap = Duration(milliseconds: 350);

  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.find<AuthRepository>();
  final _appService = Get.find<AppService>();

  final selectedSource = DiscoverSource.tmdb.obs;
  final filters = const DiscoverFilters().obs;
  final _filtersBySource = <DiscoverSource, DiscoverFilters>{};

  final itemsByKey = <String, List<RecommendApiItem>>{}.obs;
  final isLoadingByKey = <String, bool>{}.obs;
  final errorByKey = <String, String?>{}.obs;

  Future<void> _requestQueue = Future.value();
  final _pendingKeys = <String>{};
  final Map<String, DateTime> _lastFetchAt = {};
  bool _suspendAutoLoad = false;
  bool _cookieRefreshTriggered = false;

  @override
  void onInit() {
    super.onInit();
    _bootstrapFilters();
    loadCurrent();
    ever(selectedSource, (_) {
      if (_suspendAutoLoad) return;
      loadCurrent(forceRefresh: true);
    });
    ever(filters, (_) {
      if (_suspendAutoLoad) return;
      loadCurrent(forceRefresh: true);
    });
  }

  void selectSource(DiscoverSource source) {
    if (selectedSource.value == source) return;
    selectedSource.value = source;
    final next = _filtersBySource[source] ?? _defaultFiltersFor(source);
    _filtersBySource[source] = next;
    filters.value = next;
  }

  void updateFilters(DiscoverFilters next) {
    filters.value = next;
    _filtersBySource[selectedSource.value] = next;
  }

  void ensureUserCookieRefreshed() {
    if (_cookieRefreshTriggered) return;
    _cookieRefreshTriggered = true;
    _refreshUserCookie();
  }

  Future<void> _refreshUserCookie() async {
    final server = _appService.baseUrl ?? _apiClient.baseUrl;
    final token =
        _appService.loginResponse?.accessToken ??
        _appService.latestLoginProfileAccessToken ??
        _apiClient.token;
    if (server == null || server.isEmpty || token == null || token.isEmpty) {
      return;
    }
    try {
      await _authRepository.getUserGlobalConfig(
        server: server,
        accessToken: token,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刷新探索 Cookie 失败');
    }
  }

  Map<DiscoverSource, DiscoverFilters> snapshotFiltersBySource() {
    final snapshot = <DiscoverSource, DiscoverFilters>{};
    for (final source in DiscoverSource.values) {
      snapshot[source] = _filtersBySource[source] ?? _defaultFiltersFor(source);
    }
    return snapshot;
  }

  void applySelection(
    DiscoverSource source,
    Map<DiscoverSource, DiscoverFilters> filtersBySource,
  ) {
    _suspendAutoLoad = true;
    _filtersBySource
      ..clear()
      ..addAll(filtersBySource);
    selectedSource.value = source;
    filters.value = filtersBySource[source] ?? _defaultFiltersFor(source);
    _suspendAutoLoad = false;
    loadCurrent(forceRefresh: true);
  }

  List<RecommendApiItem> currentItems() {
    final key = _cacheKey(selectedSource.value, filters.value);
    return itemsByKey[key] ?? const [];
  }

  bool isLoading() {
    final key = _cacheKey(selectedSource.value, filters.value);
    return isLoadingByKey[key] ?? false;
  }

  String? errorText() {
    final key = _cacheKey(selectedSource.value, filters.value);
    return errorByKey[key];
  }

  void loadCurrent({bool forceRefresh = false}) {
    final source = selectedSource.value;
    final filter = filters.value;
    final key = _cacheKey(source, filter);

    final hasCache = itemsByKey.containsKey(key);
    if (hasCache) {
      final shouldRefresh = forceRefresh
          ? _shouldForceRefresh(key)
          : _shouldRefresh(key);
      if (!shouldRefresh) return;
    }

    _enqueueFetch(source, filter, key);
  }

  void _enqueueFetch(
    DiscoverSource source,
    DiscoverFilters filter,
    String key,
  ) {
    if (_pendingKeys.contains(key)) return;
    _pendingKeys.add(key);
    _requestQueue = _requestQueue
        .then((_) async {
          try {
            await _fetch(source, filter, key);
          } finally {
            _pendingKeys.remove(key);
            await Future.delayed(_throttleGap);
          }
        })
        .catchError((error, stack) {
          _log.handle(error, stackTrace: stack, message: '探索请求队列异常');
        });
  }

  Future<void> _fetch(
    DiscoverSource source,
    DiscoverFilters filter,
    String key,
  ) async {
    isLoadingByKey[key] = true;
    errorByKey[key] = null;
    isLoadingByKey.refresh();
    errorByKey.refresh();

    try {
      final endpoint = _endpointFor(source, filter);
      final path = '/api/v1/discover/$endpoint';
      final query = _buildQueryParams(source, filter);
      _log.info('探索请求: $path, $query');
      final response = await _apiClient.get<dynamic>(
        path,
        queryParameters: query,
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        errorByKey[key] = '请求失败 (HTTP $statusCode)';
        return;
      }

      final payload = _decodePayload(response.data);
      final list = _extractList(payload);
      final items = _parseItems(
        list,
        fallbackMediaType: filter.mediaType.isNotEmpty
            ? filter.mediaType
            : source.label,
      );
      ensureUserCookieRefreshed();
      itemsByKey[key] = items;
      itemsByKey.refresh();
      _lastFetchAt[key] = DateTime.now();
      unawaited(Get.find<SearchKeywordHintsService>().ingestFromItems(items));
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '探索数据请求异常');
      errorByKey[key] = '请求异常';
    } finally {
      isLoadingByKey[key] = false;
      isLoadingByKey.refresh();
    }
  }

  bool _shouldRefresh(String key) {
    final last = _lastFetchAt[key];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minRefreshInterval;
  }

  bool _shouldForceRefresh(String key) {
    final last = _lastFetchAt[key];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _forceRefreshInterval;
  }

  String _cacheKey(DiscoverSource source, DiscoverFilters filter) {
    final endpoint = _endpointFor(source, filter);
    return '${source.name}|$endpoint|${_signatureFor(source, filter)}';
  }

  void _bootstrapFilters() {
    for (final source in DiscoverSource.values) {
      _filtersBySource[source] = _defaultFiltersFor(source);
    }
    filters.value = _filtersBySource[selectedSource.value]!;
  }

  DiscoverFilters _defaultFiltersFor(DiscoverSource source) {
    switch (source) {
      case DiscoverSource.tmdb:
        return const DiscoverFilters(
          mediaType: '电影',
          sortBy: 'popularity.desc',
          voteAverage: 0,
        );
      case DiscoverSource.douban:
        return const DiscoverFilters(mediaType: '电影', sortBy: 'U');
      case DiscoverSource.bangumi:
        return const DiscoverFilters(
          mediaType: '',
          bangumiCategory: '',
          sortBy: 'rank',
        );
    }
  }

  String _endpointFor(DiscoverSource source, DiscoverFilters filter) {
    switch (source) {
      case DiscoverSource.tmdb:
        return _isTvType(filter.mediaType) ? 'tmdb_tvs' : 'tmdb_movies';
      case DiscoverSource.douban:
        return _isTvType(filter.mediaType) ? 'douban_tvs' : 'douban_movies';
      case DiscoverSource.bangumi:
        return 'bangumi';
    }
  }

  bool _isTvType(String mediaType) {
    final normalized = mediaType.trim();
    if (normalized.isEmpty) return false;
    return normalized == '电视剧';
  }

  Map<String, String> _buildQueryParams(
    DiscoverSource source,
    DiscoverFilters filter,
  ) {
    if (source == DiscoverSource.douban) {
      return _buildDoubanQuery(filter);
    }
    final options = _queryOptionsFor(source, filter);
    return filter.toQueryParameters(
      useOriginCountry: options.useOriginCountry,
      useProductionCountries: options.useProductionCountries,
    );
  }

  String _signatureFor(DiscoverSource source, DiscoverFilters filter) {
    final params = _buildQueryParams(source, filter);
    final keys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      buffer.write('$key=${params[key]};');
    }
    return buffer.toString();
  }

  _QueryOptions _queryOptionsFor(
    DiscoverSource source,
    DiscoverFilters filter,
  ) {
    if (source == DiscoverSource.tmdb) {
      final isTv = _isTvType(filter.mediaType);
      return _QueryOptions(
        useOriginCountry: isTv,
        useProductionCountries: !isTv,
      );
    }
    return const _QueryOptions();
  }

  Map<String, String> _buildDoubanQuery(DiscoverFilters filter) {
    final tags = <String>[];
    tags.addAll(
      _labelsForValues(
        filter.selectedGenres,
        DiscoverFilterDefines.doubanGenreOptions,
      ),
    );
    tags.addAll(
      _labelsForValues(
        filter.selectedRegions,
        DiscoverFilterDefines.regionOptions,
      ),
    );
    final decadeLabel = _labelForValue(
      filter.selectedDecade,
      DiscoverFilterDefines.decadeOptions,
    );
    if (decadeLabel.isNotEmpty) {
      tags.add(decadeLabel);
    }
    final sort = _mapDoubanSort(filter.sortBy);
    final params = <String, String>{
      'page': filter.page.toString(),
      'sort': sort,
    };
    if (tags.isNotEmpty) {
      params['tags'] = tags.join(',');
    }
    return params;
  }

  String _mapDoubanSort(String value) {
    switch (value) {
      case 'U':
      case 'R':
      case 'T':
      case 'S':
        return value;
      case 'comprehensive':
        return 'U';
      case 'release_date.desc':
        return 'R';
      case 'popularity.desc':
        return 'T';
      case 'vote_average.desc':
        return 'S';
      default:
        return value.isEmpty ? 'U' : value;
    }
  }

  List<String> _labelsForValues(
    List<String> values,
    List<DiscoverFilterOption> options,
  ) {
    if (values.isEmpty) return const [];
    final map = {for (final option in options) option.value: option.label};
    return values.map((value) => map[value] ?? value).toList();
  }

  String _labelForValue(String value, List<DiscoverFilterOption> options) {
    if (value.isEmpty) return '';
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  dynamic _decodePayload(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = _toStringKeyMap(payload);
      final candidates = <String>[
        'data',
        'results',
        'items',
        'list',
        'subjects',
        'subject',
        'rows',
      ];
      for (final key in candidates) {
        final value = map[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
      for (final entry in map.values) {
        if (entry is List) return entry;
        if (entry is Map) {
          final nested = _extractList(entry);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _toStringKeyMap(Map<dynamic, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (key is String) {
        result[key] = value;
      }
    });
    return result;
  }

  List<RecommendApiItem> _parseItems(
    List<dynamic> rawList, {
    required String fallbackMediaType,
  }) {
    final items = <RecommendApiItem>[];
    for (var i = 0; i < rawList.length; i++) {
      final raw = rawList[i];
      if (raw is! Map) continue;
      final map = _toStringKeyMap(raw);
      try {
        final apiItem = RecommendApiItem.fromJson(map);
        final patched = (apiItem.type == null || apiItem.type!.isEmpty)
            ? apiItem.copyWith(type: fallbackMediaType)
            : apiItem;
        items.add(patched);
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '解析探索条目失败');
      }
    }
    return items;
  }
}

class _QueryOptions {
  const _QueryOptions({
    this.useOriginCountry = false,
    this.useProductionCountries = false,
  });

  final bool useOriginCountry;
  final bool useProductionCountries;
}
