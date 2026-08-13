import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/score_service.dart';
import 'sudoku_logic.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final Random _random = Random();

  SudokuDifficulty _difficulty = SudokuDifficulty.medium;
  late SudokuPuzzle _puzzle;
  late List<int> _grid;
  Set<int> _conflicts = {};
  int? _selectedIndex;
  int _elapsedSeconds = 0;
  int? _bestTimeSeconds;
  Timer? _timer;
  bool _solved = false;

  String get _gameId => 'sudoku_${_difficulty.name}';

  @override
  void initState() {
    super.initState();
    _startNewGame();
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

  void _startNewGame() {
    _timer?.cancel();
    final puzzle = SudokuPuzzle.generate(_random, _difficulty);
    setState(() {
      _puzzle = puzzle;
      _grid = List<int>.from(puzzle.puzzle);
      _conflicts = {};
      _selectedIndex = null;
      _elapsedSeconds = 0;
      _solved = false;
    });
    _loadBestTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _selectCell(int index) {
    if (_solved || _puzzle.isGiven(index)) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _inputValue(int value) async {
    final index = _selectedIndex;
    if (index == null || _solved) return;
    setState(() {
      _grid[index] = value;
      _conflicts = SudokuPuzzle.findConflicts(_grid);
    });

    final isFull = !_grid.contains(0);
    if (isFull && _conflicts.isEmpty) {
      _timer?.cancel();
      setState(() => _solved = true);
      if (await ScoreService.instance.submitTime(_gameId, _elapsedSeconds)) {
        if (mounted) setState(() => _bestTimeSeconds = _elapsedSeconds);
      }
      if (mounted) _showSolvedDialog();
    }
  }

  void _erase() {
    final index = _selectedIndex;
    if (index == null || _solved) return;
    setState(() {
      _grid[index] = 0;
      _conflicts = SudokuPuzzle.findConflicts(_grid);
    });
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
        content: Text('タイム: ${_formatTime(_elapsedSeconds)}'),
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

  Future<void> _pickDifficulty() async {
    final result = await showModalBottomSheet<SudokuDifficulty>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final difficulty in SudokuDifficulty.values)
              ListTile(
                title: Text(difficulty.label),
                trailing:
                    difficulty == _difficulty ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(difficulty),
              ),
          ],
        ),
      ),
    );
    if (result != null && result != _difficulty) {
      setState(() => _difficulty = result);
      _startNewGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数独'),
        actions: [
          IconButton(
            onPressed: _pickDifficulty,
            icon: const Icon(Icons.tune),
            tooltip: '難易度',
          ),
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
                  _StatBox(label: '難易度', value: _difficulty.label),
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
                    child: _SudokuGrid(
                      puzzle: _puzzle,
                      grid: _grid,
                      conflicts: _conflicts,
                      selectedIndex: _selectedIndex,
                      onTap: _selectCell,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _NumberPad(onInput: _inputValue, onErase: _erase),
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

class _SudokuGrid extends StatelessWidget {
  const _SudokuGrid({
    required this.puzzle,
    required this.grid,
    required this.conflicts,
    required this.selectedIndex,
    required this.onTap,
  });

  final SudokuPuzzle puzzle;
  final List<int> grid;
  final Set<int> conflicts;
  final int? selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedValue = selectedIndex == null ? null : grid[selectedIndex!];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline, width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final col = index % 9;
          final value = grid[index];
          final isGiven = puzzle.isGiven(index);
          final isSelected = index == selectedIndex;
          final isConflict = conflicts.contains(index);
          final isSameValue = selectedValue != null &&
              selectedValue != 0 &&
              value == selectedValue;

          Color background;
          if (isSelected) {
            background = colorScheme.primary.withValues(alpha: 0.35);
          } else if (isSameValue) {
            background = colorScheme.primary.withValues(alpha: 0.15);
          } else if ((row ~/ 3 + col ~/ 3).isEven) {
            background = colorScheme.surfaceContainerHighest;
          } else {
            background = colorScheme.surface;
          }

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: background,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline,
                    width: row % 3 == 0 ? 1.5 : 0.3,
                  ),
                  left: BorderSide(
                    color: colorScheme.outline,
                    width: col % 3 == 0 ? 1.5 : 0.3,
                  ),
                  right: BorderSide(
                    color: colorScheme.outline,
                    width: col == 8 ? 1.5 : 0.3,
                  ),
                  bottom: BorderSide(
                    color: colorScheme.outline,
                    width: row == 8 ? 1.5 : 0.3,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: value == 0
                  ? null
                  : Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isGiven ? FontWeight.bold : FontWeight.normal,
                        color: isConflict
                            ? colorScheme.error
                            : isGiven
                                ? colorScheme.onSurface
                                : colorScheme.primary,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onInput, required this.onErase});

  final ValueChanged<int> onInput;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var value = 1; value <= 9; value++)
          _PadButton(label: '$value', onTap: () => onInput(value)),
        _PadButton(
          label: '',
          icon: Icons.backspace_outlined,
          onTap: onErase,
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({required this.label, this.icon, required this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 20)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
