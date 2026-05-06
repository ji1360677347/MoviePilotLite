import 'package:freezed_annotation/freezed_annotation.dart';

part 'recognize_model.freezed.dart';
part 'recognize_model.g.dart';

@freezed
class RecognizeResponse with _$RecognizeResponse {
  const factory RecognizeResponse({
    @JsonKey(name: 'meta_info') MetaInfo? meta_info,
    @JsonKey(name: 'media_info') MediaInfo? media_info,
    @JsonKey(name: 'torrent_info') TorrentInfo? torrent_info,
  }) = _RecognizeResponse;

  factory RecognizeResponse.fromJson(Map<String, dynamic> json) =>
      _$RecognizeResponseFromJson(json);
}

@freezed
class MetaInfo with _$MetaInfo {
  const factory MetaInfo({
    bool? isfile,
    String? org_string,
    String? title,
    String? subtitle,
    String? type,
    String? name,
    String? cn_name,
    String? en_name,
    String? year,
    @JsonKey(fromJson: _intFromJson) int? total_season,
    @JsonKey(fromJson: _intFromJson) int? begin_season,
    @JsonKey(fromJson: _intFromJson) int? end_season,
    @JsonKey(fromJson: _intFromJson) int? total_episode,
    @JsonKey(fromJson: _intFromJson) int? begin_episode,
    @JsonKey(fromJson: _intFromJson) int? end_episode,
    String? season_episode,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_list,
    String? part,
    String? resource_type,
    String? resource_effect,
    String? resource_pix,
    String? resource_team,
    String? video_encode,
    String? audio_encode,
    String? edition,
    String? web_source,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? apply_words,
  }) = _MetaInfo;

  factory MetaInfo.fromJson(Map<String, dynamic> json) =>
      _$MetaInfoFromJson(json);
}

@freezed
class MediaInfo with _$MediaInfo {
  const factory MediaInfo({
    String? source,
    String? type,
    String? title,
    String? en_title,
    String? year,
    String? title_year,
    @JsonKey(fromJson: _intFromJson) int? season,
    @JsonKey(fromJson: _intFromJson) int? tmdb_id,
    String? imdb_id,
    @JsonKey(fromJson: _intFromJson) int? tvdb_id,
    @JsonKey(fromJson: _intFromJson) int? douban_id,
    @JsonKey(fromJson: _intFromJson) int? bangumi_id,
    @JsonKey(fromJson: _intFromJson) int? collection_id,
    String? mediaid_prefix,
    String? media_id,
    String? original_language,
    String? original_title,
    String? release_date,
    String? backdrop_path,
    String? poster_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    String? overview,
    String? category,
    @JsonKey(fromJson: _seasonsFromJson, toJson: _seasonsToJson)
    List<SeasonEpisodes>? seasons,
    List<SeasonInfo>? season_info,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? names,
    List<Actor>? actors,
    List<Director>? directors,
    String? detail_link,
    bool? adult,
    List<CreatedBy>? created_by,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? episode_run_time,
    List<Genre>? genres,
    String? first_air_date,
    String? homepage,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? languages,
    String? last_air_date,
    List<Network>? networks,
    @JsonKey(fromJson: _intFromJson) int? number_of_episodes,
    @JsonKey(fromJson: _intFromJson) int? number_of_seasons,
    @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
    List<String>? origin_country,
    String? original_name,
    List<ProductionCompany>? production_companies,
    List<ProductionCountry>? production_countries,
    List<SpokenLanguage>? spoken_languages,
    List<ReleaseDate>? release_dates,
    String? status,
    String? tagline,
    @JsonKey(fromJson: _intListFromJson, toJson: _intListToJson)
    List<int>? genre_ids,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    @JsonKey(fromJson: _intFromJson) int? runtime,
    @JsonKey(fromJson: _nextEpisodeFromJson, toJson: _nextEpisodeToJson)
    NextEpisodeToAir? next_episode_to_air,
    @JsonKey(fromJson: _episodeGroupsFromJson, toJson: _episodeGroupsToJson)
    List<EpisodeGroup>? episode_groups,
    @JsonKey(fromJson: _episodeGroupFromJson, toJson: _episodeGroupToJson)
    EpisodeGroup? episode_group,
  }) = _MediaInfo;

