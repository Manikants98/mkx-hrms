import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../constants/music_constants.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../services/youtube_music_service.dart';
import '../widgets/now_playing_sheet.dart';
import '../widgets/play_bar_pill.dart';
import 'home_tab_screen.dart';
import 'library_screen.dart';
import 'radio_screen.dart';

/// Apple Music main container screen implementing iOS 27 liquid glass architecture and modular tab routing.
class MusicHomeScreen extends StatefulWidget {
  /// Constructor for MusicHomeScreen.
  const MusicHomeScreen({super.key});

  @override
  State<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends State<MusicHomeScreen> {
  final YouTubeMusicService _musicService = YouTubeMusicService();
  late final AudioPlayerService _playerService;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _radioScrollController = ScrollController();
  final ScrollController _libraryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _searchDebounce;
  bool _isMiniMode = false;
  bool _isSearching = false;
  bool _searchFieldFocused = false;
  int _selectedTab = 0;

  /// Seed initial tracks to ensure instant rendering on cold launch with zero latency.
  late List<SongModel> _trendingSongs;
  List<SongModel> _categorySongs = [];
  List<SongModel> _searchResults = [];
  bool _isLoadingTrending = false;
  bool _isLoadingCategory = false;
  bool _isSearchingYoutube = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<GlassTab> _kTabs = [
    GlassTab(
      label: 'Home',
      icon: Icon(CupertinoIcons.house),
      activeIcon: Icon(CupertinoIcons.house_fill),
    ),
    GlassTab(
      label: 'Radio',
      icon: Icon(CupertinoIcons.antenna_radiowaves_left_right),
    ),
    GlassTab(
      label: 'Library',
      icon: Icon(CupertinoIcons.music_albums),
      activeIcon: Icon(CupertinoIcons.music_albums_fill),
    ),
  ];

  ScrollController get _activeScrollController => switch (_selectedTab) {
    1 => _radioScrollController,
    2 => _libraryScrollController,
    _ => _scrollController,
  };

  @override
  void initState() {
    super.initState();
    _trendingSongs = List<SongModel>.from(kInitialCuratedSongs);
    _playerService = AudioPlayerService(musicService: _musicService);
    _scrollController.addListener(_onScroll);
    _radioScrollController.addListener(_onScroll);
    _libraryScrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onFocusChange);
    _loadTrendingMusic();
  }

  void _onScroll() {
    final ctrl = _activeScrollController;
    final mini = ctrl.hasClients && ctrl.offset > 50;
    if (mini == _isMiniMode) return;
    setState(() => _isMiniMode = mini);
  }

