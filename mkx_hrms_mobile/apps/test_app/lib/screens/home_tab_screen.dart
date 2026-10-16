import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../constants/music_constants.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/hero_card.dart';

/// Apple Music Listen Now / Home tab screen with hero banners, categories, and top picks.
class HomeTabScreen extends StatelessWidget {
  /// Scroll controller for the home view.
  final ScrollController controller;

  /// Bottom content padding to avoid overlap with floating glass bar.
  final double contentPad;

  /// Audio player service instance.
  final AudioPlayerService playerService;

  /// Active list of trending songs.
  final List<SongModel> trendingSongs;

  /// Active list of category-filtered songs.
  final List<SongModel> categorySongs;

  /// Currently selected category filter.
  final String selectedCategory;

  /// Whether trending songs are currently loading in background.
  final bool isLoadingTrending;

  /// Whether category songs are currently loading in background.
  final bool isLoadingCategory;

  /// Callback when a category filter is tapped.
  final ValueChanged<String> onCategorySelected;

  /// Callback to play a selected song.
  final void Function(SongModel song, List<SongModel> queue) onPlaySong;

  /// Constructor for HomeTabScreen.
  const HomeTabScreen({
    super.key,
    required this.controller,
    required this.contentPad,
    required this.playerService,
    required this.trendingSongs,
    required this.categorySongs,
    required this.selectedCategory,
    required this.isLoadingTrending,
    required this.isLoadingCategory,
    required this.onCategorySelected,
    required this.onPlaySong,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final activeList = selectedCategory != 'All' ? categorySongs : trendingSongs;

        return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).top + 8 + 50,
          ),
        ),

        /// Hero Card 1 - Vibrant Apple Music Red
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () {
              if (activeList.isNotEmpty) {
                onPlaySong(activeList.first, activeList);
              }
            },
            child: const HeroCard(
              title: 'Music just for you.\n2 months free.',
              subtitle: 'Accept Free Trial',
              subtext: '2 months free, then \$10.99/month',
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF83E4F),
                  Color(0xFFE2072C),
                ],
              ),
              textColor: CupertinoColors.white,
              child: AppleMusicLogo(),
            ),
          ),
        ),

        /// Mood / Category Filter Chips
        SliverToBoxAdapter(
          child: Container(
            height: 44,
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kHomeCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = kHomeCategories[index];
                final isSelected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCategorySelected(cat);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kMusicRed
                          : CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? CupertinoColors.transparent
                            : CupertinoColors.systemGrey4.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? CupertinoColors.white
                            : CupertinoColors.label.resolveFrom(context),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        /// Section: Top Picks / Trending Songs
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCategory == 'All' ? 'Top Picks' : '$selectedCategory Hits',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (isLoadingTrending || isLoadingCategory)
                  const CupertinoActivityIndicator(radius: 9),
              ],
            ),
          ),
        ),

        /// Horizontal Album Carousel of Songs
        if (activeList.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activeList.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final song = activeList[index];
                  return GestureDetector(
                    onTap: () => onPlaySong(song, activeList),
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CachedNetworkImage(
                                imageUrl: song.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                                  child: const Icon(
                                    CupertinoIcons.music_note,
                                    color: CupertinoColors.systemGrey,
                                    size: 32,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                                  child: const Icon(
                                    CupertinoIcons.music_note,
                                    color: CupertinoColors.systemGrey,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CupertinoColors.label.resolveFrom(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
                  );
                },
              ),
            ),
          ),

        /// Hero Card 2 - Spatial Audio / Family
        const SliverToBoxAdapter(
          child: HeroCard(
            title: 'Spatial Audio with\nDolby Atmos.',
            subtitle: 'Immersive Sound',
            subtext: 'Experience sound all around you in studio quality',
            color: Color(0xFF1D1B1E),
            showBorder: true,
            textColor: CupertinoColors.white,
            child: Icon(
              CupertinoIcons.headphones,
              color: kMusicRed,
              size: 110,
            ),
          ),
        ),

        /// Section: Popular Tracks List
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Text(
              'Trending Tracks',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),

        /// Vertical Song Tiles
        if (activeList.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = activeList[index];
                  final isCurrentlyPlaying = playerService.currentSong?.id == song.id;

                  return GestureDetector(
                    onTap: () => onPlaySong(song, activeList),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentlyPlaying
                            ? kMusicRed.withValues(alpha: 0.12)
                            : CupertinoColors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: song.thumbnailUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                width: 48,
                                height: 48,
                                color: CupertinoColors.systemGrey5.resolveFrom(context),
                              ),
                              errorWidget: (_, _, _) => Container(
                                width: 48,
                                height: 48,
                                color: CupertinoColors.systemGrey5.resolveFrom(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrentlyPlaying
                                        ? kMusicRed
                                        : CupertinoColors.label.resolveFrom(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size.square(36),
                            onPressed: () => playerService.togglePinSong(song),
                            child: Icon(
                              playerService.isPinned(song.id)
                                  ? CupertinoIcons.pin_fill
                                  : CupertinoIcons.pin,
                              color: playerService.isPinned(song.id)
                                  ? kMusicRed
                                  : CupertinoColors.tertiaryLabel.resolveFrom(context),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isCurrentlyPlaying && playerService.isPlaying
                                ? CupertinoIcons.pause_circle_fill
                                : CupertinoIcons.play_circle_fill,
                            color: kMusicRed,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: activeList.length,
              ),
            ),
          ),

        SliverToBoxAdapter(child: SizedBox(height: contentPad)),
      ],
    );
      },
    );
  }
}
