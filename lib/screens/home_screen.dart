import 'package:flutter/material.dart';

import '../games/game_2048/game_2048_screen.dart';
import '../games/sliding_puzzle/sliding_puzzle_screen.dart';
import '../games/sudoku/sudoku_screen.dart';
import '../models/puzzle_game.dart';
import '../widgets/game_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<PuzzleGame> games = [
    PuzzleGame(
      id: '2048',
      title: '2048',
      description: 'タイルをスライドして数字を合成しよう',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFFEDA13A),
      builder: (context) => const Game2048Screen(),
    ),
    PuzzleGame(
      id: 'sliding_puzzle',
      title: 'スライドパズル',
      description: '15個のピースを並べ替えて絵を完成させよう',
      icon: Icons.extension_rounded,
      color: const Color(0xFF3AA1ED),
      builder: (context) => const SlidingPuzzleScreen(),
    ),
    PuzzleGame(
      id: 'sudoku',
      title: '数独',
      description: '9x9の盤面を数字で埋めるロジックパズル',
      icon: Icons.apps_rounded,
      color: const Color(0xFF3AED8C),
      builder: (context) => const SudokuScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puzzlio',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '好きなパズルを選んで遊ぼう',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: games.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final game = games[index];
                  return GameCard(
                    game: game,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: game.builder),
                      );
                    },
                  );
                },
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
