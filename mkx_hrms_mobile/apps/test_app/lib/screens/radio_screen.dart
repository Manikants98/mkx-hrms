import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../constants/music_constants.dart';
import '../services/audio_player_service.dart';
import '../services/youtube_music_service.dart';

/// Apple Music Radio tab screen with stations, live broadcasts, and genres.
class RadioScreen extends StatelessWidget {
  /// Scroll controller for the radio view.
  final ScrollController controller;

  /// Bottom content padding to avoid overlap with floating glass bar.
  final double contentPad;

  /// Audio player service instance.
  final AudioPlayerService playerService;

  /// YouTube music service instance.
  final YouTubeMusicService musicService;

  /// Constructor for RadioScreen.
  const RadioScreen({
    super.key,
    required this.controller,
    required this.contentPad,
    required this.playerService,
    required this.musicService,
  });

  Future<void> _playRadioStation(
    BuildContext context,
    String name,
    String genre,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      final results = await musicService.searchMusic(
        '$name $genre music radio hits',
        maxResults: 15,
      );
      if (results.isNotEmpty) {
        playerService.playSong(results.first, newQueue: results);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('radio-scroll'),
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).top + 8,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 20),
            child: Text(
              'Radio',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, contentPad),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final station = kRadioStations[i % kRadioStations.length];
                return GestureDetector(
                  onTap: () => _playRadioStation(context, station.$1, station.$2),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 72,
                    decoration: BoxDecoration(
                      color: kCardGray.resolveFrom(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: kMusicRed.withValues(alpha: 0.85),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(14),
                            ),
                          ),
                          child: Icon(
                            station.$3,
                            color: CupertinoColors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                station.$1,
                                style: TextStyle(
                                  color: CupertinoColors.label.resolveFrom(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                station.$2,
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(
                            CupertinoIcons.play_circle_fill,
                            color: kMusicRed,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: kRadioStations.length * 2,
            ),
          ),
        ),
      ],
    );
  }
}