  void _onFocusChange() {
    setState(() => _searchFieldFocused = _searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _radioScrollController
      ..removeListener(_onScroll)
      ..dispose();
    _libraryScrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchFocusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _searchController.dispose();
    _playerService.dispose();
    _musicService.dispose();
    super.dispose();
  }

  LiquidGlassSettings get _barGlassSettings => LiquidGlassSettings(
    glassColor: CupertinoTheme.of(context).brightness == Brightness.dark
        ? const Color(0xAA1C1C1E)
        : const Color(0xAAF2F2F7),
    thickness: 30,
    blur: 2,
    chromaticAberration: 0.01,
    lightAngle: GlassDefaults.lightAngle,
    lightIntensity: 0.2,
    ambientStrength: 0,
    refractiveIndex: 1.2,
    fresnelStrength: 0.0,
    saturation: 1.2,
    specularSharpness: GlassSpecularSharpness.medium,
  );

  void _dismissMiniMode() {
    final ctrl = _activeScrollController;
    if (ctrl.hasClients) {
      ctrl.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    }
    setState(() {
      _isMiniMode = false;
      _isSearching = false;
      _searchFieldFocused = false;
    });
  }

  Future<void> _loadTrendingMusic() async {
    setState(() => _isLoadingTrending = true);
    try {
      final songs = await _musicService.getTrendingMusic();
      if (mounted && songs.isNotEmpty) {
        setState(() {
          _trendingSongs = songs;
          _isLoadingTrending = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _onCategoryChipTap(String category) async {
    HapticFeedback.selectionClick();
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
      _isLoadingCategory = true;
    });

    if (category == 'All') {
      setState(() => _isLoadingCategory = false);
      return;
    }

    try {
      final songs = await _musicService.getCategoryMusic(category);
      if (mounted) {
        setState(() {
          _categorySongs = songs;
          _isLoadingCategory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategory = false);
    }
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _isSearchingYoutube = false;
      });
      return;
    }

    setState(() {
      _searchQuery = trimmed;
      _isSearchingYoutube = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _musicService.searchMusic(trimmed);
        if (mounted && _searchQuery == trimmed) {
          setState(() {
            _searchResults = results;
            _isSearchingYoutube = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearchingYoutube = false);
      }
    });
  }

  void _openSearchForCategory(String categoryName) {
    HapticFeedback.selectionClick();
    setState(() {
      _isSearching = true;
      _searchFieldFocused = true;
      _searchQuery = categoryName;
    });
    _searchController.text = categoryName;
    _searchFocusNode.requestFocus();
    _onSearchQueryChanged(categoryName);
  }

  void _playSong(SongModel song, List<SongModel> queue) {
    HapticFeedback.mediumImpact();
    _playerService.playSong(song, newQueue: queue);
  }

  @override
  Widget build(BuildContext context) {
    final isIOS =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final sysBottom = isIOS ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;
    final double contentPad =
        kBarH + 2 * kPaddingV + 50.0 + kSpacing + 8.0 + sysBottom;

    return Stack(
      children: [
        GlassScaffold(
          background: ColoredBox(color: kBackground.resolveFrom(context)),
          settings: kPillGlass(context),
          statusBarStyle:
              CupertinoTheme.of(context).brightness == Brightness.dark
              ? GlassStatusBarStyle.light
              : GlassStatusBarStyle.dark,
          topEdgeFade: true,
          bottomEdgeFade: true,
          topEdgeFadeExtent: 0,
          bottomEdgeFadeExtent: 0,
          resizeToAvoidBottomInset: false,
          header: (_selectedTab == 0 && !_isSearching)
              ? _buildListenNowHeader()
              : null,
          headerScrollController: _activeScrollController,
          headerFadeDistance: 30,
          body: GestureDetector(
            onTap: () {
              if (_searchFieldFocused) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
            child: _isSearching
                ? ((_searchQuery.isNotEmpty ||
                          _searchResults.isNotEmpty ||
                          _isSearchingYoutube)
                      ? _buildSearchResultsView(
                          key: const ValueKey('search-results'),
                          contentPad: contentPad,
                        )
                      : _buildSearchBrowseView(
                          key: const ValueKey('search-browse'),
                          contentPad: contentPad,
                        ))
                : IndexedStack(
                    index: _selectedTab.clamp(0, 2),
                    children: [
                      HomeTabScreen(
                        key: const ValueKey('home-tab'),
                        controller: _scrollController,
                        contentPad: contentPad,
                        playerService: _playerService,
                        trendingSongs: _trendingSongs,
                        categorySongs: _categorySongs,
                        selectedCategory: _selectedCategory,
                        isLoadingTrending: _isLoadingTrending,
                        isLoadingCategory: _isLoadingCategory,
                        onCategorySelected: _onCategoryChipTap,
                        onPlaySong: _playSong,
                      ),
                      RadioScreen(
                        key: const ValueKey('radio-tab'),
                        controller: _radioScrollController,
                        contentPad: contentPad,
                        playerService: _playerService,
                        musicService: _musicService,
                      ),
                      LibraryScreen(
                        key: const ValueKey('library-tab'),
                        controller: _libraryScrollController,
                        contentPad: contentPad,
                        playerService: _playerService,
                        onOpenSection: _openSearchForCategory,
                      ),
                    ],
                  ),
          ),
          bottomBar: GlassTabBar.searchable(
            isSearchActive: _isMiniMode || _isSearching,
            bottomAccessoryPlacement: (_isMiniMode && !_isSearching)
                ? GlassTabBarAccessoryPlacement.inline
                : GlassTabBarAccessoryPlacement.expanded,
            selectedIndex: _selectedTab,
            onTabSelected: (index) {
              if (index == _selectedTab && _isMiniMode) {
                _dismissMiniMode();
              } else {
                HapticFeedback.selectionClick();
                final ctrl = switch (index) {
                  1 => _radioScrollController,
                  2 => _libraryScrollController,
                  _ => _scrollController,
                };
                final newMini = ctrl.hasClients && ctrl.offset > 50;
                setState(() {
                  _selectedTab = index;
                  _isMiniMode = newMini;
                  _isSearching = false;
                });
              }
            },
            bottomAccessory: PlayBarPill(
              playerService: _playerService,
              fallbackSong: _trendingSongs.isNotEmpty
                  ? _trendingSongs.first
                  : null,
              onTap: () {
                if (_isMiniMode) {
                  _dismissMiniMode();
                } else if (_playerService.currentSong != null) {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: CupertinoColors.transparent,
                    useSafeArea: true,
                    builder: (_) =>
                        NowPlayingSheet(playerService: _playerService),
                  );
                } else if (_trendingSongs.isNotEmpty) {
                  _playSong(_trendingSongs.first, _trendingSongs);
                }
              },
            ),
            bottomAccessoryHeight: 50.0,
            bottomAccessoryEnabled: !_searchFieldFocused,
            selectedIconColor: kMusicRed,
            unselectedIconColor: CupertinoColors.label
                .resolveFrom(context)
                .withValues(alpha: 0.9),
            indicatorColor: CupertinoColors.label
                .resolveFrom(context)
                .withValues(alpha: 0.20),
            labelFontSize: 10,
            iconSize: 28,
            iconLabelSpacing: 0,
            quality: GlassQuality.premium,
            interactionBehavior: GlassInteractionBehavior.full,
            settings: _barGlassSettings,
            searchConfig: GlassSearchBarConfig(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autoFocusOnExpand: false,
              showsCancelButton: true,
              expandWhenActive: !_isMiniMode || _isSearching,
              hintText: 'Apple Music',
              onSearchToggle: (active) {
                if (active) {
                  setState(() {
                    _isSearching = true;
                    _isMiniMode = false;
                  });
                } else {
                  setState(() {
                    _isSearching = false;
                    _searchFieldFocused = false;
                    _searchQuery = '';
                    _searchResults = [];
                  });
                  _searchController.clear();
                  if (_isMiniMode) _dismissMiniMode();
                }
              },
              onChanged: _onSearchQueryChanged,
              onSubmitted: _onSearchQueryChanged,
              onSearchFocusChanged: (focused) {
                setState(() => _searchFieldFocused = focused);
              },
              onCancelTap: () {
                _searchController.clear();
                setState(() {
                  _isSearching = false;
                  _searchFieldFocused = false;
                  _searchQuery = '';
                  _searchResults = [];
                  _isSearchingYoutube = false;
                });
                if (_isMiniMode) _dismissMiniMode();
              },
              collapsedLogoBuilder: (context) {
                final tab = _kTabs[_selectedTab];
                final iconColor = _isMiniMode && !_isSearching
                    ? kMusicRed
                    : CupertinoColors.label
                          .resolveFrom(context)
                          .withValues(alpha: 0.9);
                final icon = tab.activeIcon ?? tab.icon;
                if (icon is Icon) {
                  return Center(
                    child: Icon(icon.icon, color: iconColor, size: 28),
                  );
                }
                return icon ?? const SizedBox.shrink();
              },
            ),
            tabs: _kTabs,
          ),
        ),
        /// Active YouTube Player iframe placed after Scaffold so PlatformView is in front and not occluded
        Positioned(
          left: 0,
          top: 0,
          width: 200,
          height: 120,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.02,
              child: YoutubePlayer(
                controller: _playerService.ytController,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListenNowHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Listen Now',
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF4C4556),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'MK',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBrowseView({Key? key, required double contentPad}) {
    return CustomScrollView(
      key: key,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top + 8),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.music_note,
                      color: CupertinoColors.label.resolveFrom(context),
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Music',
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Search',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, contentPad),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = kBrowseCategories[index];
              return GestureDetector(
                onTap: () => _openSearchForCategory(category.name),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: category.color,
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: kBrowseCategories.length),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsView({Key? key, required double contentPad}) {
    return CustomScrollView(
      key: key,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top + 8),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_isSearchingYoutube)
                  const CupertinoActivityIndicator(radius: 9),
              ],
            ),
          ),
        ),
        if (!_isSearchingYoutube && _searchResults.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 56,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Results',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching for songs, artists, or genres',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, contentPad),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final song = _searchResults[index];
                final isCurrentlyPlaying =
                    _playerService.currentSong?.id == song.id;

                return GestureDetector(
                  onTap: () => _playSong(song, _searchResults),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentlyPlaying
                          ? kMusicRed.withValues(alpha: 0.12)
                          : kCardGray.resolveFrom(context),
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
                                      : CupertinoColors.label.resolveFrom(
                                          context,
                                        ),
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
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _playerService.togglePinSong(song),
                          child: Icon(
                            _playerService.isPinned(song.id)
                                ? CupertinoIcons.pin_fill
                                : CupertinoIcons.pin,
                            color: _playerService.isPinned(song.id)
                                ? kMusicRed
                                : CupertinoColors.tertiaryLabel.resolveFrom(
                                    context,
                                  ),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isCurrentlyPlaying && _playerService.isPlaying
                              ? CupertinoIcons.pause_circle_fill
                              : CupertinoIcons.play_circle_fill,
                          color: kMusicRed,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _searchResults.length),
            ),
          ),
      ],
    );
  }
}
