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
  Future<List<SongModel>> searchMusic(
    String query, {
    int maxResults = 25,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/search'
        '?part=snippet'
        '&maxResults=$maxResults'
        '&q=${Uri.encodeComponent(query)}'
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

          if (results.isNotEmpty) return results;
        }
      }

      /// Retry with general video search if needed
      final retryUri = Uri.parse(
        '$_baseUrl/search'
        '?part=snippet'
        '&maxResults=$maxResults'
        '&q=${Uri.encodeComponent('$query song')}'
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

          if (results.isNotEmpty) return results;
        }
      }

      return await _fallbackExplodeSearch(query);
    } catch (_) {
      return await _fallbackExplodeSearch(query);
    }
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
              .toList();

          if (songs.isNotEmpty) {
            _cachedTrending = songs;
            return songs;
          }
        }
      }
    } catch (_) {}

    /// 3. Fallback: Search for trending hit songs
    final fallbackSongs = await searchMusic('trending songs hindi', maxResults: maxResults);
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

  /// Maps category name to optimal YouTube search keywords.
  String _categoryToQuery(String category) {
    switch (category) {
      case 'AutoMix':
        return 'Apple Music AutoMix continuous transition DJ mix';
      case 'Spatial Audio':
        return 'Spatial Audio Dolby Atmos popular songs';
      case 'Lo-Fi Chill':
        return 'lofi chill hip hop beats study music';
      case 'Pop Hits':
        return 'top billboard pop hits songs 2026';
      case 'Bollywood':
        return 'trending bollywood hindi songs';
      case 'EDM':
        return 'EDM dance electronic festival music';
      case 'Rock':
        return 'classic and modern rock anthems';
      default:
        return '$category songs';
    }
  }

  /// Fallback search using YoutubeExplode directly when API quota runs out.
  Future<List<SongModel>> _fallbackExplodeSearch(String query) async {
    try {
      final searchResults = await _ytExplode.search
          .search(query)
          .timeout(const Duration(seconds: 8));
      return searchResults.map((video) {
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
    } catch (_) {
      return [];
    }
  }

  /// Extracts direct audio stream URL for a given YouTube video ID using YoutubeExplode.
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _ytExplode.videos.streamsClient
          .getManifest(
            videoId,
            ytClients: [
              YoutubeApiClient.ios,
              YoutubeApiClient.safari,
              YoutubeApiClient.androidVr,
            ],
          )
          .timeout(const Duration(seconds: 12));
      if (manifest.audioOnly.isNotEmpty) {
        return manifest.audioOnly.withHighestBitrate().url.toString();
      }
      if (manifest.muxed.isNotEmpty) {
        return manifest.muxed.withHighestBitrate().url.toString();
      }
    } catch (_) {}

    try {
      final manifest = await _ytExplode.videos.streamsClient
          .getManifest(
            videoId,
            ytClients: [
              YoutubeApiClient.tv,
              YoutubeApiClient.android,
            ],
          )
          .timeout(const Duration(seconds: 10));
      if (manifest.audioOnly.isNotEmpty) {
        return manifest.audioOnly.withHighestBitrate().url.toString();
      }
      if (manifest.muxed.isNotEmpty) {
        return manifest.muxed.withHighestBitrate().url.toString();
      }
    } catch (_) {}

    try {
      final manifest = await _ytExplode.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 10));
      if (manifest.audioOnly.isNotEmpty) {
        return manifest.audioOnly.withHighestBitrate().url.toString();
      }
      if (manifest.muxed.isNotEmpty) {
        return manifest.muxed.withHighestBitrate().url.toString();
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
