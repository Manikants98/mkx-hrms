import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'splash_illustration.dart';

/// Defines the app type to show correct branded assets
enum AppType { employee, hr }

/// Branded initial splash screen while authentication status initializes
class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({
    super.key,
    this.appType = AppType.employee,
  });

  final AppType appType;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              appType == AppType.hr
                  ? getHrSplashSvg(scheme)
                  : getSplashSvg(scheme),
              height: appType == AppType.hr ? 230 : 300,
            ),
            const SizedBox(height: 12),
            Text(
              'MKX HRMS',
              style: theme.typeScale.headlineLarge.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: scheme.onSurface,
              ),
            ),
            Text(
              'Empowering Your Workforce',
              style: theme.typeScale.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 36,
              height: 36,
              child: M3EProgressIndicator.circularWavy(
                strokeWidth: 3,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
