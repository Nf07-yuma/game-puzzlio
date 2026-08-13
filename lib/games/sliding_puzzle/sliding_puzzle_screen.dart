import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_state_storage.dart';
import '../../services/score_service.dart';
import 'sliding_puzzle_logic.dart';

class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({super.key});

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen> {
  static const String _gameId = 'sliding_puzzle';

  final Random _random = Random();

  late SlidingPuzzleBoard _board;
  int _moves = 0;
  int _elapsedSeconds = 0;
  int? _bestTimeSeconds;
  Timer? _timer;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _resetBoard();
    _loadBestTime();
    _restoreSavedGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestTime() async {
    final best = await ScoreService.instance.getBestTimeSeconds(_gameId);
    if (mounted) setState(() => _bestTimeSeconds = best);
  }

  /// Restores an in-progress game saved before navigating away, if any.
  /// The timer started by [_resetBoard] keeps running underneath, so
  /// resuming just swaps in the saved board/moves/elapsed time. If nothing
  /// was saved yet, persists the freshly generated board so a puzzle that
  /// hasn't received any input is still there next time.
  Future<void> _restoreSavedGame() async {
    final saved = await GameStateStorage.instance.load(_gameId);
    if (!mounted) return;
    if (saved == null) {
      await _saveGame();
      return;
    }
    final tiles = (saved['tiles'] as List).cast<int>();
    setState(() {
      _board = SlidingPuzzleBoard(tiles);
      _moves = saved['moves'] as int;
      _elapsedSeconds = saved['elapsedSeconds'] as int;
    });
  }

  Future<void> _saveGame() async {
    await GameStateStorage.instance.save(_gameId, {
      'tiles': _board.tiles,
      'moves': _moves,
      'elapsedSeconds': _elapsedSeconds,
    });
  }

  void _resetBoard() {
    _timer?.cancel();
    setState(() {
      _board = SlidingPuzzleBoard.shuffled(_random);
      _moves = 0;
      _elapsedSeconds = 0;
      _solved = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _startNewGame() {
    GameStateStorage.instance.clear(_gameId);
    _resetBoard();
    _saveGame();
  }

  Future<void> _handleTap(int index) async {
    if (_solved) return;
    if (!_board.movableIndices.contains(index)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _board = _board.tap(index);
      _moves++;
    });

    if (_board.isSolved) {
      HapticFeedback.mediumImpact();
      _timer?.cancel();
      setState(() => _solved = true);
      await GameStateStorage.instance.clear(_gameId);
      if (await ScoreService.instance.submitTime(_gameId, _elapsedSeconds)) {
        if (mounted) setState(() => _bestTimeSeconds = _elapsedSeconds);
      }
      if (mounted) _showSolvedDialog();
    } else {
      await _saveGame();
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showSolvedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クリア！'),
        content: Text('タイム: ${_formatTime(_elapsedSeconds)}\n手数: $_moves'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text('もう一度'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スライドパズル'),
        actions: [
          IconButton(
            onPressed: _startNewGame,
            icon: const Icon(Icons.refresh),
            tooltip: '新しいゲーム',
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
                  _StatBox(label: '手数', value: '$_moves'),
                  _StatBox(label: 'タイム', value: _formatTime(_elapsedSeconds)),
                  _StatBox(
                    label: 'ベスト',
                    value: _bestTimeSeconds == null
                        ? '--:--'
                        : _formatTime(_bestTimeSeconds!),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _PuzzleGrid(board: _board, onTap: _handleTap),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('空きマスの隣のピースをタップして動かそう'),
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
      width: 96,
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

class _PuzzleGrid extends StatelessWidget {
  const _PuzzleGrid({required this.board, required this.onTap});

  final SlidingPuzzleBoard board;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: SlidingPuzzleBoard.size,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: SlidingPuzzleBoard.size * SlidingPuzzleBoard.size,
        itemBuilder: (context, index) {
          final value = board.tiles[index];
          final movable = board.movableIndices.contains(index);
          return _PuzzlePiece(
            value: value,
            movable: movable,
            onTap: () => onTap(index),
          );
        },
      ),
    );
  }
}

class _PuzzlePiece extends StatelessWidget {
  const _PuzzlePiece({
    required this.value,
    required this.movable,
    required this.onTap,
  });

  final int value;
  final bool movable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox.expand();

    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Material(
        color: movable
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
