import 'package:flutter/widgets.dart';

import '../storage/token_storage.dart';

/**
 * Runtime theme palette choices, adapted for MKX HRMS.
 * Synchronizes and persists user preferences in local storage.
 */
class AppThemeSettings extends ChangeNotifier {
  /** Seed choices offered when dynamic color is off. */
  static const List<Color> seedOptions = <Color>[
    Color(0xFF6750A4),
    Color(0xFF00658F),
    Color(0xFF006D3D),
    Color(0xFF8F4C00),
    Color(0xFFA1003C),
  ];

  /** Labels shown under each entry in [seedOptions]. */
  static const List<String> seedLabels = <String>[
    'Default',
    'Ocean',
    'Forest',
    'Amber',
    'Rose',
  ];

  /** Family name registered for Google Sans Flex. */
  static const String googleSansFlex = 'Google Sans Flex';

  /** Family name registered for Poppins. */
  static const String poppins = 'Poppins';

  bool _autoTheming = true;
  bool _dynamicColoring = true;
  Color _seedColor = seedOptions.first;
  String? _fontFamily = googleSansFlex;

  /**
   * Restores persisted theme settings from local preferences.
   */
  Future<void> loadSettings() async {
    final mode = await TokenStorage.instance.getThemeMode();
    if (mode == 'dark' || mode == 'light') {
      _autoTheming = false;
    } else {
      _autoTheming = await TokenStorage.instance.getAutoTheming();
    }
    _dynamicColoring = await TokenStorage.instance.getDynamicColoring();
    final savedSeed = await TokenStorage.instance.getSeedColor();
    if (savedSeed != null) {
      _seedColor = Color(savedSeed);
    }
    final savedFont = await TokenStorage.instance.getFontFamily();
    if (savedFont != null) {
      _fontFamily = savedFont.isEmpty ? null : savedFont;
    }
    notifyListeners();
  }

  /** Whether the theme follows the platform brightness. */
  bool get autoTheming => _autoTheming;

  set autoTheming(bool value) {
    if (value == _autoTheming) {
      return;
    }
    _autoTheming = value;
    TokenStorage.instance.saveAutoTheming(value);
    notifyListeners();
  }

  /** Whether device dynamic color overrides the seeded scheme. */
  bool get dynamicColoring => _dynamicColoring;

  set dynamicColoring(bool value) {
    if (value == _dynamicColoring) {
      return;
    }
    _dynamicColoring = value;
    TokenStorage.instance.saveDynamicColoring(value);
    notifyListeners();
  }

  /** Seed used to generate the scheme when dynamic color is off. */
  Color get seedColor => _seedColor;

  set seedColor(Color value) {
    if (value == _seedColor) {
      return;
    }
    _seedColor = value;
    TokenStorage.instance.saveSeedColor(value.toARGB32());
    notifyListeners();
  }

  /** Font family for the app, or null for the platform default. */
  String? get fontFamily => _fontFamily;

  set fontFamily(String? value) {
    if (value == _fontFamily) {
      return;
    }
    _fontFamily = value;
    TokenStorage.instance.saveFontFamily(value);
    notifyListeners();
  }
}