  factory MediaInfo.fromJson(Map<String, dynamic> json) =>
      _$MediaInfoFromJson(json);
}

@freezed
class SeasonEpisodes with _$SeasonEpisodes {
  const factory SeasonEpisodes({
    required int season,
    required List<int> episodes,
  }) = _SeasonEpisodes;

  factory SeasonEpisodes.fromJson(Map<String, dynamic> json) =>
      _$SeasonEpisodesFromJson(json);
}

@freezed
class SeasonInfo with _$SeasonInfo {
  const factory SeasonInfo({
    String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? overview,
    String? poster_path,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
  }) = _SeasonInfo;

  factory SeasonInfo.fromJson(Map<String, dynamic> json) =>
      _$SeasonInfoFromJson(json);
}

@freezed
class Actor with _$Actor {
  const factory Actor({
    String? source,
    bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? known_for_department,
    String? name,
    String? original_name,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    String? profile_path,
    String? character,
    String? credit_id,
    @JsonKey(fromJson: _intFromJson) int? order,
  }) = _Actor;

  factory Actor.fromJson(Map<String, dynamic> json) => _$ActorFromJson(json);
}

@freezed
class Director with _$Director {
  const factory Director({
    bool? adult,
    @JsonKey(fromJson: _intFromJson) int? gender,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? original_name,
    String? credit_id,
    String? known_for_department,
    String? job,
    @JsonKey(fromJson: _doubleFromJson) double? popularity,
    String? profile_path,
  }) = _Director;

  factory Director.fromJson(Map<String, dynamic> json) =>
      _$DirectorFromJson(json);
}

@freezed
class CreatedBy with _$CreatedBy {
  const factory CreatedBy({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? credit_id,
    String? name,
    String? original_name,
    @JsonKey(fromJson: _intFromJson) int? gender,
    String? profile_path,
  }) = _CreatedBy;

  factory CreatedBy.fromJson(Map<String, dynamic> json) =>
      _$CreatedByFromJson(json);
}

@freezed
class Genre with _$Genre {
  const factory Genre({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
  }) = _Genre;

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
}

@freezed
class Network with _$Network {
  const factory Network({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  }) = _Network;

  factory Network.fromJson(Map<String, dynamic> json) =>
      _$NetworkFromJson(json);
}

@freezed
class ProductionCompany with _$ProductionCompany {
  const factory ProductionCompany({
    @JsonKey(fromJson: _intFromJson) int? id,
    String? logo_path,
    String? name,
    String? origin_country,
  }) = _ProductionCompany;

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      _$ProductionCompanyFromJson(json);
}

@freezed
class ProductionCountry with _$ProductionCountry {
  const factory ProductionCountry({String? iso_3166_1, String? name}) =
      _ProductionCountry;

  factory ProductionCountry.fromJson(Map<String, dynamic> json) =>
      _$ProductionCountryFromJson(json);
}

@freezed
class SpokenLanguage with _$SpokenLanguage {
  const factory SpokenLanguage({
    String? english_name,
    String? iso_639_1,
    String? name,
  }) = _SpokenLanguage;

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) =>
      _$SpokenLanguageFromJson(json);
}

@freezed
class ReleaseDate with _$ReleaseDate {
  const factory ReleaseDate({
    String? certification,
    String? iso_3166_1,
    String? release_date,
    String? note,
    @JsonKey(fromJson: _intFromJson) int? type,
  }) = _ReleaseDate;

  factory ReleaseDate.fromJson(Map<String, dynamic> json) =>
      _$ReleaseDateFromJson(json);
}

@freezed
class EpisodeGroup with _$EpisodeGroup {
  const factory EpisodeGroup({
    @JsonKey(fromJson: _stringFromJson) String? id,
    String? name,
    String? description,
    @JsonKey(fromJson: _intFromJson) int? episode_count,
    @JsonKey(fromJson: _intFromJson) int? group_count,
    String? type,
    @JsonKey(fromJson: _networkFromJson, toJson: _networkToJson)
    Network? network,
  }) = _EpisodeGroup;

