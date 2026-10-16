/// Audio player service module.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/song_model.dart';
import 'youtube_music_service.dart';

/// Service managing audio playback using native just_audio streaming with YouTube iframe fallback.
class AudioPlayerService extends ChangeNotifier {
  /// Native audio player engine from just_audio.
  late final ja.AudioPlayer _audioPlayer;

  /// Secondary YouTube iframe player controller fallback.
  late final YoutubePlayerController _ytController;

  /// Subscription to native audio player state stream.
  StreamSubscription<ja.PlayerState>? _audioPlayerSubscription;

  /// Reference to YouTube search and metadata service.
  final YouTubeMusicService musicService;

  /// Currently active song track.
  SongModel? _currentSong;

  /// Current queue of tracks.
  List<SongModel> _queue = [];

  /// Current song index in queue.
  int _currentIndex = -1;

  /// Flag indicating if an audio stream is currently being loaded.
  bool _isLoading = false;

  /// Error message if playback fails.
  String? _errorMessage;

  /// Stream subscription for player state changes.
  StreamSubscription<YoutubePlayerValue>? _ytSubscription;

  /// Whether playback is currently handled by the YouTube iframe engine.
  bool _usingIframe = true;

  /// Whether iOS 26 AI AutoMix is enabled for seamless beat-matched transitions.
  bool _isAutoMix = true;

  /// Whether the real-time lyrics & phonetic pronunciation view is displayed.
  bool _isLyricsOpen = false;

  /// Set of video IDs pinned to the top of Library / Home (iOS 26 feature).
  final Set<String> _pinnedIds = {};

  /// Pinned songs list containing full SongModel instances.
  final List<SongModel> _pinnedSongsList = [];

