import 'package:flutter/widgets.dart';

import 'app_theme_settings.dart';

/// Exposes the [AppThemeSettings] to every route in the app.
class AppThemeScope extends InheritedNotifier<AppThemeSettings> {
  /// Creates a theme settings scope.
  const AppThemeScope({
    required AppThemeSettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  /// The nearest settings object; throws when the scope is missing.
  static AppThemeSettings of(BuildContext context) {
    final AppThemeScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'No AppThemeScope found in context.');
    return scope!.notifier!;
  }
}
