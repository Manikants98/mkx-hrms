/// Audio service handler module for background media controls, lockscreen, and notifications.
library;

import 'package:audio_service/audio_service.dart';

/// Handler that connects Android media session, lockscreen, and notification controls to player service.
class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  /// Callback to resume playback.
  Future<void> Function()? onPlay;

  /// Callback to pause playback.
  Future<void> Function()? onPause;

  /// Callback to play the next track in queue.
  Future<void> Function()? onSkipToNext;

  /// Callback to play the previous track in queue.
  Future<void> Function()? onSkipToPrevious;

  /// Callback to toggle repeat playback mode.
  Future<void> Function()? onToggleRepeat;

  /// Callback to seek playback position.
  Future<void> Function(Duration position)? onSeek;

  /// Callback to stop playback.
  Future<void> Function()? onStop;

  /// Constructor initializing initial idle playback state with standard actions.
  MusicAudioHandler() {
    playbackState.add(
      PlaybackState(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setRepeatMode,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (onPlay != null) {
      await onPlay!();
    }
  }

  @override
  Future<void> pause() async {
    if (onPause != null) {
      await onPause!();
    }
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) {
      await onSkipToNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) {
      await onSkipToPrevious!();
    }
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.media:
        if (playbackState.valueOrNull?.playing == true) {
          await pause();
        } else {
          await play();
        }
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (onToggleRepeat != null) {
      await onToggleRepeat!();
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggle_repeat' && onToggleRepeat != null) {
      await onToggleRepeat!();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (onSeek != null) {
      await onSeek!(position);
    }
  }

  @override
  Future<void> stop() async {
    if (onStop != null) {
      await onStop!();
    }
    await super.stop();
  }

  /// Sets the active media metadata displayed on lockscreen and notification card.
  void setTrackMetadata({
    required String id,
    required String title,
    required String artist,
    required String? album,
    required String? artUri,
    Duration? duration,
  }) {
    mediaItem.add(
      MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album ?? 'MKX Music',
        artUri: artUri != null && artUri.isNotEmpty ? Uri.tryParse(artUri) : null,
        duration: duration,
      ),
    );
  }

  /// Updates notification playback state with previous, play/pause, and next actions.
  void updatePlaybackState({
    required bool isPlaying,
    required AudioProcessingState processingState,
    required Duration position,
    required Duration bufferedPosition,
    required double speed,
    required int queueIndex,
    required AudioServiceRepeatMode repeatMode,
  }) {
    final controls = [
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setRepeatMode,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        speed: speed,
        queueIndex: queueIndex,
        repeatMode: repeatMode,
      ),
    );
  }
}