  factory EpisodeGroup.fromJson(Map<String, dynamic> json) =>
      _$EpisodeGroupFromJson(json);
}

@freezed
class NextEpisodeToAir with _$NextEpisodeToAir {
  const factory NextEpisodeToAir({
    String? air_date,
    @JsonKey(fromJson: _intFromJson) int? episode_number,
    @JsonKey(fromJson: _intFromJson) int? id,
    String? name,
    String? overview,
    String? production_code,
    @JsonKey(fromJson: _intFromJson) int? season_number,
    String? still_path,
    @JsonKey(fromJson: _doubleFromJson) double? vote_average,
    @JsonKey(fromJson: _intFromJson) int? vote_count,
    @JsonKey(fromJson: _intFromJson) int? runtime,
  }) = _NextEpisodeToAir;

  factory NextEpisodeToAir.fromJson(Map<String, dynamic> json) =>
      _$NextEpisodeToAirFromJson(json);
}

@freezed
class TorrentInfo with _$TorrentInfo {
  const factory TorrentInfo() = _TorrentInfo;

  factory TorrentInfo.fromJson(Map<String, dynamic> json) =>
      _$TorrentInfoFromJson(json);
}

int? _intFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _stringFromJson(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

double? _doubleFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<int> _intListFromJson(Object? value) {
  if (value is List) {
    return value.map((item) => _intFromJson(item)).whereType<int>().toList();
  }
  return const [];
}

List<int>? _intListToJson(List<int>? value) => value;

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value
        .map((item) => _stringFromJson(item))
        .whereType<String>()
        .toList();
  }
  return const [];
}

List<String>? _stringListToJson(List<String>? value) => value;

List<SeasonEpisodes> _seasonsFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    final items = <SeasonEpisodes>[];
    value.forEach((key, rawEpisodes) {
      final season = _intFromJson(key) ?? int.tryParse(key) ?? 0;
      final episodes = _intListFromJson(rawEpisodes);
      items.add(SeasonEpisodes(season: season, episodes: episodes));
    });
    items.sort((a, b) => a.season.compareTo(b.season));
    return items;
  }
  return const [];
}

Map<String, dynamic> _seasonsToJson(List<SeasonEpisodes>? seasons) {
  final result = <String, dynamic>{};
  if (seasons == null) return result;
  for (final item in seasons) {
    result[item.season.toString()] = item.episodes;
  }
  return result;
}

NextEpisodeToAir? _nextEpisodeFromJson(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) {
    if (value.isEmpty) return null;
    return NextEpisodeToAir.fromJson(value);
  }
  return null;
}

Map<String, dynamic>? _nextEpisodeToJson(NextEpisodeToAir? value) =>
    value?.toJson();

List<EpisodeGroup> _episodeGroupsFromJson(Object? value) {
  if (value is! List) return const [];
  final groups = <EpisodeGroup>[];
  for (final item in value) {
    final group = _episodeGroupFromJson(item);
    if (group != null) {
      groups.add(group);
    }
  }
  return groups;
}

List<Map<String, dynamic>>? _episodeGroupsToJson(List<EpisodeGroup>? value) =>
    value?.map((item) => item.toJson()).toList();

EpisodeGroup? _episodeGroupFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    if (value.isEmpty) return null;
    return EpisodeGroup.fromJson(value);
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    if (map.isEmpty) return null;
    return EpisodeGroup.fromJson(map);
  }
  return null;
}

Map<String, dynamic>? _episodeGroupToJson(EpisodeGroup? value) =>
    value?.toJson();

Network? _networkFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    if (value.isEmpty) return null;
    return Network.fromJson(value);
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    if (map.isEmpty) return null;
    return Network.fromJson(map);
  }
  return null;
}

Map<String, dynamic>? _networkToJson(Network? value) => value?.toJson();
