import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class VanguardeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFullWidth;

  const VanguardeButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Bounceable(
      onTap: onPressed,
      // The Semantics widget tells screen readers this is a clickable button
      child: Semantics(
        button: true,
        child: Container(
          // Handle full width natively inside the Container
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: scheme.onPrimary, // Text color
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}