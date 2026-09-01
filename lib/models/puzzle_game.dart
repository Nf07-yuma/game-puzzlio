import 'package:flutter/material.dart';

import '../widgets/puzzle_badge.dart';

/// Describes one puzzle game available from the home screen.
class PuzzleGame {
  const PuzzleGame({
    required this.id,
    required this.title,
    required this.description,
    required this.glyph,
    required this.color,
    required this.builder,
  });

  /// Stable identifier used as a key for persisted scores.
  final String id;
  final String title;
  final String description;
  final PuzzleBadgeGlyph glyph;
  final Color color;
  final WidgetBuilder builder;
}
