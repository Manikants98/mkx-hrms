import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../services/lyrics_service.dart';

/// Center view mode in the Apple Music Now Playing sheet.
enum CenterViewMode {
  /// Square album artwork with dynamic scaling.
  artwork,

  /// Interactive synchronized lyrics view.
  lyrics,

  /// Up Next queue manager view.
  queue,
}

/// Full-screen Apple Music iOS 26 Now Playing sheet — all controls interactive.
class NowPlayingSheet extends StatefulWidget {
  /// Reference to the audio player service.
  final AudioPlayerService playerService;

  /// Constructor for NowPlayingSheet.
  const NowPlayingSheet({super.key, required this.playerService});

  @override
  State<NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends State<NowPlayingSheet> {
  bool _isFavorite = false;
  String? _lastError;
  CenterViewMode _centerViewMode = CenterViewMode.artwork;

  @override
  void initState() {
    super.initState();
    widget.playerService.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    widget.playerService.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final err = widget.playerService.errorMessage;
    if (err != null && err != _lastError) {
      _lastError = err;
      _showIosToast(context, err, icon: CupertinoIcons.exclamationmark_circle);
    }
  }

  /// Formats duration as m:ss.
  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Formats remaining duration as -m:ss.
  String _fmtRemaining(Duration total, Duration pos) {
    final r = total - pos;
    if (r.isNegative || total == Duration.zero) return '-0:00';
    final m = r.inMinutes;
    final s = r.inSeconds % 60;
    return '-$m:${s.toString().padLeft(2, '0')}';
  }

  /// Displays an iOS-style dynamic island feedback pill overlay.
  void _showIosToast(BuildContext context, String message, {IconData? icon}) {
    final overlay =
        Navigator.maybeOf(context)?.overlay ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, (1 - val) * -12),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.playerService,
      builder: (ctx, _) {
        final song = widget.playerService.currentSong;
        if (song == null) return const SizedBox.shrink();

        final isPinned = widget.playerService.isPinned(song.id);
        final isAutoMix = widget.playerService.isAutoMix;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: Stack(
              children: [
                /// Ambient blurred artwork background with Apple Music dark gradient
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x50000000),
                            Color(0x95000000),
                            Color(0xF5000000),
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                /// Content
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        /// Grabber
                        Center(
                          child: Container(
                            width: 36,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        /// Top bar: back chevron + options menu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _showOptionsMenu(ctx, song, isPinned);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        /// Apple Music Liquid Glass Center: Artwork / Synced Lyrics / Up Next Queue
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              child: _centerViewMode == CenterViewMode.artwork
                                  ? AspectRatio(
                                      key: const ValueKey('artwork'),
                                      aspectRatio: 1.0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          setState(
                                            () => _centerViewMode =
                                                CenterViewMode.lyrics,
                                          );
                                        },
                                        child: AnimatedScale(
                                          scale: widget.playerService.isPlaying
                                              ? 1.0
                                              : 0.86,
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.50),
                                                  blurRadius: 36,
                                                  spreadRadius: -2,
                                                  offset: const Offset(0, 18),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              child: CachedNetworkImage(
                                                imageUrl: song.thumbnailUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorWidget: (_, _, _) =>
                                                    Container(
                                                      color: Colors.white10,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : _centerViewMode == CenterViewMode.lyrics
                                  ? _LyricsView(
                                      key: const ValueKey('lyrics'),
                                      song: song,
                                      playerService: widget.playerService,
                                      onDismiss: () => setState(
                                        () => _centerViewMode =
                                            CenterViewMode.artwork,
                                      ),
                                    )
                                  : _QueueView(
                                      key: const ValueKey('queue'),
                                      playerService: widget.playerService,
                                      onDismiss: () => setState(
                                        () => _centerViewMode =
                                            CenterViewMode.artwork,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        /// Title + Artist + Favorite + Pin
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isFavorite = !_isFavorite);
                                _showIosToast(
                                  ctx,
                                  _isFavorite
                                      ? 'Added to Favorites'
                                      : 'Removed from Favorites',
                                  icon: _isFavorite
                                      ? CupertinoIcons.heart_fill
                                      : CupertinoIcons.heart,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  _isFavorite
                                      ? CupertinoIcons.heart_fill
                                      : CupertinoIcons.heart,
                                  color: _isFavorite
                                      ? const Color(0xFFFA2D48)
                                      : Colors.white60,
                                  size: 24,
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.playerService.togglePinSong(song);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  isPinned
                                      ? CupertinoIcons.pin_fill
                                      : CupertinoIcons.pin,
                                  color: isPinned
                                      ? const Color(0xFFFA2D48)
                                      : Colors.white60,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        /// Apple Music iOS Scrubber Bar
                        StreamBuilder<Duration>(
                          stream: widget.playerService.positionStream,
                          builder: (context, snap) {
                            final pos = snap.data ?? Duration.zero;
                            final dur = widget.playerService.totalDuration;
                            final pct = dur.inMilliseconds > 0
                                ? (pos.inMilliseconds / dur.inMilliseconds)
                                      .clamp(0.0, 1.0)
                                : 0.0;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white.withValues(
                                      alpha: 0.20,
                                    ),
                                    thumbColor: Colors.white,
                                    trackHeight: 3.5,
                                    trackShape:
                                        const RoundedRectSliderTrackShape(),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                  ),
                                  child: Slider(
                                    value: pct,
                                    onChanged: (v) {
                                      if (dur.inMilliseconds > 0) {
                                        widget.playerService.seek(
                                          Duration(
                                            milliseconds:
                                                (v * dur.inMilliseconds)
                                                    .toInt(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _fmt(pos),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _fmtRemaining(dur, pos),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        /// Apple Music Playback Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            /// Shuffle
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.playerService.toggleShuffle();
                                _showIosToast(
                                  ctx,
                                  widget.playerService.isShuffle
                                      ? 'Shuffle: On'
                                      : 'Shuffle: Off',
                                  icon: CupertinoIcons.shuffle,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  CupertinoIcons.shuffle,
                                  color: widget.playerService.isShuffle
                                      ? const Color(0xFFFA2D48)
                                      : Colors.white.withValues(alpha: 0.50),
                                  size: 22,
                                ),
                              ),
                            ),

                            /// Previous
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.playerService.playPrevious();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  CupertinoIcons.backward_fill,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),

                            /// Play / Pause (Large iconic Apple Music glyph)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.playerService.togglePlayPause();
                              },
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: Center(
                                  child: widget.playerService.isLoading
                                      ? const CupertinoActivityIndicator(
                                          radius: 18,
                                          color: Colors.white,
                                        )
                                      : Icon(
                                          widget.playerService.isPlaying
                                              ? CupertinoIcons.pause_fill
                                              : CupertinoIcons.play_fill,
                                          color: Colors.white,
                                          size: 52,
                                        ),
                                ),
                              ),
                            ),

                            /// Next
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.playerService.playNext();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  CupertinoIcons.forward_fill,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),

                            /// Repeat (Off -> All -> One -> Off)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.playerService.toggleRepeat();
                                final String msg;
                                final IconData ic;
                                switch (widget.playerService.repeatMode) {
                                  case MusicRepeatMode.off:
                                    msg = 'Repeat: Off';
                                    ic = CupertinoIcons.repeat;
                                    break;
                                  case MusicRepeatMode.all:
                                    msg = 'Repeat: All';
                                    ic = CupertinoIcons.repeat;
                                    break;
                                  case MusicRepeatMode.one:
                                    msg = 'Repeat: One';
                                    ic = CupertinoIcons.repeat_1;
                                    break;
                                }
                                _showIosToast(ctx, msg, icon: ic);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  widget.playerService.repeatMode ==
                                          MusicRepeatMode.one
                                      ? CupertinoIcons.repeat_1
                                      : CupertinoIcons.repeat,
                                  color:
                                      widget.playerService.repeatMode ==
                                          MusicRepeatMode.off
                                      ? Colors.white.withValues(alpha: 0.50)
                                      : const Color(0xFFFA2D48),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        /// Interactive Volume Slider
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.speaker_fill,
                              color: Colors.white.withValues(alpha: 0.40),
                              size: 14,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white.withValues(
                                    alpha: 0.70,
                                  ),
                                  inactiveTrackColor: Colors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                  thumbColor: Colors.white,
                                  trackHeight: 3,
                                  trackShape:
                                      const RoundedRectSliderTrackShape(),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10,
                                  ),
                                ),
                                child: Slider(
                                  value: widget.playerService.volume,
                                  onChanged: (v) {
                                    widget.playerService.setVolume(v);
                                  },
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.speaker_3_fill,
                              color: Colors.white.withValues(alpha: 0.40),
                              size: 16,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// Bottom Actions: Lyrics | AutoMix | Queue (Liquid Glass)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _BottomAction(
                              icon: CupertinoIcons.quote_bubble,
                              label: 'Lyrics',
                              active: _centerViewMode == CenterViewMode.lyrics,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _centerViewMode =
                                      _centerViewMode == CenterViewMode.lyrics
                                      ? CenterViewMode.artwork
                                      : CenterViewMode.lyrics;
                                });
                              },
                            ),
                            _BottomAction(
                              icon: CupertinoIcons.sparkles,
                              label: 'AutoMix',
                              active: isAutoMix,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.playerService.toggleAutoMix();
                              },
                            ),
                            _BottomAction(
                              icon: CupertinoIcons.list_bullet,
                              label: 'Queue',
                              active: _centerViewMode == CenterViewMode.queue,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _centerViewMode =
                                      _centerViewMode == CenterViewMode.queue
                                      ? CenterViewMode.artwork
                                      : CenterViewMode.queue;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows contextual options for the current song in a frosted liquid glass sheet.
  void _showOptionsMenu(BuildContext ctx, SongModel song, bool isPinned) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181A).withValues(alpha: 0.78),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.0,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OptionTile(
                      icon: CupertinoIcons.share,
                      label: 'Share Song',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showIosToast(
                          ctx,
                          'Share unavailable',
                          icon: CupertinoIcons.share,
                        );
                      },
                    ),
                    _OptionTile(
                      icon: isPinned
                          ? CupertinoIcons.pin_fill
                          : CupertinoIcons.pin,
                      label: isPinned ? 'Unpin Song' : 'Pin Song',
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.playerService.togglePinSong(song);
                      },
                    ),
                    _OptionTile(
                      icon: CupertinoIcons.music_note_list,
                      label: 'Add to Playlist',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showIosToast(
                          ctx,
                          'Added to playlist',
                          icon: CupertinoIcons.checkmark_circle,
                        );
                      },
                    ),
                    _OptionTile(
                      icon: CupertinoIcons.compass,
                      label: 'Open on YouTube',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showIosToast(
                          ctx,
                          'Opening YouTube…',
                          icon: CupertinoIcons.compass,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Liquid glass bottom action button in Now Playing sheet.
class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFA2D48).withValues(alpha: 0.28)
                      : Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? const Color(0xFFFA2D48).withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.14),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  color: active ? const Color(0xFFFA2D48) : Colors.white60,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFFA2D48) : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet option tile with Cupertino styling.
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

