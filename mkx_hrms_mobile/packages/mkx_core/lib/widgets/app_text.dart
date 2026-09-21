import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Opinionated [Text] replacement for MKX HRMS that applies Material 3 Expressive
/// typography and automatically resolves foreground / muted colors from the current theme.
///
/// Named constructors map to the common typography scales used across the app:
/// ```dart
/// AppText.heading('Dashboard Overview')
/// AppText.title('Employees')
/// AppText.body('Some description')
/// AppText.label('Department • Engineering')
/// AppText.caption('2h ago')
/// AppText.muted('No records found')
/// ```
class AppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  /// Explicit color. When null, [AppText] resolves the color automatically from
  /// [_ColorRole] using the current brightness.
  final Color? color;
  final _ColorRole _role;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final double? height;

  // ── Base constructor ────────────────────────────────────────────────────────

  /// Base constructor — full control over all parameters.
  const AppText(
    this.text, {
    super.key,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
  }) : _role = _ColorRole.foreground;

  // ── Named constructors ──────────────────────────────────────────────────────

  /// Large screen heading — 20pt, w800, −0.5 letter-spacing.
  const AppText.heading(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 20,
        fontWeight = FontWeight.w800,
        letterSpacing = -0.5,
        _role = _ColorRole.foreground;

  /// Section title — 16pt, w700.
  const AppText.title(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 16,
        fontWeight = FontWeight.w700,
        letterSpacing = null,
        _role = _ColorRole.foreground;

  /// Subsection title — 15pt, w700.
  const AppText.subtitle(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 15,
        fontWeight = FontWeight.w700,
        letterSpacing = null,
        _role = _ColorRole.foreground;

  /// Primary body text — 13pt, w400.
  const AppText.body(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 13,
        fontWeight = FontWeight.w400,
        letterSpacing = null,
        _role = _ColorRole.foreground;

  /// Emphasized body — 13pt, w600.
  const AppText.bodyBold(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 13,
        fontWeight = FontWeight.w600,
        letterSpacing = null,
        _role = _ColorRole.foreground;

  /// Small label / chip text — 12pt, w500.
  const AppText.label(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 12,
        fontWeight = FontWeight.w500,
        letterSpacing = null,
        _role = _ColorRole.foreground;

  /// Tiny caption — 11pt, w400, muted color.
  const AppText.caption(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 11,
        fontWeight = FontWeight.w400,
        letterSpacing = null,
        _role = _ColorRole.muted;

  /// De-emphasized / helper text — 12pt, w400, muted color.
  const AppText.muted(
    this.text, {
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.height,
  })  : fontSize = 12,
        fontWeight = FontWeight.w400,
        letterSpacing = null,
        _role = _ColorRole.muted;

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    final resolvedColor = color ?? _resolveColor(scheme);

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: resolvedColor,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }

  Color _resolveColor(M3EColorScheme scheme) {
    switch (_role) {
      case _ColorRole.muted:
        return scheme.onSurfaceVariant;
      case _ColorRole.foreground:
        return scheme.onSurface;
    }
  }
}

/// Internal enum controlling automatic color resolution when no explicit color
/// is passed to an [AppText] named constructor.
enum _ColorRole { foreground, muted }
