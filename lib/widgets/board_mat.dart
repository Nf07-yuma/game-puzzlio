import 'package:flutter/material.dart';

/// Wraps a game board in a rounded frame without ever rounding the board
/// itself. The frame's padding keeps its curved corners clear of the
/// board's straight grid lines, so the two edge treatments never collide
/// into the mixed straight/curved corners a direct border-radius on the
/// grid would produce.
class BoardMat extends StatelessWidget {
  const BoardMat({super.key, required this.child, this.padding = 10});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
