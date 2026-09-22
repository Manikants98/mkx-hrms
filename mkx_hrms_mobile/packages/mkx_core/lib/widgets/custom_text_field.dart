import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Clean, modern text input field using Material 3 Expressive
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return M3ETextField(
      controller: controller,
      label: label ?? hintText,
      errorText: errorText,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: !readOnly,
      onChanged: onChanged,
      leading: prefixIcon,
      trailing: suffixIcon,
      variant: M3ETextFieldVariant.outlined,
    );
  }
}
