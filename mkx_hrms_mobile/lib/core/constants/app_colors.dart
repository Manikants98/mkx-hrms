import 'package:flutter/material.dart';

/// Design tokens and semantic color definitions matching the MKX HRMS design system.
///
/// **Palette intent (both modes):**
/// - [lightBackground] / [darkBackground] — Scaffold/page background (grey)
/// - [lightCard] / [darkCard]             — Tile/card surface (lighter in light, darker in dark)
/// - [lightBorder] / [darkBorder]         — Separator line between tiles
class AppColors {
  AppColors._();

  // ── Light Mode ────────────────────────────────────────────────────────────
  /// Page scaffold background — iOS-style light grey.
  static const Color lightBackground = Color(0xFFF2F2F7);

  /// Tile / card surface — white on the grey scaffold.
  static const Color lightCard = Color(0xFFFFFFFF);

  /// Foreground / primary text.
  static const Color lightForeground = Color(0xFF09090B);

  /// Subtle separator line between grouped tiles.
  static const Color lightBorder = Color(0xFFD1D1D6);

  /// Input field fill.
  static const Color lightInput = Color(0xFFE5E5EA);

  /// Primary interactive color (e.g., buttons).
  static const Color lightPrimary = Color(0xFF18181B);

  /// Text on primary.
  static const Color lightPrimaryForeground = Color(0xFFFAFAFA);

  /// Secondary container (inner sub-boxes).
  static const Color lightSecondary = Color(0xFFF2F2F7);

  /// Text on secondary.
  static const Color lightSecondaryForeground = Color(0xFF18181B);

  /// De-emphasised / helper text.
  static const Color lightMuted = Color(0xFF6E6E73);

  /// Muted container background.
  static const Color lightMutedBg = Color(0xFFE5E5EA);

  // ── Dark Mode ─────────────────────────────────────────────────────────────
  /// Page scaffold background — medium charcoal grey.
  static const Color darkBackground = Color(0xFF1C1C1E);

  /// Tile / card surface — near-black, darker than the scaffold.
  static const Color darkCard = Color(0xFF0F0F11);

  /// Foreground / primary text.
  static const Color darkForeground = Color(0xFFEEEEEE);

  /// Subtle separator line between grouped tiles.
  static const Color darkBorder = Color(0xFF2C2C30);

  /// Input field fill.
  static const Color darkInput = Color(0xFF1A1A1E);

  /// Primary interactive color.
  static const Color darkPrimary = Color(0xFFEEEEEE);

  /// Text on primary.
  static const Color darkPrimaryForeground = Color(0xFF0F0F11);

  /// Secondary container (inner sub-boxes inside a tile).
  static const Color darkSecondary = Color(0xFF1A1A1E);

  /// Text on secondary.
  static const Color darkSecondaryForeground = Color(0xFFEEEEEE);

  /// De-emphasised / helper text.
  static const Color darkMuted = Color(0xFFA1A1AA);

  /// Muted container background.
  static const Color darkMutedBg = Color(0xFF1A1A1E);

  // ── Semantic Status Colors ─────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBgLight = Color(0xFFECFDF5);
  static const Color successBgDark = Color(0xFF062D20);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBgLight = Color(0xFFFFFBEB);
  static const Color warningBgDark = Color(0xFF352003);

  static const Color error = Color(0xFFEF4444);
  static const Color errorBgLight = Color(0xFFFEF2F2);
  static const Color errorBgDark = Color(0xFF371212);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoBgLight = Color(0xFFF0F9FF);
  static const Color infoBgDark = Color(0xFF082F49);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleBgLight = Color(0xFFF5F3FF);
  static const Color purpleBgDark = Color(0xFF2E1065);
}
