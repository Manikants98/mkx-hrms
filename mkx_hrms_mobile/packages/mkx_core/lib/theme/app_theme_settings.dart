import 'package:flutter/widgets.dart';

/// Runtime theme palette choices, adapted for MKX HRMS.
///
/// Notifies so the root app can rebuild with the new values.
class AppThemeSettings extends ChangeNotifier {
  /// Seed choices offered when dynamic color is off.
  static const List<Color> seedOptions = <Color>[
    Color(0xFF6750A4), // Default Purple
    Color(0xFF00658F), // Ocean Blue
    Color(0xFF006D3D), // Forest Green
    Color(0xFF8F4C00), // Amber
    Color(0xFFA1003C), // Rose
  ];

  /// Labels shown under each entry in [seedOptions].
  static const List<String> seedLabels = <String>[
    'Default',
    'Ocean',
    'Forest',
    'Amber',
    'Rose',
  ];

  /// Family name registered for Google Sans Flex.
  static const String googleSansFlex = 'Google Sans Flex';

  /// Family name registered for Poppins.
  static const String poppins = 'Poppins';

  bool _autoTheming = true;
  bool _dynamicColoring = true;
  Color _seedColor = seedOptions.first;
  String? _fontFamily = googleSansFlex;

  /// Whether the theme follows the platform brightness.
  bool get autoTheming => _autoTheming;

  set autoTheming(bool value) {
    if (value == _autoTheming) {
      return;
    }
    _autoTheming = value;
    notifyListeners();
  }

  /// Whether device dynamic color overrides the seeded scheme.
  bool get dynamicColoring => _dynamicColoring;

  set dynamicColoring(bool value) {
    if (value == _dynamicColoring) {
      return;
    }
    _dynamicColoring = value;
    notifyListeners();
  }

  /// Seed used to generate the scheme when dynamic color is off.
  Color get seedColor => _seedColor;

  set seedColor(Color value) {
    if (value == _seedColor) {
      return;
    }
    _seedColor = value;
    notifyListeners();
  }

  /// Font family for the app, or null for the platform default.
  String? get fontFamily => _fontFamily;

  set fontFamily(String? value) {
    if (value == _fontFamily) {
      return;
    }
    _fontFamily = value;
    notifyListeners();
  }
}
