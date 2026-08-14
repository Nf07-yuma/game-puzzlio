import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_state_storage.dart';
import '../../services/score_service.dart';
import 'sliding_puzzle_logic.dart';

enum _GameMenuAction { restart, newGame }

class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({super.key});

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen> {
  static const String _gameId = 'sliding_puzzle';

  final Random _random = Random();

  late SlidingPuzzleBoard _board;
  late SlidingPuzzleBoard _initialBoard;
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
    final initialTilesRaw = saved['initialTiles'] as List?;
    setState(() {
      _board = SlidingPuzzleBoard(tiles);
      _initialBoard = initialTilesRaw != null
          ? SlidingPuzzleBoard(initialTilesRaw.cast<int>())
          : _board;
      _moves = saved['moves'] as int;
      _elapsedSeconds = saved['elapsedSeconds'] as int;
    });
  }

  Future<void> _saveGame() async {
    await GameStateStorage.instance.save(_gameId, {
      'tiles': _board.tiles,
      'initialTiles': _initialBoard.tiles,
      'moves': _moves,
      'elapsedSeconds': _elapsedSeconds,
    });
  }

  void _resetBoard() {
    _timer?.cancel();
    final board = SlidingPuzzleBoard.shuffled(_random);
    setState(() {
      _board = board;
      _initialBoard = board;
      _moves = 0;
      _elapsedSeconds = 0;
      _solved = false;
    });
    _startTimer();
  }

  void _startTimer() {
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

  /// Restarts the puzzle currently on screen from its original shuffle,
  /// undoing every move -- unlike [_startNewGame], this keeps the same
  /// shuffled layout instead of generating a new one.
  void _resetToInitialState() {
    _timer?.cancel();
    setState(() {
      _board = _initialBoard;
      _moves = 0;
      _elapsedSeconds = 0;
      _solved = false;
    });
    _startTimer();
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
          PopupMenuButton<_GameMenuAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'メニュー',
            onSelected: (action) {
              switch (action) {
                case _GameMenuAction.restart:
                  _resetToInitialState();
                case _GameMenuAction.newGame:
                  _startNewGame();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _GameMenuAction.restart,
                child: Row(
                  children: [
                    Icon(Icons.replay),
                    SizedBox(width: 12),
                    Text('最初からやり直す'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _GameMenuAction.newGame,
                child: Row(
                  children: [
                    Icon(Icons.shuffle),
                    SizedBox(width: 12),
                    Text('新しいゲーム'),
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
              child: Text('空きマスの隣のピースをタップ、またはドラッグして動かそう'),
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

/// Renders the board as a [Stack] of tiles positioned by pixel offset
/// (rather than a [GridView]) so a tile can animate smoothly between cells
/// -- either sliding into place after a tap, or tracking a finger drag and
/// snapping/springing back on release.
class _PuzzleGrid extends StatefulWidget {
  const _PuzzleGrid({required this.board, required this.onTap});

  final SlidingPuzzleBoard board;
  final ValueChanged<int> onTap;

  @override
  State<_PuzzleGrid> createState() => _PuzzleGridState();
}

class _PuzzleGridState extends State<_PuzzleGrid> {
  static const double _spacing = 8;
  static const double _commitThresholdFraction = 0.35;

  int? _draggingIndex;
  Offset _dragOffset = Offset.zero;

  @override
  void didUpdateWidget(covariant _PuzzleGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The board only changes once a move is committed (tap or a completed
    // drag), at which point any in-progress drag is already done with.
    if (oldWidget.board != widget.board) {
      _draggingIndex = null;
      _dragOffset = Offset.zero;
    }
  }

  /// Clamps a raw drag delta to the single direction that actually slides
  /// [index] into the blank space at [blankIndex] -- e.g. only rightward if
  /// the blank is to the right -- so the tile can't be dragged past it or
  /// off in an illegal direction.
  Offset _clampToBlank(
    Offset raw,
    int index,
    int blankIndex,
    double cellExtent,
  ) {
    const size = SlidingPuzzleBoard.size;
    final tileRow = index ~/ size;
    final tileCol = index % size;
    final blankRow = blankIndex ~/ size;
    final blankCol = blankIndex % size;
    if (tileRow == blankRow) {
      final dx = blankCol > tileCol
          ? raw.dx.clamp(0, cellExtent)
          : raw.dx.clamp(-cellExtent, 0);
      return Offset(dx.toDouble(), 0);
    }
    final dy = blankRow > tileRow
        ? raw.dy.clamp(0, cellExtent)
        : raw.dy.clamp(-cellExtent, 0);
    return Offset(0, dy.toDouble());
  }

  void _handlePanStart(int index) {
    setState(() {
      _draggingIndex = index;
      _dragOffset = Offset.zero;
    });
  }

  void _handlePanUpdate(
    int index,
    DragUpdateDetails details,
    double cellExtent,
  ) {
    if (_draggingIndex != index) return;
    setState(() {
      _dragOffset = _clampToBlank(
        _dragOffset + details.delta,
        index,
        widget.board.blankIndex,
        cellExtent,
      );
    });
  }

  void _handlePanEnd(int index, double cellExtent) {
    if (_draggingIndex != index) return;
    final traveled = _dragOffset.dx.abs() + _dragOffset.dy.abs();
    final committed = traveled > cellExtent * _commitThresholdFraction;
    setState(() {
      _draggingIndex = null;
      _dragOffset = Offset.zero;
    });
    if (committed) widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const size = SlidingPuzzleBoard.size;
          final cell = (constraints.maxWidth - _spacing * (size - 1)) / size;
          return Stack(
            children: [
              for (var index = 0; index < widget.board.tiles.length; index++)
                if (widget.board.tiles[index] != 0)
                  _buildTile(index, cell, colorScheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTile(int index, double cell, ColorScheme colorScheme) {
    const size = SlidingPuzzleBoard.size;
    final value = widget.board.tiles[index];
    final movable = widget.board.movableIndices.contains(index);
    final dragging = _draggingIndex == index;
    final offset = dragging ? _dragOffset : Offset.zero;

    return AnimatedPositioned(
      key: ValueKey(value),
      duration: dragging ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      left: (index % size) * (cell + _spacing) + offset.dx,
      top: (index ~/ size) * (cell + _spacing) + offset.dy,
      width: cell,
      height: cell,
      child: GestureDetector(
        onPanStart: movable ? (_) => _handlePanStart(index) : null,
        onPanUpdate: movable
            ? (details) => _handlePanUpdate(index, details, cell)
            : null,
        onPanEnd: movable ? (_) => _handlePanEnd(index, cell) : null,
        onPanCancel: movable ? () => _handlePanEnd(index, cell) : null,
        child: _PuzzlePiece(
          value: value,
          movable: movable,
          onTap: () => widget.onTap(index),
        ),
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
