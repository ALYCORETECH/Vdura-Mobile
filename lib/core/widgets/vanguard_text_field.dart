import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR TextInputFormatter
import 'package:sales_management/core/theme/theme.dart';

class VanguardeTextField extends StatelessWidget {
  final String? label;
  final String? labelHint;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  // ─── THESE ARE THE MISSING PROPERTIES ───
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const VanguardeTextField({
    super.key,
    this.label,
    this.labelHint,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.maxLength, // Added here
    this.inputFormatters, // Added here
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>() ?? VanguardeColors.light;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!, style: Theme.of(context).textTheme.labelLarge),
              if (labelHint != null)
                Text(
                  labelHint!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: colors.smallLabel,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
        ],

        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          enabled: enabled,

          // ─── APPLIED HERE ───
          maxLength: maxLength,
          inputFormatters: inputFormatters,

          cursorColor: scheme.primary,
          style: TextStyle(
            fontSize: 13.5,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            counterText: '', // Hides the default "0/10" character counter text
            hintText: hintText,
            hintStyle: TextStyle(color: colors.fieldHint, fontSize: 13.5),
            filled: true,
            fillColor: colors.fieldBackground,
            suffixIcon: suffixIcon,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.fieldBorder),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.fieldBorder.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: scheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: scheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: scheme.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}