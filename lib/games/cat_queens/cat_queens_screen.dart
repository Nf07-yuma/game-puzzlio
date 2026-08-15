import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_state_storage.dart';
import '../../services/score_service.dart';
import 'cat_queens_logic.dart';

enum _GameMenuAction { resetBoard, resetProgress }

/// Colors used for the puzzle's color regions, cycled by region id.
const List<Color> _regionColors = [
  Color(0xFFF6D860),
  Color(0xFF3FAE6A),
  Color(0xFF6FD98B),
  Color(0xFF52B7D9),
  Color(0xFFB5793C),
  Color(0xFFD9A441),
  Color(0xFFE87FAE),
  Color(0xFF8E7CD9),
  Color(0xFFE8955A),
  Color(0xFFC94F6D),
];

class CatQueensScreen extends StatefulWidget {
  const CatQueensScreen({super.key});

  @override
  State<CatQueensScreen> createState() => _CatQueensScreenState();
}

class _CatQueensScreenState extends State<CatQueensScreen> {
  static const String _gameId = 'cat_queens';
  static const String _savedStateId = 'cat_queens_current';

  final Random _random = Random();

  int _level = 1;
  int _score = 0;
  int? _bestScore;
  late CatQueensPuzzle _puzzle;
  late List<CatCellState> _board;
  CatQueensValidation _validation = const CatQueensValidation(
    conflicts: {},
    solved: false,
  );

  @override
  void initState() {
    super.initState();
    _newPuzzleForLevel(_level);
    _restoreSavedGame();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final best = await ScoreService.instance.getBestScore(_gameId);
    if (mounted) setState(() => _bestScore = best);
  }

  Future<void> _restoreSavedGame() async {
    final saved = await GameStateStorage.instance.load(_savedStateId);
    if (!mounted || saved == null) return;
    final size = saved['size'] as int;
    final regions = (saved['regions'] as List).cast<int>();
    final solutionColumns = (saved['solutionColumns'] as List).cast<int>();
    final board = (saved['board'] as List)
        .cast<int>()
        .map((v) => CatCellState.values[v])
        .toList();
    setState(() {
      _level = saved['level'] as int;
      _score = saved['score'] as int;
      _puzzle = CatQueensPuzzle(
        size: size,
        regions: regions,
        solutionColumns: solutionColumns,
      );
      _board = board;
      _validation = CatQueensPuzzle.validate(size, regions, board);
    });
  }

  Future<void> _saveGame() async {
    await GameStateStorage.instance.save(_savedStateId, {
      'level': _level,
      'score': _score,
      'size': _puzzle.size,
      'regions': _puzzle.regions,
      'solutionColumns': _puzzle.solutionColumns,
      'board': _board.map((s) => s.index).toList(),
    });
  }

  void _newPuzzleForLevel(int level) {
    final size = CatQueensPuzzle.sizeForLevel(level);
    _puzzle = CatQueensPuzzle.generate(_random, size);
    _board = List<CatCellState>.filled(size * size, CatCellState.empty);
    _validation = const CatQueensValidation(conflicts: {}, solved: false);
  }

  void _resetBoard() {
    setState(() {
      _board = List<CatCellState>.filled(
        _puzzle.size * _puzzle.size,
        CatCellState.empty,
      );
      _validation = const CatQueensValidation(conflicts: {}, solved: false);
    });
    _saveGame();
  }

  Future<void> _resetProgress() async {
    setState(() {
      _level = 1;
      _score = 0;
      _newPuzzleForLevel(_level);
    });
    await _saveGame();
  }

  void _tapCell(int index) {
    if (_validation.solved) return;
    HapticFeedback.selectionClick();
    setState(() {
      _board[index] = switch (_board[index]) {
        CatCellState.empty => CatCellState.marked,
        CatCellState.marked => CatCellState.cat,
        CatCellState.cat => CatCellState.empty,
      };
      _validation = CatQueensPuzzle.validate(
        _puzzle.size,
        _puzzle.regions,
        _board,
      );
    });
    if (_validation.solved) {
      _onSolved();
    } else {
      _saveGame();
    }
  }

