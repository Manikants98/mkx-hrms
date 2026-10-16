import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../constants/music_constants.dart';
import '../services/audio_player_service.dart';

/// Apple Music Library tab screen with pinned tracks, playlists, and sections.
class LibraryScreen extends StatelessWidget {
  /// Scroll controller for the library view.
  final ScrollController controller;

  /// Bottom content padding to avoid overlap with floating glass bar.
  final double contentPad;

  /// Audio player service instance.
  final AudioPlayerService playerService;

  /// Callback when a library section is tapped.
  final ValueChanged<String>? onOpenSection;

  /// Constructor for LibraryScreen.
  const LibraryScreen({
    super.key,
    required this.controller,
    required this.contentPad,
    required this.playerService,
    this.onOpenSection,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final pinned = playerService.pinnedSongs;

        return CustomScrollView(
          key: const PageStorageKey('library-scroll'),
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
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Text(
                  'Library',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            /// Pinned tracks section (iOS 26 feature)
            if (pinned.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                  child: Text(
                    'Pinned Tracks',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final song = pinned[i];
                      return GestureDetector(
                        onTap: () => playerService.playSong(song, newQueue: pinned),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: kCardGray.resolveFrom(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: song.thumbnailUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: CupertinoColors.label.resolveFrom(context),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => playerService.togglePinSong(song),
                                child: const Icon(
                                  CupertinoIcons.pin_fill,
                                  color: kMusicRed,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: pinned.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            /// Standard Apple Music Library navigation sections
            SliverPadding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, contentPad),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final title = kLibrarySections[i % kLibrarySections.length];
                    return GestureDetector(
                      onTap: () {
                        if (onOpenSection != null) {
                          onOpenSection!(title);
                        }
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.music_albums_fill,
                                  color: kMusicRed,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: CupertinoColors.label.resolveFrom(context),
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_forward,
                                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 0.33,
                            margin: const EdgeInsets.only(left: 56),
                            color: CupertinoColors.label.resolveFrom(context).withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: kLibrarySections.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
