import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum ButtonVariant { primary, secondary, outline, danger }

/// Professional, highly responsive custom button widget using Material 3 Expressive
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final ButtonVariant variant;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.height = 48,
    this.width,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    M3EButtonStyle buttonStyle;
    switch (variant) {
      case ButtonVariant.primary:
        buttonStyle = M3EButtonStyle.filled;
        break;
      case ButtonVariant.secondary:
        buttonStyle = M3EButtonStyle.tonal;
        break;
      case ButtonVariant.outline:
        buttonStyle = M3EButtonStyle.outlined;
        break;
      case ButtonVariant.danger:
        buttonStyle = M3EButtonStyle.filled;
        break;
    }

    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.onPrimary,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return SizedBox(
      height: height,
      width: width,
      child: M3EButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
