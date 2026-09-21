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

  Color _seedColor = seedOptions.first;

  /// Seed used to generate the scheme when dynamic color is off.
  Color get seedColor => _seedColor;

  set seedColor(Color value) {
    if (value == _seedColor) {
      return;
    }
    _seedColor = value;
    notifyListeners();
  }
}
