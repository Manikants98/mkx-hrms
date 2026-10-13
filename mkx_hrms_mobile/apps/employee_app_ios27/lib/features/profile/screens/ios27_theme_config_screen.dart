import 'package:flutter/cupertino.dart';
import 'package:mkx_core/theme/app_theme_scope.dart';
import 'package:mkx_core/theme/app_theme_settings.dart';

import '../../../widgets/ios27_app_bar.dart';
import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_theme_mode_selector.dart';

/// Full-screen iOS 27 Liquid Glass theme palette and personalization configuration screen.
class Ios27ThemeConfigScreen extends StatelessWidget {
  /// Constructs the iOS 27 theme preferences screen.
  const Ios27ThemeConfigScreen({super.key});

  /// Navigates to the theme configuration screen using a native iOS slide transition.
  static void push(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => const Ios27ThemeConfigScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final AppThemeSettings settings = AppThemeScope.of(context);

    final Color primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: Ios27Background(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Ios27AppBar(
                title: 'Theme',
                subtitle: 'Appearance & Style',
                showBackButton: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      _buildSeedColorsSection(settings, isDark, primaryColor),
                      _buildFontFamilySection(settings, isDark, primaryColor),
                      _buildThemeModeSection(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * Builds the seed color palette selection grid with liquid glass indicator rings.
   */
  Widget _buildSeedColorsSection(
    AppThemeSettings settings,
    bool isDark,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Ios27GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Wrap(
            spacing: 12,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (int i = 0; i < AppThemeSettings.seedOptions.length; i++)
                _buildSeedSwatch(
                  color: AppThemeSettings.seedOptions[i],
                  label: AppThemeSettings.seedLabels[i],
                  selected:
                      settings.seedColor == AppThemeSettings.seedOptions[i],
                  enabled: true,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onTap: () =>
                      settings.seedColor = AppThemeSettings.seedOptions[i],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds an individual seed color circle swatch item.
  Widget _buildSeedSwatch({
    required Color color,
    required String label,
    required bool selected,
    required bool enabled,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback? onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: enabled ? color : color.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? (isDark
                          ? CupertinoColors.white.withValues(alpha: 0.60)
                          : primaryColor.withValues(alpha: 0.30))
                      : CupertinoColors.transparent,
                  width: selected ? 2.8 : 0,
                ),
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: isDark ? 0.65 : 0.45),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? const Center(
                      child: Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 24,
                        color: CupertinoColors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
                color: selected
                    ? (isDark ? CupertinoColors.white : const Color(0xFF1C1C1E))
                    : (isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the typography card selection section.
  Widget _buildFontFamilySection(
    AppThemeSettings settings,
    bool isDark,
    Color primaryColor,
  ) {
    final List<(String, String?)> families = <(String, String?)>[
      ('SF Pro', AppThemeSettings.sfPro),
      ('Google Sans', AppThemeSettings.googleSansFlex),
      ('Poppins', AppThemeSettings.poppins),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Font family',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color:
                      isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Applies app-wide typography styles.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6E6E73),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Ios27GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: families.map(((String, String?) item) {
              final bool isSelected = settings.fontFamily == item.$2;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => settings.fontFamily = item.$2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? primaryColor.withValues(alpha: 0.35)
                                    : primaryColor.withValues(alpha: 0.15))
                                : (isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.06)
                                    : CupertinoColors.black
                                        .withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? CupertinoColors.white
                                          .withValues(alpha: 0.12)
                                      : CupertinoColors.black
                                          .withValues(alpha: 0.08)),
                              width: isSelected ? 1.8 : 0.8,
                            ),
                          ),
                          child: Text(
                            'Aa',
                            style: TextStyle(
                              fontFamily: item.$2,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isDark
                                      ? CupertinoColors.white
                                      : primaryColor)
                                  : (isDark
                                      ? CupertinoColors.white
                                      : const Color(0xFF1C1C1E)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: -0.2,
                            color: isSelected
                                ? (isDark
                                    ? CupertinoColors.white
                                    : primaryColor)
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
        ),
      ],
    );
  }

  /// Builds the theme mode segment control section.
  Widget _buildThemeModeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color:
                      isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Choose between system, light, and dark appearance.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6E6E73),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Ios27ThemeModeSelector(),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
