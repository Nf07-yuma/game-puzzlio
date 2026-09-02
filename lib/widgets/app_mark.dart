import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// Puzzlio's wordmark glyph: four tiles in the app's four game colors.
/// Painted directly instead of clipping a raster asset, so it never shows a
/// stray edge against whatever background it sits on.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tile = size * 0.46;
    final gap = size * 0.08;
    final radius = BorderRadius.circular(size * 0.16);
    Widget square(Color color) => Container(
          width: tile,
          height: tile,
          decoration: BoxDecoration(color: color, borderRadius: radius),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              square(GameColors.yamabuki),
              SizedBox(width: gap),
              square(GameColors.hanada),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              square(GameColors.wakakusa),
              SizedBox(width: gap),
              square(GameColors.sango),
            ],
          ),
        ],
      ),
    );
  }
}
