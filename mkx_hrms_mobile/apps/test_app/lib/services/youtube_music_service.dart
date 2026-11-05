import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/song_model.dart';

/// Service responsible for querying YouTube Data API v3 and extracting stream URLs.
class YouTubeMusicService {
  /// User's official Google Cloud YouTube Data API Key.
  static const String apiKey = 'AIzaSyDtpfYFpiXhtC1gnxT9TkeyHnn5ePBZhRE';

  /// Base URL for YouTube Data API v3.
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  /// Instance of YoutubeExplode for fallback search when API quota is exceeded.
  final YoutubeExplode _ytExplode = YoutubeExplode();

  /// Searches for music tracks using YouTube Data API v3 with automatic fallback.
  /// Searches YouTube Data API v3 for songs matching the query, prioritizing official releases.
  Future<List<SongModel>> searchMusic(
    String query, {
    int maxResults = 25,
  }) async {
    final effectiveQuery = query.toLowerCase().contains('official')
        ? query
        : '$query official';

    try {
      final uri = Uri.parse(
        '$_baseUrl/search'
        '?part=snippet'
        '&maxResults=$maxResults'
        '&q=${Uri.encodeComponent(effectiveQuery)}'
        '&type=video'
        '&videoEmbeddable=true'
        '&videoSyndicated=true'
        '&key=$apiKey',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"items":[]}', 408),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map && data['items'] is List) {
          final items = data['items'] as List;
          final results = items
              .whereType<Map>()
              .map((item) => SongModel.fromYouTubeMap(item))
              .where((song) => song.id.isNotEmpty)
              .toList();

          final officialResults = results.where(_isOfficialMusic).toList();
          if (officialResults.isNotEmpty) return officialResults;
          if (results.isNotEmpty) return results;
        }
      }

      /// Retry with general video search if needed
      final retryUri = Uri.parse(
        '$_baseUrl/search'
        '?part=snippet'
        '&maxResults=$maxResults'
        '&q=${Uri.encodeComponent('$query official song')}'
        '&type=video'
        '&videoEmbeddable=true'
        '&videoSyndicated=true'
        '&key=$apiKey',
      );