  /// Constructor initializing native audio player and iframe fallback.
  AudioPlayerService({required this.musicService}) {
    _audioPlayer = ja.AudioPlayer();
    _ytController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        showVideoAnnotations: false,
        mute: false,
        loop: false,
        enableJavaScript: true,
      ),
    );

    _initNativeListeners();
    _initIframeListeners();
  }

  /// Getter for YouTube player controller.
  YoutubePlayerController get ytController => _ytController;

  /// Whether iframe fallback is currently active.
  bool get usingIframe => _usingIframe;

  /// Getter for current playing song.
  SongModel? get currentSong => _currentSong;

  /// Getter for song queue.
  List<SongModel> get queue => _queue;

  /// Getter for loading state.
  bool get isLoading =>
      _errorMessage == null &&
      (_isLoading ||
          (!_usingIframe &&
              (_audioPlayer.playerState.processingState ==
                      ja.ProcessingState.buffering ||
                  _audioPlayer.playerState.processingState ==
                      ja.ProcessingState.loading)) ||
          (_usingIframe &&
              _ytController.value.playerState == PlayerState.buffering));

  /// Getter for error message.
  String? get errorMessage => _errorMessage;

  /// Getter for playing state.
  bool get isPlaying => _usingIframe
      ? _ytController.value.playerState == PlayerState.playing
      : _audioPlayer.playing;

  /// Stream of current playback position.
  Stream<Duration> get positionStream => _usingIframe
      ? _ytController.videoStateStream.map((state) => state.position)
      : _audioPlayer.positionStream;

  /// Stream of current track duration.
  Stream<Duration> get durationStream => _usingIframe
      ? _ytController.stream.map((value) => value.metaData.duration)
      : _audioPlayer.durationStream.map((d) => d ?? Duration.zero);

  /// Total duration of the current audio.
  Duration get totalDuration => _usingIframe
      ? _ytController.value.metaData.duration
      : (_audioPlayer.duration ?? Duration.zero);

  /// Getter for iOS 26 AutoMix status.
  bool get isAutoMix => _isAutoMix;

  /// Toggles iOS 26 AutoMix feature.
  void toggleAutoMix() {
    _isAutoMix = !_isAutoMix;
    notifyListeners();
  }

  /// Getter for real-time lyrics & phonetic pronunciation view.
  bool get isLyricsOpen => _isLyricsOpen;

  /// Toggles the real-time lyrics view.
  void toggleLyrics() {
    _isLyricsOpen = !_isLyricsOpen;
    notifyListeners();
  }

  /// Recently played tracks history.
  final List<SongModel> _recentlyPlayed = [];

  /// Getter for recently played tracks history.
  List<SongModel> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);

  /// Getter for pinned songs list.
  List<SongModel> get pinnedSongs => List.unmodifiable(_pinnedSongsList);

  /// Checks if a song is pinned.
  bool isPinned(String songId) => _pinnedIds.contains(songId);

  /// Toggles pinned status of a song (iOS 26 Pinned Music).
  void togglePin(String songId) {
    if (_currentSong != null && _currentSong!.id == songId) {
      togglePinSong(_currentSong!);
    } else {
      final existingIdx = _pinnedSongsList.indexWhere((s) => s.id == songId);
      if (existingIdx >= 0) {
        final s = _pinnedSongsList.removeAt(existingIdx);
        s.isPinned = false;
        _pinnedIds.remove(songId);
      } else {
        _pinnedIds.add(songId);
      }
      notifyListeners();
    }
  }

  /// Toggles pinned status of a song model.
  void togglePinSong(SongModel song) {
    final existingIdx = _pinnedSongsList.indexWhere((s) => s.id == song.id);
    if (existingIdx >= 0) {
      _pinnedSongsList.removeAt(existingIdx);
      song.isPinned = false;
      _pinnedIds.remove(song.id);
    } else {
      song.isPinned = true;
      _pinnedSongsList.insert(0, song);
      _pinnedIds.add(song.id);
    }
    notifyListeners();
  }

  /// Initializes native audio player listeners.
  void _initNativeListeners() {
    _audioPlayerSubscription = _audioPlayer.playerStateStream.listen(
      (state) {
        if (state.processingState == ja.ProcessingState.completed) {
          playNext();
        } else if (state.processingState == ja.ProcessingState.ready) {
          _isLoading = false;
          _errorMessage = null;
        }
      },
      onError: (Object err) {
        if (_currentSong != null && !_usingIframe) {
          _playViaIframe(_currentSong!);
        } else {
          _isLoading = false;
          _errorMessage = 'Playback error: $err';
        }
      },
    );

    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object err) {
        if (_currentSong != null && !_usingIframe) {
          _playViaIframe(_currentSong!);
        } else {
          _isLoading = false;
          _errorMessage = 'Audio error: $err';
        }
      },
    );
  }

  /// Seamlessly loads and plays the audio via the official YouTube iframe engine.
  Future<void> _playViaIframe(SongModel song) async {
    _usingIframe = true;
    _isLoading = true;
    _errorMessage = null;

    debugPrint('[AudioPlayer] Loading via IFrame: ${song.id} (${song.title})');

    try {
      await _audioPlayer.stop();
      await _ytController
          .loadVideoById(videoId: song.id)
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () => throw TimeoutException('[AudioPlayer] loadVideoById timed out'),
          );
      await _ytController
          .playVideo()
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => throw TimeoutException('[AudioPlayer] playVideo timed out'),
          );
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[AudioPlayer] loadVideoById error/timeout: $e, attempting cue + play',
      );
      try {
        await _ytController
            .cueVideoById(videoId: song.id)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw TimeoutException('[AudioPlayer] cueVideoById timed out'),
            );
        await _ytController
            .playVideo()
            .timeout(
              const Duration(seconds: 4),
              onTimeout: () => throw TimeoutException('[AudioPlayer] playVideo timed out'),
            );
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      } catch (cueErr) {
        debugPrint('[AudioPlayer] IFrame fallback also failed: $cueErr');
        _isLoading = false;
        _errorMessage = 'Playback error: $cueErr';
        notifyListeners();

        /// Advance queue to next track if available
        if (_queue.length > 1 && _currentIndex < _queue.length - 1) {
          debugPrint('[AudioPlayer] Auto-skipping to next track in queue');
          playNext();
        }
      }
    }
  }

  /// Initializes player event listeners for iframe fallback.
  void _initIframeListeners() {
    _ytSubscription = _ytController.stream.listen((value) {
      debugPrint(
        '[AudioPlayer] IFrame playerState=${value.playerState}, hasError=${value.hasError}',
      );
      if (!_usingIframe) return;
      if (value.playerState == PlayerState.playing) {
        _isLoading = false;
        _errorMessage = null;
      } else if (value.playerState == PlayerState.cued) {
        _isLoading = false;
        if (_currentSong != null) {
          play();
        }
      } else if (value.playerState == PlayerState.paused) {
        _isLoading = false;
      } else if (value.playerState == PlayerState.ended) {
        playNext();
      } else if (value.hasError) {
        _isLoading = false;
        _errorMessage = 'Playback error: ${value.error.name}';
        notifyListeners();

        /// Auto-skip to next track on embedding error (e.g. 101/150)
        if (_queue.length > 1 && _currentIndex < _queue.length - 1) {
          debugPrint(
            '[AudioPlayer] Track failed with ${value.error.name}, auto-advancing queue',
          );
          playNext();
        }
      }
      notifyListeners();
    });
  }

  /// Plays a given song using native just_audio stream first, falling back to YouTube iframe.
  Future<void> playSong(SongModel song, {List<SongModel>? newQueue}) async {
    if (newQueue != null && newQueue.isNotEmpty) {
      _queue = List<SongModel>.from(newQueue);
      _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex == -1) {
        _queue.insert(0, song);
        _currentIndex = 0;
      }
    }

    _currentSong = song;
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('[AudioPlayer] playSong requested: ${song.title} (${song.id})');

    try {
      await _ytController.pauseVideo();
      final url = song.audioStreamUrl ??
          await musicService
              .getAudioStreamUrl(song.id)
              .timeout(const Duration(seconds: 8));
      if (url == null || url.isEmpty) {
        throw Exception('No stream URL extracted');
      }
      song.audioStreamUrl = url;
      _usingIframe = false;
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioPlayer] Native audio failed ($e), falling back to IFrame');
      await _playViaIframe(song);
    }
  }

  /// Resumes playback.
  Future<void> play() async {
    if (_usingIframe) {
      await _ytController.playVideo();
    } else {
      await _audioPlayer.play();
    }
    notifyListeners();
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (_usingIframe) {
      await _ytController.pauseVideo();
    } else {
      await _audioPlayer.pause();
    }
    notifyListeners();
  }

  /// Toggles between play and pause.
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seeks to a specific timestamp.
  Future<void> seek(Duration position) async {
    if (_usingIframe) {
      await _ytController.seekTo(
        seconds: position.inSeconds.toDouble(),
        allowSeekAhead: true,
      );
    } else {
      await _audioPlayer.seek(position);
    }
  }

  /// Plays the next song in the queue.
  Future<void> playNext() async {
    if (_queue.isEmpty || _currentIndex >= _queue.length - 1) return;
    _currentIndex++;
    await playSong(_queue[_currentIndex]);
  }

  /// Plays the previous song in the queue.
  Future<void> playPrevious() async {
    if (_queue.isEmpty || _currentIndex <= 0) return;
    _currentIndex--;
    await playSong(_queue[_currentIndex]);
  }

  @override
  void dispose() {
    _audioPlayerSubscription?.cancel();
    _ytSubscription?.cancel();
    _audioPlayer.dispose();
    _ytController.close();
    super.dispose();
  }
}
