import 'package:flutter/material.dart';

/// The pictogram drawn inside a [PuzzleBadge], one per game.
enum PuzzleBadgeGlyph { tiles2048, slidingGrid, sudokuGrid, flag }

/// A game's identity mark: a rounded square with a knob on its right edge
/// and a socket cut into its bottom edge, so the badge itself reads as a
/// single interlocking puzzle piece rather than a generic icon tile.
class PuzzleBadge extends StatelessWidget {
  const PuzzleBadge({
    super.key,
    required this.color,
    required this.glyph,
    this.size = 56,
    this.matColor,
  });

  /// The badge's fill color -- one of [GameColors]' four accents.
  final Color color;
  final PuzzleBadgeGlyph glyph;
  final double size;

  /// The color the socket cut is painted, so it reads as a notch rather
  /// than a solid dot. Defaults to the surrounding scaffold background.
  final Color? matColor;

  @override
  Widget build(BuildContext context) {
    final knob = size * 0.32;
    final socket = size * 0.27;
    final mat = matColor ?? Theme.of(context).scaffoldBackgroundColor;
    final inset = size * 0.22;

    return SizedBox(
      width: size + knob / 2,
      height: size + socket / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size * 0.28),
              ),
              padding: EdgeInsets.all(inset),
              child: CustomPaint(painter: _painterFor(glyph, Colors.white)),
            ),
          ),
          Positioned(
            left: size - knob / 2,
            top: size / 2 - knob / 2,
            child: Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: size / 2 - socket / 2,
            top: size - socket / 2,
            child: Container(
              width: socket,
              height: socket,
              decoration: BoxDecoration(color: mat, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  CustomPainter _painterFor(PuzzleBadgeGlyph glyph, Color color) {
    return switch (glyph) {
      PuzzleBadgeGlyph.tiles2048 => _Tiles2048Painter(color),
      PuzzleBadgeGlyph.slidingGrid => _SlidingGridPainter(color),
      PuzzleBadgeGlyph.sudokuGrid => _SudokuGridPainter(color),
      PuzzleBadgeGlyph.flag => _FlagPainter(color),
    };
  }
}

/// Two small tiles above one wide merged tile, hinting at 2048's "combine
/// two into one" mechanic.
class _Tiles2048Painter extends CustomPainter {
  const _Tiles2048Painter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final r = Radius.circular(w * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w * 0.42, h * 0.42), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, 0, w * 0.42, h * 0.42),
        r,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.58, w, h * 0.42),
        Radius.circular(w * 0.2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _Tiles2048Painter oldDelegate) =>
      oldDelegate.color != color;
}

/// A 3x3 grid with the bottom-right cell left empty -- the 15-puzzle's
/// blank space.
class _SlidingGridPainter extends CustomPainter {
  const _SlidingGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cell = size.width / 3;
    final gap = cell * 0.18;
    final r = Radius.circular(cell * 0.16);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        if (row == 2 && col == 2) continue;
        final rect = Rect.fromLTWH(
          col * cell + gap / 2,
          row * cell + gap / 2,
          cell - gap,
          cell - gap,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, r), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SlidingGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A full, evenly-divided 3x3 grid -- distinguished from the sliding
/// puzzle's glyph by having every cell present.
class _SudokuGridPainter extends CustomPainter {
  const _SudokuGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09;
    final inner = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055;
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(outer.strokeWidth / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.12)),
      outer,
    );
    final third = size.width / 3;
    canvas.drawLine(Offset(third, 0), Offset(third, size.height), inner);
    canvas.drawLine(
      Offset(third * 2, 0),
      Offset(third * 2, size.height),
      inner,
    );
    canvas.drawLine(Offset(0, third), Offset(size.width, third), inner);
    canvas.drawLine(
      Offset(0, third * 2),
      Offset(size.width, third * 2),
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant _SudokuGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A small flag on a pole.
class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final poleWidth = size.width * 0.13;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.14, 0, poleWidth, size.height),
        Radius.circular(poleWidth / 2),
      ),
      paint,
    );
    final path = Path()
      ..moveTo(size.width * 0.14 + poleWidth, size.height * 0.06)
      ..lineTo(size.width * 0.95, size.height * 0.28)
      ..lineTo(size.width * 0.14 + poleWidth, size.height * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.color != color;
}