      final retryResponse = await http.get(retryUri).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('{"items":[]}', 408),
      );

      if (retryResponse.statusCode == 200) {
        final dynamic data = json.decode(retryResponse.body);
        if (data is Map && data['items'] is List) {
          final items = data['items'] as List;
          final results = items
              .whereType<Map>()
              .map((item) => SongModel.fromYouTubeMap(item))
              .where((song) => song.id.isNotEmpty)
              .toList();

          final officialResults = results.where(_isOfficialMusic).toList();
          if (officialResults.isNotEmpty) return officialResults;
          if (results.isNotEmpty) return results;
        }
      }

      return await _fallbackExplodeSearch(effectiveQuery);
    } catch (_) {
      return await _fallbackExplodeSearch(effectiveQuery);
    }
  }

  /// Filters out fan-made re-uploads, slowed+reverb edits, whatsapp status clips, etc.
  static bool _isOfficialMusic(SongModel song) {
    final title = song.title.toLowerCase();

    const unofficialKeywords = [
      'slowed',
      'reverb',
      '8d audio',
      'whatsapp status',
      'status video',
      'ringtone',
      'bass boosted',
      'cover by',
      'dance cover',
      'reaction',
      'short',
      'shorts',
      'karaoke',
      'instrumental cover',
      'nightcore',
      'mashup by',
      'parody',
      'ai cover',
      'fan made',
    ];

    for (final term in unofficialKeywords) {
      if (title.contains(term)) return false;
    }

    return true;
  }

  /// In-memory cache for trending tracks.
  List<SongModel> _cachedTrending = [];

  /// Getter for cached trending tracks.
  List<SongModel> get cachedTrending => List.unmodifiable(_cachedTrending);

  /// Fetches top trending music tracks dynamically from YouTube Data API v3.
  Future<List<SongModel>> getTrendingMusic({int maxResults = 25}) async {
    /// 1. Primary: Official mostPopular trending music chart for user region (IN)
    try {
      final uri = Uri.parse(
        '$_baseUrl/videos'
        '?part=snippet'
        '&chart=mostPopular'
        '&videoCategoryId=10'
        '&regionCode=IN'
        '&maxResults=$maxResults'
        '&key=$apiKey',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('{"items":[]}', 408),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map && data['items'] is List) {
          final items = data['items'] as List;
          final songs = items
              .whereType<Map>()
              .map((item) => SongModel.fromYouTubeMap(item))
              .where((song) => song.id.isNotEmpty)
              .where(_isOfficialMusic)
              .toList();

          if (songs.isNotEmpty) {
            _cachedTrending = songs;
            return songs;
          }
        }
      }
    } catch (_) {}

    /// 2. Secondary: Global mostPopular trending music chart
    try {
      final uri = Uri.parse(
        '$_baseUrl/videos'
        '?part=snippet'
        '&chart=mostPopular'
        '&videoCategoryId=10'
        '&maxResults=$maxResults'
        '&key=$apiKey',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('{"items":[]}', 408),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map && data['items'] is List) {
          final items = data['items'] as List;
          final songs = items
              .whereType<Map>()
              .map((item) => SongModel.fromYouTubeMap(item))
              .where((song) => song.id.isNotEmpty)
              .where(_isOfficialMusic)
              .toList();

          if (songs.isNotEmpty) {
            _cachedTrending = songs;
            return songs;
          }
        }
      }
    } catch (_) {}

    /// 3. Fallback: Search for official trending hits in Hindi, English, Punjabi, Haryanvi
    final fallbackSongs = await searchMusic(
      'official hindi english punjabi haryanvi hit songs',
      maxResults: maxResults,
    );
    if (fallbackSongs.isNotEmpty) {
      _cachedTrending = fallbackSongs;
    }
    return fallbackSongs;
  }

  /// Dynamic in-memory category cache ensuring fast subsequent access.
  final Map<String, List<SongModel>> _categoryCache = {};

  /// Dynamically queries YouTube Data API v3 for songs matching the selected category.
  Future<List<SongModel>> getCategoryMusic(
    String category, {
    int maxResults = 25,
  }) async {
    if (_categoryCache.containsKey(category) &&
        _categoryCache[category]!.isNotEmpty) {
      return _categoryCache[category]!;
    }

    final query = _categoryToQuery(category);
    final songs = await searchMusic(query, maxResults: maxResults);
    if (songs.isNotEmpty) {
      _categoryCache[category] = songs;
    }
    return songs;
  }

  /// Maps category name to optimal official YouTube search keywords.
  String _categoryToQuery(String category) {
    switch (category) {
      case 'All':
        return 'official hindi english punjabi haryanvi hit songs';
      case 'Hindi':
      case 'Hindi Official':
        return 'official hindi bollywood hit songs';
      case 'English':
      case 'English Hits':
        return 'official english billboard pop songs';
      case 'Punjabi':
      case 'Punjabi Hits':
        return 'official punjabi hit songs';
      case 'Haryanvi':
      case 'Haryanvi Dhaakad':
        return 'official haryanvi hit songs';
      case 'Bollywood Romance':
        return 'official romantic bollywood hindi songs';
      case 'Global Billboard':
        return 'official english global billboard top songs';
      case 'Punjabi Bhangra':
        return 'official punjabi bhangra party songs';
      case 'Haryanvi Folk & Beats':
        return 'official haryanvi hit ragni beats songs';
      default:
        return 'official $category songs';
    }
  }

  /// Fallback search using YoutubeExplode directly when API quota runs out.
  Future<List<SongModel>> _fallbackExplodeSearch(String query) async {
    try {
      final searchResults = await _ytExplode.search
          .search(query)
          .timeout(const Duration(seconds: 8));
      final all = searchResults.map((video) {
        return SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.highResUrl,
          duration: video.duration != null
              ? '${video.duration!.inMinutes}:${(video.duration!.inSeconds % 60).toString().padLeft(2, '0')}'
              : '--:--',
        );
      }).toList();

      final official = all.where(_isOfficialMusic).toList();
      return official.isNotEmpty ? official : all;
    } catch (_) {
      return [];
    }
  }

  /// Extracts direct audio stream URL for a given YouTube video ID using YoutubeExplode.
  /// Prioritizes progressive muxed MP4 streams because YouTube permits open-ended byte
  /// range requests (Range: bytes=0-) returning HTTP 206 Partial Content, permanently
  /// bypassing the 403 Forbidden errors that occur with standalone adaptive audio streams.
  Future<String?> getAudioStreamUrl(String videoId) async {
    /// 1. Primary: Default YouTube client prioritizing progressive muxed MP4 streams
    try {
      final manifest = await _ytExplode.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 25));

      if (manifest.muxed.isNotEmpty) {
        return manifest.muxed.sortByBitrate().first.url.toString();
      }
      final aacStreams = manifest.audioOnly
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();
      if (aacStreams.isNotEmpty) {
        return aacStreams.withHighestBitrate().url.toString();
      }
      if (manifest.audioOnly.isNotEmpty) {
        return manifest.audioOnly.withHighestBitrate().url.toString();
      }
    } catch (_) {}

    /// 2. Fallback: Android client with high reliability
    try {
      final manifest = await _ytExplode.videos.streamsClient
          .getManifest(
            videoId,
            ytClients: [
              YoutubeApiClient.android,
            ],
          )
          .timeout(const Duration(seconds: 20));

      if (manifest.muxed.isNotEmpty) {
        return manifest.muxed.sortByBitrate().first.url.toString();
      }
      final aacStreams = manifest.audioOnly
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();
      if (aacStreams.isNotEmpty) {
        return aacStreams.withHighestBitrate().url.toString();
      }
      if (manifest.audioOnly.isNotEmpty) {
        return manifest.audioOnly.withHighestBitrate().url.toString();
      }
    } catch (_) {}

    return null;
  }

  /// Getter for the underlying YoutubeExplode instance.
  YoutubeExplode get ytExplode => _ytExplode;

  /// Releases resources used by the service.
  void dispose() {
    _ytExplode.close();
  }
}
