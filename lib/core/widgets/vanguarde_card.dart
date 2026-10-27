import 'package:flutter/material.dart';
import 'package:sales_management/core/theme/theme.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class VanguardeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingText;
  final String trailingSubText;
  final IconData? icon;
  final VoidCallback? onTap;

  const VanguardeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.trailingSubText,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>() ?? VanguardeColors.light;
    final scheme = Theme.of(context).colorScheme;

    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.fieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.fieldBorder),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colors.subtitle),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.statusDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trailingSubText,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: colors.smallLabel,
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Bounceable(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}