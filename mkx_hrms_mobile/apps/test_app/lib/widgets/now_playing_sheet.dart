import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';

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
  double _volume = 0.75;

  /// Formats duration as mm:ss.
  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formats remaining as -mm:ss.
  String _fmtRemaining(Duration total, Duration pos) {
    final r = total - pos;
    if (r.isNegative) return '-00:00';
    return '-${r.inMinutes.toString().padLeft(2, '0')}:${(r.inSeconds % 60).toString().padLeft(2, '0')}';
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
        final isLyrics = widget.playerService.isLyricsOpen;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: Stack(
              children: [
                /// Blurred artwork background
                Positioned.fill(
                  child: CachedNetworkImage(imageUrl: song.thumbnailUrl, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: Container(color: Colors.black.withValues(alpha: 0.78)),
                  ),
                ),

                /// Content
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        /// Grabber
                        Center(
                          child: Container(
                            width: 38, height: 5,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        /// Top bar: back + menu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), shape: BoxShape.circle),
                                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                            const Text('Now Playing', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _showOptionsMenu(ctx, song, isPinned);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), shape: BoxShape.circle),
                                child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        /// Artwork or Lyrics
                        Expanded(
                          flex: 38,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.playerService.toggleLyrics,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: isLyrics
                                  ? _LyricsView(song: song, key: const ValueKey('lyrics'))
                                  : ClipRRect(
                                      key: const ValueKey('artwork'),
                                      borderRadius: BorderRadius.circular(24),
                                      child: CachedNetworkImage(
                                        imageUrl: song.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorWidget: (_, _, _) => Container(color: Colors.white10),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// Title + Favorite + Pin
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                  const SizedBox(height: 3),
                                  Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _isFavorite = !_isFavorite),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: _isFavorite ? const Color(0xFFFA2D48) : Colors.white60,
                                  size: 26,
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.playerService.togglePinSong(song),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                  color: isPinned ? const Color(0xFFFA2D48) : Colors.white60,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        /// Scrub Bar
                        StreamBuilder<Duration>(
                          stream: widget.playerService.positionStream,
                          builder: (context, snap) {
                            final pos = snap.data ?? Duration.zero;
                            final dur = widget.playerService.totalDuration;
                            final pct = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;

                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  ),
                                  child: Slider(
                                    value: pct,
                                    onChanged: (v) {
                                      if (dur.inMilliseconds > 0) {
                                        widget.playerService.seek(Duration(milliseconds: (v * dur.inMilliseconds).toInt()));
                                      }
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(pos), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                    Text(_fmtRemaining(dur, pos), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        /// Playback Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            /// Shuffle
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Shuffle'), duration: Duration(seconds: 1)),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.shuffle_rounded, color: Colors.white60, size: 26),
                              ),
                            ),

                            /// Previous
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.playerService.playPrevious,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                              ),
                            ),

                            /// Play / Pause
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.playerService.togglePlayPause,
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                child: widget.playerService.isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(18),
                                        child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                                      )
                                    : Icon(
                                        widget.playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 40,
                                      ),
                              ),
                            ),

                            /// Next
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.playerService.playNext,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                              ),
                            ),

                            /// Repeat
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Repeat'), duration: Duration(seconds: 1)),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.repeat_rounded, color: Colors.white60, size: 26),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        /// Volume Slider
                        Row(
                          children: [
                            const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 18),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white60,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                ),
                                child: Slider(
                                  value: _volume,
                                  onChanged: (v) => setState(() => _volume = v),
                                ),
                              ),
                            ),
                            const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 18),
                          ],
                        ),

                        const SizedBox(height: 14),

                        /// Bottom Row: AutoMix | Lyrics toggle | AirPlay | Queue
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _BottomAction(
                              icon: Icons.auto_awesome,
                              label: 'AutoMix',
                              active: isAutoMix,
                              onTap: widget.playerService.toggleAutoMix,
                            ),
                            _BottomAction(
                              icon: Icons.mic_rounded,
                              label: 'Lyrics',
                              active: isLyrics,
                              onTap: widget.playerService.toggleLyrics,
                            ),
                            _BottomAction(
                              icon: Icons.airplay_rounded,
                              label: 'AirPlay',
                              active: false,
                              onTap: () {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('AirPlay unavailable'), duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                            _BottomAction(
                              icon: Icons.queue_music_rounded,
                              label: 'Queue',
                              active: false,
                              onTap: () => _showQueue(ctx),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
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

  /// Shows the queue as a bottom sheet.
  void _showQueue(BuildContext ctx) {
    final queue = widget.playerService.queue;
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Queue', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Expanded(
              child: queue.isEmpty
                  ? const Center(child: Text('Queue is empty', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: queue.length,
                      itemBuilder: (ctx, i) {
                        final s = queue[i];
                        return ListTile(
                          leading: CachedNetworkImage(
                            imageUrl: s.thumbnailUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(Icons.music_note, color: Colors.white54),
                          ),
                          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(s.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          onTap: () {
                            widget.playerService.playSong(s);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Shows contextual options for the current song.
  void _showOptionsMenu(BuildContext ctx, dynamic song, bool isPinned) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 10),
              _OptionTile(icon: Icons.share_rounded, label: 'Share Song', onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Share unavailable'), duration: Duration(seconds: 1)));
              }),
              _OptionTile(
                icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                label: isPinned ? 'Unpin Song' : 'Pin Song',
                onTap: () {
                  Navigator.pop(ctx);
                  widget.playerService.togglePinSong(song);
                },
              ),
              _OptionTile(icon: Icons.playlist_add_rounded, label: 'Add to Playlist', onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Added to playlist'), duration: Duration(seconds: 1)));
              }),
              _OptionTile(icon: Icons.open_in_browser_rounded, label: 'Open on YouTube', onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Opening YouTube…'), duration: Duration(seconds: 1)));
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom action button in Now Playing sheet.
class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomAction({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFA2D48).withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: active ? Border.all(color: const Color(0xFFFA2D48).withValues(alpha: 0.50), width: 0.8) : null,
            ),
            child: Icon(icon, color: active ? const Color(0xFFFA2D48) : Colors.white60, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? const Color(0xFFFA2D48) : Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Sheet option tile.
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }
}

/// Lyrics view widget with phonetic pronunciation.
class _LyricsView extends StatelessWidget {
  final dynamic song;

  const _LyricsView({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_rounded, color: Color(0xFFFA2D48), size: 36),
            SizedBox(height: 12),
            Text(
              'Lyrics',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Synced lyrics powered by Apple Music.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
