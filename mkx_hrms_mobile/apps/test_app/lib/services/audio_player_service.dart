/// Audio player service module.
library;

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/song_model.dart';
import 'music_audio_handler.dart';
import 'youtube_music_service.dart';

/// Repeat mode playback state matching Apple Music.
enum MusicRepeatMode {
  /// Play queue sequentially, stop when queue ends.
  off,

  /// Loop entire queue.
  all,

  /// Loop current song continuously.
  one,
}

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
  bool _usingIframe = false;

  /// Whether iOS 26 AI AutoMix is enabled for seamless beat-matched transitions.
  bool _isAutoMix = true;

  /// Whether the real-time lyrics & phonetic pronunciation view is displayed.
  bool _isLyricsOpen = false;

  /// Set of video IDs pinned to the top of Library / Home (iOS 26 feature).
  final Set<String> _pinnedIds = {};

  /// Pinned songs list containing full SongModel instances.
  final List<SongModel> _pinnedSongsList = [];

  /// Background audio handler managing system notifications and lockscreen.
  final MusicAudioHandler? audioHandler;

  /// Constructor initializing native audio player, iframe fallback, and background audio handler.
  AudioPlayerService({
    required this.musicService,
    this.audioHandler,
  }) {
    _audioPlayer = ja.AudioPlayer(
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      useProxyForRequestHeaders: false,
    );
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

    _initAudioHandlerCallbacks();
    _initNativeListeners();
    _initIframeListeners();
  }

  /// Connects audio handler notification actions to player controls.
  void _initAudioHandlerCallbacks() {
    if (audioHandler == null) return;
    audioHandler!.onPlay = play;
    audioHandler!.onPause = pause;
    audioHandler!.onSkipToNext = playNext;
    audioHandler!.onSkipToPrevious = playPrevious;
    audioHandler!.onToggleRepeat = () async {
      toggleRepeat();
    };
    audioHandler!.onSeek = seek;
    audioHandler!.onStop = () async {
      await pause();
    };
  }

  /// Maps native player state to AudioProcessingState for the notification.
  AudioProcessingState _getAudioProcessingState() {
    if (_errorMessage != null) return AudioProcessingState.error;
    if (_currentSong != null) {
      if (_isLoading) return AudioProcessingState.loading;
      switch (_audioPlayer.playerState.processingState) {
        case ja.ProcessingState.idle:
        case ja.ProcessingState.loading:
          return AudioProcessingState.loading;
        case ja.ProcessingState.buffering:
          return AudioProcessingState.buffering;
        case ja.ProcessingState.ready:
          return AudioProcessingState.ready;
        case ja.ProcessingState.completed:
          return AudioProcessingState.completed;
      }
    }
    return AudioProcessingState.idle;
  }

  /// Synchronizes current song and playback status with the system notification.
  void _syncNotification() {
    if (audioHandler == null || _currentSong == null) return;
    audioHandler!.updatePlaybackState(
      isPlaying: _isLoading ? true : isPlaying,
      processingState: _getAudioProcessingState(),
      position: _usingIframe ? Duration.zero : _audioPlayer.position,
      bufferedPosition:
          _usingIframe ? Duration.zero : _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
      queueIndex: _currentIndex >= 0 ? _currentIndex : 0,
      repeatMode: _repeatMode == MusicRepeatMode.one
          ? AudioServiceRepeatMode.one
          : (_repeatMode == MusicRepeatMode.all
              ? AudioServiceRepeatMode.all
              : AudioServiceRepeatMode.none),
    );
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

  /// Whether shuffle playback mode is enabled.
  bool _isShuffle = false;

  /// Getter for shuffle playback mode status.
  bool get isShuffle => _isShuffle;

  /// Toggles shuffle playback mode.
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  /// Current repeat mode matching Apple Music iOS 26.
  MusicRepeatMode _repeatMode = MusicRepeatMode.off;

  /// Getter for active repeat playback mode.
  MusicRepeatMode get repeatMode => _repeatMode;

  /// Legacy getter for backwards compatibility.
  bool get isRepeat => _repeatMode != MusicRepeatMode.off;

  /// Toggles through Apple Music repeat modes: Off -> All -> One -> Off.
  void toggleRepeat() {
    switch (_repeatMode) {
      case MusicRepeatMode.off:
        _repeatMode = MusicRepeatMode.all;
        _audioPlayer.setLoopMode(ja.LoopMode.off);
        break;
      case MusicRepeatMode.all:
        _repeatMode = MusicRepeatMode.one;
        _audioPlayer.setLoopMode(ja.LoopMode.one);
        break;
      case MusicRepeatMode.one:
        _repeatMode = MusicRepeatMode.off;
        _audioPlayer.setLoopMode(ja.LoopMode.off);
        break;
    }
    _syncNotification();
    notifyListeners();
  }

  /// Removes a song from the queue by index.
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (_currentIndex >= _queue.length) {
      _currentIndex = _queue.length - 1;
    }
    notifyListeners();
  }

  /// Reorders a song within the queue.
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;
    final currentSongId = _currentSong?.id;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    if (currentSongId != null) {
      _currentIndex = _queue.indexWhere((s) => s.id == currentSongId);
    }
    notifyListeners();
  }

  /// Clears upcoming tracks from the queue, preserving the currently playing song.
  void clearUpcomingQueue() {
    if (_currentSong != null && _currentIndex >= 0 && _currentIndex < _queue.length) {
      final current = _queue[_currentIndex];
      _queue = [current];
      _currentIndex = 0;
    } else {
      _queue.clear();
      _currentIndex = -1;
    }
    notifyListeners();
  }

  /// Getter for player volume level (0.0 to 1.0).
  double get volume => _audioPlayer.volume;

  /// Sets player volume level (0.0 to 1.0).
  Future<void> setVolume(double val) async {
    await _audioPlayer.setVolume(val.clamp(0.0, 1.0));
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
          if (_repeatMode == MusicRepeatMode.one) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.play();
          } else {
            playNext();
          }
        } else if (state.processingState == ja.ProcessingState.ready) {
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } else {
          notifyListeners();
        }
        _syncNotification();
      },
      onError: (Object err) {
        _isLoading = false;
        _errorMessage = 'Playback error: $err';
        notifyListeners();
        _syncNotification();
      },
    );

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null && _currentSong != null) {
        audioHandler?.setTrackMetadata(
          id: _currentSong!.id,
          title: _currentSong!.title,
          artist: _currentSong!.artist,
          album: 'MKX Music',
          artUri: _currentSong!.thumbnailUrl,
          duration: duration,
        );
      }
    });

    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object err) {
        debugPrint('[AudioPlayer] Native playbackEvent error: $err');
      },
    );
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
    } else if (_queue.isEmpty) {
      _queue = [song];
      _currentIndex = 0;
    } else {
      final existingIdx = _queue.indexWhere((s) => s.id == song.id);
      if (existingIdx != -1) {
        _currentIndex = existingIdx;
      } else {
        _queue.add(song);
        _currentIndex = _queue.length - 1;
      }
    }

    _currentSong = song;
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    audioHandler?.setTrackMetadata(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: 'MKX Music',
      artUri: song.thumbnailUrl,
      duration: null,
    );
    _syncNotification();

    debugPrint('[AudioPlayer] playSong requested: ${song.title} (${song.id})');

    try {
      if (_usingIframe) {
        await _ytController.pauseVideo();
      }
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      final String? url;
      if (song.audioStreamUrl != null && song.audioStreamUrl!.isNotEmpty) {
        url = song.audioStreamUrl;
      } else {
        url = await musicService
            .getAudioStreamUrl(song.id)
            .timeout(const Duration(seconds: 20));
      }

      if (url == null || url.isEmpty) {
        throw Exception('No stream URL extracted');
      }
      song.audioStreamUrl = url;
      _usingIframe = false;
      final audioSource = ja.AudioSource.uri(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        },
      );
      _audioPlayer.play();
      await _audioPlayer.setAudioSource(audioSource);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      _syncNotification();
      _preloadNextSongs();
    } catch (e) {
      song.audioStreamUrl = null;
      debugPrint('[AudioPlayer] Native audio failed ($e)');
      _isLoading = false;
      _errorMessage =
          'Unable to stream this track. Please select another song.';
      notifyListeners();
      _syncNotification();
    }
  }

  /// Pre-fetches stream URLs for upcoming tracks in background for instant playback.
  void _preloadNextSongs() {
    if (_queue.isEmpty || _currentIndex < 0) return;
    final nextIndex = (_currentIndex + 1) % _queue.length;
    final nextSong = _queue[nextIndex];
    if (nextSong.audioStreamUrl == null || nextSong.audioStreamUrl!.isEmpty) {
      musicService.getAudioStreamUrl(nextSong.id).then((url) {
        if (url != null && url.isNotEmpty) {
          nextSong.audioStreamUrl = url;
        }
      }).catchError((_) {});
    }
  }

  /// Resumes playback.
  Future<void> play() async {
    if (_usingIframe) {
      await _ytController.playVideo();
    } else {
      await _audioPlayer.play();
    }
    _syncNotification();
    notifyListeners();
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (_usingIframe) {
      await _ytController.pauseVideo();
    } else {
      await _audioPlayer.pause();
    }
    _syncNotification();
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
    _syncNotification();
  }

  /// Plays the next song in the queue.
  Future<void> playNext() async {
    if (_queue.isEmpty) {
      if (_currentSong != null) {
        _queue = [_currentSong!];
        _currentIndex = 0;
      } else {
        return;
      }
    }
    if (_isShuffle && _queue.length > 1) {
      final nextIdx =
          (_currentIndex + 1 + (DateTime.now().millisecond % (_queue.length - 1))) %
              _queue.length;
      _currentIndex = nextIdx;
      await playSong(_queue[_currentIndex]);
    } else if (_queue.length > 1) {
      if (_currentIndex >= _queue.length - 1) {
        _currentIndex = 0;
      } else {
        _currentIndex++;
      }
      await playSong(_queue[_currentIndex]);
    } else {
      await seek(Duration.zero);
      await play();
    }
  }

  /// Plays the previous song in the queue.
  Future<void> playPrevious() async {
    if (_queue.isEmpty) {
      if (_currentSong != null) {
        _queue = [_currentSong!];
        _currentIndex = 0;
      } else {
        return;
      }
    }
    if (_audioPlayer.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    } else if (_queue.length > 1) {
      _currentIndex = _queue.length - 1;
      await playSong(_queue[_currentIndex]);
    } else {
      await seek(Duration.zero);
      await play();
    }
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
