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

/// Curated home category chip titles: strictly official Hindi, English, Punjabi, Haryanvi.
const List<String> kHomeCategories = [
  'All',
  'Hindi',
  'English',
  'Punjabi',
  'Haryanvi',
];

/// Curated radio stations with name, genre, and icon.
const List<(String, String, IconData)> kRadioStations = [
  ('Apple Music 1', 'Global Hits', CupertinoIcons.dot_radiowaves_left_right),
  ('Hindi Hits Radio', 'Bollywood & Indie', CupertinoIcons.music_note_2),
  ('Punjabi Waves', 'Desi & Bhangra', CupertinoIcons.star_fill),
  ('Haryanvi Beats', 'Folk & Dhaakad', CupertinoIcons.bolt_fill),
  ('English Pop Radio', 'Billboard Top 40', CupertinoIcons.wand_stars),
  ('Late Night Chill', 'Acoustic & Soul', CupertinoIcons.moon_stars_fill),
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
  BrowseCategory(name: 'Hindi Official', color: Color(0xFFFF2D55)),
  BrowseCategory(name: 'English Hits', color: Color(0xFF007AFF)),
  BrowseCategory(name: 'Punjabi Hits', color: Color(0xFFFF9500)),
  BrowseCategory(name: 'Haryanvi Dhaakad', color: Color(0xFF34C759)),
  BrowseCategory(name: 'Bollywood Romance', color: Color(0xFFAF52DE)),
  BrowseCategory(name: 'Global Billboard', color: Color(0xFF5856D6)),
  BrowseCategory(name: 'Punjabi Bhangra', color: Color(0xFFFFCC00)),
  BrowseCategory(name: 'Haryanvi Folk & Beats', color: Color(0xFF30B0C7)),
];

/// Curated seed tracks ensuring instantaneous rendering on cold launch with verified official songs.
final List<SongModel> kInitialCuratedSongs = [
  SongModel(
    id: 'BddP6PYo2gs',
    title: 'Kesariya',
    artist: 'Arijit Singh (Sony Music India)',
    thumbnailUrl: 'https://i.ytimg.com/vi/BddP6PYo2gs/hqdefault.jpg',
    duration: '04:28',
  ),
  SongModel(
    id: '4NRXx6U8ABQ',
    title: 'Blinding Lights',
    artist: 'The Weeknd (Official Video)',
    thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
    duration: '04:22',
  ),
  SongModel(
    id: 'mH_LFkWxpI0',
    title: 'Lover',
    artist: 'Diljit Dosanjh (Official Video)',
    thumbnailUrl: 'https://i.ytimg.com/vi/mH_LFkWxpI0/hqdefault.jpg',
    duration: '03:31',
  ),
  SongModel(
    id: 'tJGBVigwPlU',
    title: 'Moto',
    artist: 'Diler Kharkiya (Saga Music Haryanvi)',
    thumbnailUrl: 'https://i.ytimg.com/vi/tJGBVigwPlU/hqdefault.jpg',
    duration: '03:45',
  ),
  SongModel(
    id: 'gJLVTKhTnog',
    title: 'Husn',
    artist: 'Anuv Jain (Official)',
    thumbnailUrl: 'https://i.ytimg.com/vi/gJLVTKhTnog/hqdefault.jpg',
    duration: '03:38',
  ),
  SongModel(
    id: 'cWMxCE2HTag',
    title: 'Softly',
    artist: 'Karan Aujla (Official Video)',
    thumbnailUrl: 'https://i.ytimg.com/vi/cWMxCE2HTag/hqdefault.jpg',
    duration: '02:35',
  ),
  SongModel(
    id: 'CZt-rVn2BJs',
    title: '52 Gaj Ka Daman',
    artist: 'Renuka Panwar (Desi Records)',
    thumbnailUrl: 'https://i.ytimg.com/vi/CZt-rVn2BJs/hqdefault.jpg',
    duration: '03:08',
  ),
  SongModel(
    id: 'TUVcZfQe-Kw',
    title: 'Levitating',
    artist: 'Dua Lipa (Official Music Video)',
    thumbnailUrl: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
    duration: '03:50',
  ),
];
