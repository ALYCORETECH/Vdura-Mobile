import 'package:flutter/material.dart';
import 'package:sales_management/core/theme/theme.dart';

class VanguardeDropdown<T> extends StatelessWidget {
  final String? label;
  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const VanguardeDropdown({
    super.key,
    this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>() ?? VanguardeColors.light;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 7),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.fieldHint),
          dropdownColor: colors.fieldBackground,
          style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: colors.fieldHint, fontSize: 13.5),
            filled: true,
            fillColor: colors.fieldBackground,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: scheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}