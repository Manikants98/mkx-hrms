import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../features/auth/state/auth_provider.dart';
import '../theme/app_theme_scope.dart';
import '../theme/app_theme_settings.dart';

/**
 * A segmented button group allowing users to toggle between Light, System, and Dark theme modes.
 * Synchronizes with both [AuthProvider] and [AppThemeSettings].
 */
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = M3ETheme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final settings = AppThemeScope.of(context);

    final modes = [
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
      (ThemeMode.system, 'System', Icons.settings_brightness_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
    ];

    final activeMode =
        settings.autoTheming ? ThemeMode.system : auth.themeMode;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EButtonGroup(
        type: M3EButtonGroupType.connected,
        shape: M3EButtonShape.square,
        size: M3EButtonSize.sm,
        style: M3EButtonStyle.filled,
        neighborSquish: true,
        decoration: M3EToggleButtonDecoration(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.surfaceContainer;
          }),
        ),
        selectedIndex: modes.indexWhere((m) => m.$1 == activeMode),
        onSelectedIndexChanged: (int? index) {
          if (index != null && index >= 0 && index < modes.length) {
            final item = modes[index];
            if (item.$1 == ThemeMode.system) {
              settings.autoTheming = true;
            } else {
              settings.autoTheming = false;
            }
            auth.setThemeMode(item.$1);
          }
        },
        actions: modes.map((item) {
          final isSelected = item.$1 == activeMode;
          return M3EButtonGroupAction(
            label: Text(
              item.$2,
              style: TextStyle(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            icon: Icon(
              item.$3,
              size: 14,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          );
        }).toList(),
      ),
    );
  }
}
