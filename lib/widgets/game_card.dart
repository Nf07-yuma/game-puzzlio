import 'package:flutter/material.dart';

import '../models/puzzle_game.dart';
import 'puzzle_badge.dart';

/// One row of the home screen's game list. Deliberately flat -- a hairline
/// rule above the row instead of a bordered/shadowed card -- so the
/// [PuzzleBadge]'s color and shape carry the identity instead of chrome.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, required this.onTap});

  final PuzzleGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            PuzzleBadge(color: game.color, glyph: game.glyph, size: 46),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: TextStyle(
                fontSize: 22,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
