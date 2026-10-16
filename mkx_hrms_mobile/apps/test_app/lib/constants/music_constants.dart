import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/song_model.dart';

/// Apple Music Red brand accent color.
const Color kMusicRed = Color(0xFFFF2D55);

/// Background dynamic color adapting between dark and light themes.
const CupertinoDynamicColor kBackground = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFF2F2F7),
  darkColor: Color(0xFF000000),
);

/// Card gray dynamic color for Apple Music items.
const CupertinoDynamicColor kCardGray = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFFFFFFF),
  darkColor: Color(0xFF1C1C1E),
);

/// Bar dimension constants matching iOS 27 Apple Music metrics.
const double kBarH = 64.0;
const double kPaddingH = 20.0;
const double kPaddingV = 16.0;
const double kSpacing = 8.0;

/// Glass settings shared by floating pills.
LiquidGlassSettings kPillGlass(BuildContext context) => LiquidGlassSettings(
  glassColor: CupertinoTheme.of(context).brightness == Brightness.dark
      ? const Color(0x991C1C1E)
      : const Color(0x99FFFFFF),
  thickness: 24,
  blur: 24,
  chromaticAberration: 0.02,
  lightAngle: GlassDefaults.lightAngle,
  lightIntensity: 0.35,
  ambientStrength: 0.0,
  refractiveIndex: 1.3,
  fresnelStrength: 0.0,
  saturation: 1.15,
  specularSharpness: GlassSpecularSharpness.sharp,
);

/// Curated home category chip titles.
const List<String> kHomeCategories = [
  'All',
  'AutoMix',
  'Spatial Audio',
  'Lo-Fi Chill',
  'Pop Hits',
  'Bollywood',
  'EDM',
  'Rock',
];

/// Curated radio stations with name, genre, and icon.
const List<(String, String, IconData)> kRadioStations = [
  ('Apple Music 1', 'Global Pop', CupertinoIcons.dot_radiowaves_left_right),
  ('Apple Music Country', 'Country Hits', CupertinoIcons.music_note_2),
  ('Apple Music Hits', 'All-Time Favorites', CupertinoIcons.star_fill),
  ('Beats 1 Classics', 'Throwbacks', CupertinoIcons.clock_fill),
  ('Chill Mix', 'Lo-Fi & Ambient', CupertinoIcons.moon_fill),
  ('Workout Mix', 'High Energy', CupertinoIcons.bolt_fill),
  ('Late Night', 'R&B & Soul', CupertinoIcons.moon_stars_fill),
  ('Discover', 'New Artists', CupertinoIcons.wand_stars),
];

/// Curated library section titles.
const List<String> kLibrarySections = [
  'Recently Added',
  'Artists',
  'Albums',
  'Songs',
  'Playlists',
  'Music Videos',
  'Compilations',
  'Downloaded',
];

/// Category representation for the browse grid.
class BrowseCategory {
  /// Constructor for BrowseCategory.
  const BrowseCategory({required this.name, required this.color});

  /// Category title.
  final String name;

  /// Card accent color.
  final Color color;
}

/// Curated Apple Music categories for the Search Browse view.
const List<BrowseCategory> kBrowseCategories = [
  BrowseCategory(name: 'Pop', color: Color(0xFFFF2D55)),
  BrowseCategory(name: 'Hip-Hop', color: Color(0xFF5856D6)),
  BrowseCategory(name: 'Rock', color: Color(0xFF636366)),
  BrowseCategory(name: 'Electronic', color: Color(0xFF007AFF)),
  BrowseCategory(name: 'R&B / Soul', color: Color(0xFFAF52DE)),
  BrowseCategory(name: 'Country', color: Color(0xFFFF9500)),
  BrowseCategory(name: 'Jazz', color: Color(0xFF30B0C7)),
  BrowseCategory(name: 'Classical', color: Color(0xFF34C759)),
  BrowseCategory(name: 'Latin', color: Color(0xFFFFCC00)),
  BrowseCategory(name: 'Bollywood', color: Color(0xFFFF3B30)),
  BrowseCategory(name: 'Lo-Fi Chill', color: Color(0xFF5E5CE6)),
  BrowseCategory(name: 'Alternative', color: Color(0xFF1C1C1E)),
];

/// Curated seed tracks ensuring instantaneous rendering on cold launch with zero latency.
final List<SongModel> kInitialCuratedSongs = [
  SongModel(
    id: '60ItHLz5WEA',
    title: 'Alan Walker - Faded',
    artist: 'Alan Walker',
    thumbnailUrl: 'https://i.ytimg.com/vi/60ItHLz5WEA/hqdefault.jpg',
    duration: '03:32',
  ),
  SongModel(
    id: '2zToEPp4WAo',
    title: 'Cartoon - On & On (feat. Daniel Levi)',
    artist: 'NCS',
    thumbnailUrl: 'https://i.ytimg.com/vi/2zToEPp4WAo/hqdefault.jpg',
    duration: '03:28',
  ),
  SongModel(
    id: 'yJg-Y5byMMw',
    title: 'Janji - Heroes Tonight (feat. Johnning)',
    artist: 'NCS',
    thumbnailUrl: 'https://i.ytimg.com/vi/yJg-Y5byMMw/hqdefault.jpg',
    duration: '03:28',
  ),
  SongModel(
    id: 'mAKsZ26SabQ',
    title: 'Lost Sky - Fearless pt.II (feat. Chris Linton)',
    artist: 'NCS',
    thumbnailUrl: 'https://i.ytimg.com/vi/mAKsZ26SabQ/hqdefault.jpg',
    duration: '03:14',
  ),
  SongModel(
    id: 'p7ZsBPK656s',
    title: 'Elektronomia - Sky High',
    artist: 'NCS',
    thumbnailUrl: 'https://i.ytimg.com/vi/p7ZsBPK656s/hqdefault.jpg',
    duration: '03:57',
  ),
  SongModel(
    id: 'n8X9_MgEdCg',
    title: 'TheFatRat - Unity',
    artist: 'TheFatRat',
    thumbnailUrl: 'https://i.ytimg.com/vi/n8X9_MgEdCg/hqdefault.jpg',
    duration: '04:09',
  ),
];
