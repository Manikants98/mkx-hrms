/// Song model representing a music track from YouTube.
class SongModel {
  /// Unique YouTube video ID.
  final String id;

  /// Song or video title.
  final String title;

  /// Channel or artist name.
  final String artist;

  /// High-resolution thumbnail image URL.
  final String thumbnailUrl;

  /// Human-readable duration string (e.g. 03:45).
  final String duration;

  /// Cached audio stream URL once extracted.
  String? audioStreamUrl;

  /// Whether the track is pinned by the user (iOS 26 Pinned Music feature).
  bool isPinned;

  /// Time-synced lyrics with phonetic pronunciation for the track.
  final List<LyricLine>? lyrics;

  /// Constructor for creating a song track.
  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.duration = '--:--',
    this.audioStreamUrl,
    this.isPinned = false,
    this.lyrics,
  });

  /// Factory constructor to parse any YouTube item (from search or videos endpoint).
  factory SongModel.fromYouTubeMap(Map item) {
    final rawId = item['id'];
    String videoId = '';
    if (rawId is String) {
      videoId = rawId;
    } else if (rawId is Map) {
      videoId = (rawId['videoId'] ?? '').toString();
    }

    final snippet = item['snippet'] is Map ? item['snippet'] as Map : {};
    final title = (snippet['title'] ?? 'Unknown Title').toString();
    final artist = (snippet['channelTitle'] ?? 'Unknown Artist').toString();

    final thumbnails = snippet['thumbnails'] is Map ? snippet['thumbnails'] as Map : {};
    String thumbUrl = '';
    if (thumbnails['high'] is Map && thumbnails['high']['url'] != null) {
      thumbUrl = thumbnails['high']['url'].toString();
    } else if (thumbnails['medium'] is Map && thumbnails['medium']['url'] != null) {
      thumbUrl = thumbnails['medium']['url'].toString();
    } else if (thumbnails['default'] is Map && thumbnails['default']['url'] != null) {
      thumbUrl = thumbnails['default']['url'].toString();
    }

    if (thumbUrl.isEmpty && videoId.isNotEmpty) {
      thumbUrl = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    }

    return SongModel(
      id: videoId,
      title: _cleanTitle(title),
      artist: artist,
      thumbnailUrl: thumbUrl,
    );
  }

  /// Factory constructor to parse YouTube Data API search items.
  factory SongModel.fromYouTubeSnippet(Map item) => SongModel.fromYouTubeMap(item);

  /// Factory constructor to parse YouTube Data API mostPopular video chart items.
  factory SongModel.fromYouTubeVideoItem(Map item) => SongModel.fromYouTubeMap(item);

  /// Cleans HTML entities that YouTube titles frequently contain.
  static String _cleanTitle(String rawTitle) {
    return rawTitle
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}

/// Represents a line of time-synced lyrics with phonetic pronunciation (iOS 26 feature).
class LyricLine {
  /// Original text of the lyric.
  final String text;

  /// Phonetic pronunciation or translation in iOS 26 style.
  final String? phonetic;

  /// Timestamp in seconds.
  final int seconds;

  /// Constructor for LyricLine.
  const LyricLine({
    required this.text,
    this.phonetic,
    required this.seconds,
  });
}
