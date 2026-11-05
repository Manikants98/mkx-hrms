/// Lyrics service module fetching synced and plain lyrics.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

/// Single line in a synced lyrics track with timestamp.
class LyricLine {
  /// Playback timestamp when this lyric line begins.
  final Duration timestamp;

  /// Text content of this lyric line.
  final String text;

  /// Constructor for LyricLine.
  const LyricLine({required this.timestamp, required this.text});
}

/// Parsed lyrics result for a song.
class LyricsResult {
  /// Track name returned by lyrics provider.
  final String trackName;

  /// Artist name returned by lyrics provider.
  final String artistName;

  /// Timestamped lines of lyrics.
  final List<LyricLine> lines;

  /// Whether the lyrics have millisecond timestamps.
  final bool isSynced;

  /// Full plain text lyrics if available.
  final String? plainLyrics;

  /// Constructor for LyricsResult.
  const LyricsResult({
    required this.trackName,
    required this.artistName,
    required this.lines,
    required this.isSynced,
    this.plainLyrics,
  });
}

/// Service that fetches and caches synchronized lyrics from LRCLIB API.
class LyricsService {
  /// In-memory cache keyed by song id.
  static final Map<String, LyricsResult?> _cache = {};

  /// Shared client for requests.
  static final http.Client _client = http.Client();

  /// Fetches synced or plain lyrics for the given song model.
  static Future<LyricsResult?> fetchLyrics(SongModel song) async {
    if (_cache.containsKey(song.id)) {
      return _cache[song.id];
    }

    try {
      final cleanTitle = _sanitizeTitle(song.title);
      final cleanArtist = _sanitizeArtist(song.artist);

      /// 1. Try exact get with sanitized artist and title
      var result = await _fetchExact(cleanArtist, cleanTitle);

      /// 2. If exact match not found, try search with title
      result ??= await _fetchSearch('$cleanTitle $cleanArtist');

      /// 3. Fallback to just the main title keyword
      result ??= await _fetchSearch(cleanTitle);

      _cache[song.id] = result;
      return result;
    } catch (_) {
      _cache[song.id] = null;
      return null;
    }
  }

  /// Exact lookup via LRCLIB get endpoint.
  static Future<LyricsResult?> _fetchExact(String artist, String title) async {
    if (title.isEmpty) return null;
    try {
      final uri = Uri.https('lrclib.net', '/api/get', {
        'artist_name': artist,
        'track_name': title,
      });

      final response = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return _parseLyricsJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Search lookup via LRCLIB search endpoint.
  static Future<LyricsResult?> _fetchSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    try {
      final uri = Uri.https('lrclib.net', '/api/search', {
        'q': trimmed,
      });

      final response = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final List<dynamic> list =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final parsed = _parseLyricsJson(item);
            if (parsed != null) return parsed;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Parses LRCLIB JSON payload into LyricsResult.
  static LyricsResult? _parseLyricsJson(Map<String, dynamic> data) {
    final synced = data['syncedLyrics']?.toString();
    final plain = data['plainLyrics']?.toString();
    final track = (data['trackName'] ?? data['name'] ?? '').toString();
    final artist = (data['artistName'] ?? '').toString();

    if (synced != null && synced.trim().isNotEmpty) {
      final lines = _parseSyncedLyrics(synced);
      if (lines.isNotEmpty) {
        return LyricsResult(
          trackName: track,
          artistName: artist,
          lines: lines,
          isSynced: true,
          plainLyrics: plain,
        );
      }
    }

    if (plain != null && plain.trim().isNotEmpty) {
      final lines = plain
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => LyricLine(timestamp: Duration.zero, text: l))
          .toList();

      if (lines.isNotEmpty) {
        return LyricsResult(
          trackName: track,
          artistName: artist,
          lines: lines,
          isSynced: false,
          plainLyrics: plain,
        );
      }
    }

    return null;
  }

  /// Parses LRC timestamped string into a list of LyricLine objects.
  static List<LyricLine> _parseSyncedLyrics(String lrc) {
    final result = <LyricLine>[];
    final regExp = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\](.*)$');

    for (final rawLine in lrc.split('\n')) {
      final match = regExp.firstMatch(rawLine.trim());
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = double.tryParse(match.group(2) ?? '0.0') ?? 0.0;
        final text = (match.group(3) ?? '').trim();

        if (text.isNotEmpty) {
          final ms = (minutes * 60000 + seconds * 1000).toInt();
          result.add(LyricLine(
            timestamp: Duration(milliseconds: ms),
            text: text,
          ));
        }
      }
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  /// Cleans raw YouTube titles (e.g. removes "Official Video", "(Slowed + Reverb)", etc.).
  static String _sanitizeTitle(String title) {
    var clean = title;

    /// Remove brackets content
    clean = clean.replaceAll(RegExp(r'\[.*?\]'), ' ');
    clean = clean.replaceAll(RegExp(r'\(.*?\)'), ' ');

    /// Split by delimiters like |, -, /, x
    if (clean.contains('|')) {
      clean = clean.split('|').first;
    }
    if (clean.contains('–')) {
      clean = clean.split('–').first;
    }

    /// Common tag cleanup
    clean = clean.replaceAll(RegExp(r'official\s+video', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'lyric(al)?\s+video', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'full\s+song', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'audio', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'slowed\s*\+\s*reverb', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'lofi', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'remix', caseSensitive: false), '');

    return clean.trim();
  }

  /// Cleans artist names.
  static String _sanitizeArtist(String artist) {
    var clean = artist;
    clean = clean.replaceAll(RegExp(r'vevo', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'topic', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'records', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'music', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'official', caseSensitive: false), '');
    return clean.trim();
  }
}