/// Liquid glass synchronized lyrics view with real-time autoscroll & tap-to-seek.
class _LyricsView extends StatefulWidget {
  final SongModel song;
  final AudioPlayerService playerService;
  final VoidCallback onDismiss;

  const _LyricsView({
    super.key,
    required this.song,
    required this.playerService,
    required this.onDismiss,
  });

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  LyricsResult? _result;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(covariant _LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _loadLyrics();
    }
  }

  Future<void> _loadLyrics() async {
    setState(() => _isLoading = true);
    final res = await LyricsService.fetchLyrics(widget.song);
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int idx) {
    if (!_scrollController.hasClients) return;
    final targetOffset = (idx * 60.0) - 90.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151517).withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              /// Liquid Glass Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 10),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.quote_bubble_fill,
                      color: Color(0xFFFA2D48),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lyrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              /// Lyrics Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                          color: Colors.white,
                        ),
                      )
                    : _result == null || _result!.lines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.mic_slash,
                                size: 38,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Lyrics Not Available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Synced lyrics could not be found for this track.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : StreamBuilder<Duration>(
                        stream: widget.playerService.positionStream,
                        builder: (context, snap) {
                          final currentPos = snap.data ?? Duration.zero;

                          int activeIdx = -1;
                          if (_result!.isSynced) {
                            for (int i = 0; i < _result!.lines.length; i++) {
                              if (currentPos >= _result!.lines[i].timestamp) {
                                activeIdx = i;
                              } else {
                                break;
                              }
                            }
                            if (activeIdx != _lastActiveIndex &&
                                activeIdx >= 0) {
                              _lastActiveIndex = activeIdx;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollToIndex(activeIdx);
                              });
                            }
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            itemCount: _result!.lines.length,
                            itemBuilder: (context, i) {
                              final line = _result!.lines[i];
                              final isActive =
                                  _result!.isSynced && i == activeIdx;

                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  if (_result!.isSynced) {
                                    widget.playerService.seek(line.timestamp);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    line.text,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.38,
                                            ),
                                      fontSize: isActive ? 22 : 18,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      letterSpacing: -0.3,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liquid glass Up Next / Playing Next queue view with reordering and removal.
class _QueueView extends StatelessWidget {
  final AudioPlayerService playerService;
  final VoidCallback onDismiss;

  const _QueueView({
    super.key,
    required this.playerService,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final queue = playerService.queue;
    final currentSong = playerService.currentSong;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151517).withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              /// Liquid Glass Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 10),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.list_bullet,
                      color: Color(0xFFFA2D48),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Playing Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${queue.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (queue.length > 1) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          playerService.clearUpcomingQueue();
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Color(0xFFFA2D48),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              /// Queue List
              Expanded(
                child: queue.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.music_albums,
                              size: 38,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Queue is Empty',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'AutoMix will automatically discover related songs',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.50),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: queue.length,
                          onReorderItem: (oldIdx, newIdx) {
                            HapticFeedback.selectionClick();
                            playerService.reorderQueue(oldIdx, newIdx);
                          },
                          itemBuilder: (context, i) {
                            final s = queue[i];
                            final isCurrent =
                                currentSong != null && currentSong.id == s.id;

                            return Container(
                              key: ValueKey('queue_${s.id}_$i'),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: s.thumbnailUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.white12,
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? const Color(0xFFFA2D48)
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  s.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        playerService.removeFromQueue(i);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          CupertinoIcons.minus_circle,
                                          color: Colors.white.withValues(
                                            alpha: 0.35,
                                          ),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          CupertinoIcons.bars,
                                          color: Colors.white.withValues(
                                            alpha: 0.35,
                                          ),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (!isCurrent) {
                                    HapticFeedback.lightImpact();
                                    playerService.playSong(s);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
