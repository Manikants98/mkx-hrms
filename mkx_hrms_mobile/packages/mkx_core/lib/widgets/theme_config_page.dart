import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../theme/app_theme_scope.dart';
import '../theme/app_theme_settings.dart';

/// A page for configuring the app's theme settings.
class ThemeConfigPage extends StatelessWidget {
  const ThemeConfigPage({super.key});

  static void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ThemeConfigPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final AppThemeSettings settings = AppThemeScope.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Theme'),
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLow,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            _toggles(theme, settings),
            const SizedBox(height: 24),
            _seeds(theme, settings),
            const SizedBox(height: 24),
            _type(theme, settings),
          ],
        ),
      ),
    );
  }

  Widget _toggles(M3EThemeData theme, AppThemeSettings settings) {
    final List<Widget> rows = <Widget>[
      M3EListItem(
        headline: 'Auto theming',
        supportingText: 'Follow the platform light and dark setting',
        trailing: M3ESwitch(
          value: settings.autoTheming,
          semanticLabel: 'Auto theming',
          onChanged: (bool value) => settings.autoTheming = value,
        ),
      ),
      M3EListItem(
        headline: 'Dynamic color',
        supportingText:
            'Use the device wallpaper palette where the platform supports it',
        trailing: M3ESwitch(
          value: settings.dynamicColoring,
          semanticLabel: 'Dynamic color',
          onChanged: (bool value) => settings.dynamicColoring = value,
        ),
      ),
    ];

    return M3ECardList(
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int index) => rows[index],
    );
  }

  Widget _seeds(M3EThemeData theme, AppThemeSettings settings) {
    final M3EColorScheme scheme = theme.colorScheme;
    final bool enabled = !settings.dynamicColoring;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Seed color',
          style: theme.typeScale.titleMedium.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          enabled
              ? 'Generates the scheme for both brightnesses.'
              : 'Turn dynamic color off to pick a seed.',
          style: theme.typeScale.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            for (int i = 0; i < AppThemeSettings.seedOptions.length; i++)
              _SeedSwatch(
                color: AppThemeSettings.seedOptions[i],
                label: AppThemeSettings.seedLabels[i],
                selected: enabled &&
                    settings.seedColor == AppThemeSettings.seedOptions[i],
                onTap: enabled
                    ? () => settings.seedColor = AppThemeSettings.seedOptions[i]
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _type(M3EThemeData theme, AppThemeSettings settings) {
    final M3EColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Font family',
          style: theme.typeScale.titleMedium.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Applies app-wide typography styles.',
          style: theme.typeScale.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _FamilySwatch(
              label: 'Sans',
              family: AppThemeSettings.googleSansFlex,
              selected: settings.fontFamily == AppThemeSettings.googleSansFlex,
              onTap: () =>
                  settings.fontFamily = AppThemeSettings.googleSansFlex,
            ),
            _FamilySwatch(
              label: 'System',
              family: null,
              selected: settings.fontFamily == null,
              onTap: () => settings.fontFamily = null,
            ),
            _FamilySwatch(
              label: 'Poppins',
              family: AppThemeSettings.poppins,
              selected: settings.fontFamily == AppThemeSettings.poppins,
              onTap: () => settings.fontFamily = AppThemeSettings.poppins,
            ),
          ],
        ),
      ],
    );
  }
}

/// One seed choice: a filled circle with its label underneath.
class _SeedSwatch extends StatelessWidget {
  const _SeedSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final Color tick =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF000000);

    return M3ETappable(
      onTap: onTap,
      enabled: onTap != null,
      semanticLabel: '$label seed',
      pressedScale: 0.94,
      haptic: M3EHapticFeedback.light,
      builder: (BuildContext context, M3EInteractionState state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: M3EMotion.short3,
              curve: M3EMotion.standard,
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: onTap == null ? color.withValues(alpha: 0.38) : color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.onSurface : scheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child:
                  selected ? Icon(M3EIcons.check, size: 24, color: tick) : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.typeScale.labelMedium.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One font family choice: sample letters in that face.
class _FamilySwatch extends StatelessWidget {
  const _FamilySwatch({
    required this.label,
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? family;
  final bool selected;
  final VoidCallback onTap;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return M3ETappable(
      onTap: onTap,
      semanticLabel: '$label font',
      excludeSemantics: true,
      pressedScale: 0.94,
      haptic: M3EHapticFeedback.light,
      builder: (BuildContext context, M3EInteractionState state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: M3EMotion.short3,
              curve: M3EMotion.standard,
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.secondaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? scheme.onSurface : scheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Text(
                'Aa',
                style: theme.typeScale.titleMedium.copyWith(
                  fontFamily: family,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.typeScale.labelMedium.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
