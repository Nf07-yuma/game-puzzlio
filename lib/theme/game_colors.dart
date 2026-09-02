import 'package:flutter/material.dart';

/// Accent colors drawn from traditional Japanese color names, one per game.
/// Kept in one place so the home screen list, each game screen, and the
/// shared badge widget always agree on a game's identity color.
class GameColors {
  const GameColors._();

  /// 山吹色 (yamabuki) -- 2048.
  static const Color yamabuki = Color(0xFFDC9A34);

  /// 縹色 (hanada) -- sliding puzzle.
  static const Color hanada = Color(0xFF3E7CA6);

  /// 若草色 (wakakusa) -- sudoku.
  static const Color wakakusa = Color(0xFF5F9A52);

  /// 珊瑚色 (sango) -- territory puzzle.
  static const Color sango = Color(0xFFE85A41);
}
