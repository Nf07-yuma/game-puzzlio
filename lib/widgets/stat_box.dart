import 'package:flutter/material.dart';

/// A small rounded stat display used in every game's header (score, time,
/// level, best, ...) -- kept as one shared widget so all games read
/// consistently.
class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.width = 100,
    this.accent = false,
  });

  final String label;
  final String value;
  final double width;

  /// Tints the value with the theme's primary color for a stat that
  /// deserves extra emphasis (e.g. the current score).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent ? colorScheme.primary : colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
