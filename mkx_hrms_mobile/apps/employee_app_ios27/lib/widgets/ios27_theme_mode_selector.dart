import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/theme/app_theme_scope.dart';
import 'package:mkx_core/theme/app_theme_settings.dart';
import 'package:provider/provider.dart';

/// iOS 27 Liquid Glass theme mode switcher allowing toggle between Light, System, and Dark appearance.
class Ios27ThemeModeSelector extends StatelessWidget {
  /// Background tint color override.
  final Color? color;

  /// Creates an iOS 27 themed appearance switcher.
  const Ios27ThemeModeSelector({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final AuthProvider auth = context.watch<AuthProvider>();
    final AppThemeSettings settings = AppThemeScope.of(context);

    final List<(ThemeMode, String, IconData)> modes =
        <(ThemeMode, String, IconData)>[
      (ThemeMode.light, 'Light', CupertinoIcons.sun_max_fill),
      (ThemeMode.system, 'System', CupertinoIcons.circle_righthalf_fill),
      (ThemeMode.dark, 'Dark', CupertinoIcons.moon_fill),
    ];

    final ThemeMode activeMode =
        settings.autoTheming ? ThemeMode.system : auth.themeMode;

    return GlassCard(
      padding: const EdgeInsets.all(4),
      shape: const LiquidRoundedSuperellipse(borderRadius: 16),
      useOwnLayer: true,
      settings: LiquidGlassSettings(
        thickness: 14,
        blur: 14,
        refractiveIndex: 1.15,
        lightIntensity: isDark ? 0.40 : 0.55,
        fresnelStrength: isDark ? 0.30 : 0.40,
        chromaticAberration: 0.03,
      ),
      child: Row(
        children: modes.map(((ThemeMode, String, IconData) item) {
          final bool isSelected = item.$1 == activeMode;

          return Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () {
                if (item.$1 == ThemeMode.system) {
                  settings.autoTheming = true;
                } else {
                  settings.autoTheming = false;
                }
                auth.setThemeMode(item.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? CupertinoColors.white.withValues(alpha: 0.18)
                          : CupertinoColors.white)
                      : CupertinoColors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: CupertinoColors.black.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      item.$3,
                      size: 15,
                      color: isSelected
                          ? (isDark
                              ? CupertinoColors.white
                              : CupertinoTheme.of(context).primaryColor)
                          : (isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: -0.2,
                        color: isSelected
                            ? (isDark
                                ? CupertinoColors.white
                                : CupertinoTheme.of(context).primaryColor)
                            : (isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6E6E73)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
