import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small labeled stat pill (level, score, time, ...), shared by every
/// game screen's header row. Flat and hairline-bordered rather than filled,
/// so the accent color -- not a background fill -- carries emphasis.
class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.width = 100,
    this.accentColor,
  });

  final String label;
  final String value;
  final double width;

  /// When set, the value is drawn in this color instead of the default
  /// text color, marking this stat as the game's headline number.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: accentColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
