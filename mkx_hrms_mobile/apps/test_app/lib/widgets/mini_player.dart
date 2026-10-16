import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';
import 'now_playing_sheet.dart';

/// Floating Apple Music iOS 26 frosted-glass mini player island.
class MiniPlayer extends StatelessWidget {
  /// Reference to the audio player service.
  final AudioPlayerService playerService;

  /// Constructor for MiniPlayer.
  const MiniPlayer({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final song = playerService.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (_) => NowPlayingSheet(playerService: playerService),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.8),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      /// Thin progress bar at very top
                      StreamBuilder<Duration>(
                        stream: playerService.positionStream,
                        builder: (context, snap) {
                          final pos = snap.data ?? Duration.zero;
                          final dur = playerService.totalDuration;
                          final pct = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 2,
                              backgroundColor: Colors.white.withValues(alpha: 0.07),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFA2D48)),
                            ),
                          );
                        },
                      ),

                      /// Content Row
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              /// Artwork
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: song.thumbnailUrl,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                  placeholder: (_, url) => Container(width: 42, height: 42, color: Colors.white10, child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20)),
                                  errorWidget: (_, url, error) => Container(width: 42, height: 42, color: Colors.white10, child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20)),
                                ),
                              ),
                              const SizedBox(width: 12),

                              /// Title + Artist
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                                    Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                                  ],
                                ),
                              ),

                              /// Play / Pause
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: playerService.togglePlayPause,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: playerService.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFA2D48))),
                                        )
                                      : Icon(
                                          playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                ),
                              ),

                              /// Next
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: playerService.playNext,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 4, right: 6),
                                  child: Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
