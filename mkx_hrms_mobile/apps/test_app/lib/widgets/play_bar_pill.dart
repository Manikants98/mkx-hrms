import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/music_constants.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';

/// Glass play bar pill accessory in expanded and inline modes matching iOS 27 design.
class PlayBarPill extends StatelessWidget {
  /// Audio player service instance.
  final AudioPlayerService playerService;

  /// Optional fallback song model.
  final SongModel? fallbackSong;

  /// On tap callback.
  final VoidCallback? onTap;

  /// Constructor for PlayBarPill.
  const PlayBarPill({
    super.key,
    required this.playerService,
    this.fallbackSong,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final song = playerService.currentSong ?? fallbackSong;
        final isPlaying = playerService.isPlaying;
        final isLoading = playerService.isLoading;

        return GlassButton.custom(
          onTap: onTap ?? () {},
          quality: GlassQuality.premium,
          useOwnLayer: true,
          width: double.infinity,
          height: kBarH,
          shape: const LiquidRoundedRectangle(borderRadius: kBarH / 2),
          settings: kPillGlass(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song != null
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _albumPlaceholder(context),
                          errorWidget: (_, _, _) => _albumPlaceholder(context),
                        )
                      : _albumPlaceholder(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song?.title ?? 'Apple Music',
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song?.artist ?? 'Tap to play trending music',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(36),
                  onPressed: () {
                    if (playerService.currentSong != null) {
                      playerService.togglePlayPause();
                    } else if (fallbackSong != null) {
                      playerService.playSong(fallbackSong!);
                    }
                  },
                  child: isLoading
                      ? const CupertinoActivityIndicator(radius: 10)
                      : Icon(
                          isPlaying
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          color: CupertinoColors.label.resolveFrom(context),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(36),
                  onPressed: () {
                    playerService.playNext();
                  },
                  child: Icon(
                    CupertinoIcons.forward_end_fill,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _albumPlaceholder(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFA2D48), Color(0xFFE2072C)],
        ),
      ),
      child: const Icon(
        CupertinoIcons.music_note,
        color: CupertinoColors.white,
        size: 18,
      ),
    );
  }
}
