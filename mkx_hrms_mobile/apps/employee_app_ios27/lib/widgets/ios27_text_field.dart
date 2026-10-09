import 'package:flutter/cupertino.dart';

/**
 * Premium iOS 27 glass input field built natively with CupertinoTextField and FormField validation
 */
class Ios27TextField extends StatefulWidget {
  /**
   * Controller for the text being edited
   */
  final TextEditingController? controller;

  /**
   * Floating or top label above the field
   */
  final String? label;

  /**
   * Subtle placeholder hint displayed when input is empty
   */
  final String? placeholder;

  /**
   * Optional manual error message
   */
  final String? errorText;

  /**
   * Whether the text should be masked for sensitive fields like passwords
   */
  final bool obscureText;

  /**
   * Leading icon or widget placed inside the input container
   */
  final Widget? prefixIcon;

  /**
   * Trailing action or icon widget
   */
  final Widget? suffixIcon;

  /**
   * Keyboard layout type appropriate for this input
   */
  final TextInputType keyboardType;

  /**
   * Action button type for the virtual keyboard
   */
  final TextInputAction? textInputAction;

  /**
   * Callback fired on submitting the input via keyboard
   */
  final ValueChanged<String>? onSubmitted;

  /**
   * Validation rule delegate
   */
  final FormFieldValidator<String>? validator;

  /**
   * Optional autofill hints for system credential management
   */
  final Iterable<String>? autofillHints;

  /**
   * Whether the input field is interactive
   */
  final bool enabled;

  /**
   * Maximum lines for multi-line inputs
   */
  final int maxLines;

  /**
   * Minimum lines for multi-line inputs
   */
  final int? minLines;

  /**
   * Creates an authentic iOS Cupertino glass text input field
   */
  const Ios27TextField({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.autofillHints,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<Ios27TextField> createState() => _Ios27TextFieldState();
}

class _Ios27TextFieldState extends State<Ios27TextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;
    final primaryColor = cupertinoTheme.primaryColor;

    return FormField<String>(
      validator: (val) {
        final currentText = widget.controller?.text ?? val;
        return widget.validator?.call(currentText);
      },
      initialValue: widget.controller?.text,
      builder: (FormFieldState<String> fieldState) {
        final effectiveError = widget.errorText ?? fieldState.errorText;
        final hasError = effectiveError != null && effectiveError.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.88)
                        : const Color(0xFF1C2230),
                  ),
                ),
              ),
            ],
            CupertinoTextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              onChanged: (val) {
                fieldState.didChange(val);
              },
              autofillHints: widget.autofillHints,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? CupertinoColors.white : const Color(0xFF0F172A),
              ),
              cursorColor: primaryColor,
              placeholder: widget.placeholder,
              placeholderStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.32)
                    : const Color(0xFF8E9BAE),
              ),
              prefix: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: widget.prefixIcon,
                    )
                  : null,
              suffix: widget.suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12, left: 6),
                      child: widget.suffixIcon,
                    )
                  : null,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? (_isFocused
                        ? const Color(0xFF1B2236).withValues(alpha: 0.88)
                        : const Color(0xFF121724).withValues(alpha: 0.65))
                    : (_isFocused
                        ? CupertinoColors.white.withValues(alpha: 0.95)
                        : CupertinoColors.white.withValues(alpha: 0.72)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasError
                      ? CupertinoColors.systemRed
                      : (_isFocused
                          ? primaryColor
                          : (isDark
                              ? CupertinoColors.white.withValues(alpha: 0.12)
                              : CupertinoColors.black.withValues(alpha: 0.08))),
                  width: (hasError || _isFocused) ? 1.5 : 1.0,
                ),
              ),
            ),
            if (hasError) ...[
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 5),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_circle_fill,
                      size: 13,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        effectiveError,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