  void _giveHint() {
    if (_validation.solved) return;
    final size = _puzzle.size;
    final rows = List<int>.generate(size, (i) => i)..shuffle(_random);
    for (final row in rows) {
      final targetIndex = row * size + _puzzle.solutionColumns[row];
      if (_board[targetIndex] != CatCellState.cat) {
        HapticFeedback.lightImpact();
        setState(() {
          _board[targetIndex] = CatCellState.cat;
          _validation = CatQueensPuzzle.validate(size, _puzzle.regions, _board);
        });
        if (_validation.solved) {
          _onSolved();
        } else {
          _saveGame();
        }
        return;
      }
    }
  }

  Future<void> _onSolved() async {
    HapticFeedback.mediumImpact();
    final gained = 50 + _puzzle.size * 30;
    setState(() => _score += gained);
    if (await ScoreService.instance.submitScore(_gameId, _score)) {
      if (mounted) setState(() => _bestScore = _score);
    }
    await _saveGame();
    if (mounted) _showSolvedDialog(gained);
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _newPuzzleForLevel(_level);
    });
    _saveGame();
  }

  void _showSolvedDialog(int gained) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('レベルクリア!'),
        content: Text('+$gained ポイント\nスコア: $_score'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextLevel();
            },
            child: const Text('次のレベルへ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catsPlaced = _board.where((s) => s == CatCellState.cat).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ネコクイーンズ'),
        actions: [
          IconButton(
            onPressed: _giveHint,
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'ヒント',
          ),
          PopupMenuButton<_GameMenuAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'メニュー',
            onSelected: (action) {
              switch (action) {
                case _GameMenuAction.resetBoard:
                  _resetBoard();
                case _GameMenuAction.resetProgress:
                  _resetProgress();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _GameMenuAction.resetBoard,
                child: Row(
                  children: [
                    Icon(Icons.replay),
                    SizedBox(width: 12),
                    Text('盤面をリセット'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _GameMenuAction.resetProgress,
                child: Row(
                  children: [
                    Icon(Icons.restart_alt),
                    SizedBox(width: 12),
                    Text('レベル1からやり直す'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBox(label: 'レベル', value: '$_level'),
                  _StatBox(label: 'スコア', value: '$_score'),
                  _StatBox(
                    label: 'ベスト',
                    value: _bestScore == null ? '--' : '$_bestScore',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('🐱', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '$catsPlaced / ${_puzzle.size}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _RuleChip('1色に1匹'),
                  _RuleChip('行と列に1匹ずつ'),
                  _RuleChip('ネコ同士は隣接不可'),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _CatQueensGrid(
                      puzzle: _puzzle,
                      board: _board,
                      conflicts: _validation.conflicts,
                      onTap: _tapCell,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _CatQueensGrid extends StatelessWidget {
  const _CatQueensGrid({
    required this.puzzle,
    required this.board,
    required this.conflicts,
    required this.onTap,
  });

  final CatQueensPuzzle puzzle;
  final List<CatCellState> board;
  final Set<int> conflicts;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: puzzle.size,
        ),
        itemCount: puzzle.size * puzzle.size,
        itemBuilder: (context, index) {
          final region = puzzle.regionAt(index);
          final color = _regionColors[region % _regionColors.length];
          final state = board[index];
          final isConflict = conflicts.contains(index);

          return Padding(
            padding: const EdgeInsets.all(1.5),
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: isConflict
                      ? Border.all(color: colorScheme.error, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: switch (state) {
                  CatCellState.empty => null,
                  CatCellState.marked => Icon(
                      Icons.close_rounded,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  CatCellState.cat => const Text(
                      '🐱',
                      style: TextStyle(fontSize: 18),
                    ),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
