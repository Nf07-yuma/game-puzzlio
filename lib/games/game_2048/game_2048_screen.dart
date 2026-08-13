import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/score_service.dart';
import 'game_2048_logic.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const String _gameId = '2048';

  final Random _random = Random();

  late Board2048 _board;
  int _score = 0;
  int? _bestScore;
  bool _gameOver = false;
  bool _wonBannerShown = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final best = await ScoreService.instance.getBestScore(_gameId);
    if (mounted) setState(() => _bestScore = best);
  }

  void _startNewGame() {
    var board = Board2048.empty();
    board = board.withRandomTile(_random);
    board = board.withRandomTile(_random);
    setState(() {
      _board = board;
      _score = 0;
      _gameOver = false;
      _wonBannerShown = false;
    });
  }

  Future<void> _handleMove(SwipeDirection direction) async {
    if (_gameOver) return;
    final result = _board.move(direction);
    if (!result.moved) return;

    final newBoard = result.board.withRandomTile(_random);
    final newScore = _score + result.scoreGained;
    setState(() {
      _board = newBoard;
      _score = newScore;
      _gameOver = !newBoard.canMove;
    });

    if (await ScoreService.instance.submitScore(_gameId, newScore)) {
      if (mounted) setState(() => _bestScore = newScore);
    }

    if (!_wonBannerShown && newBoard.hasWon) {
      _wonBannerShown = true;
      if (mounted) _showWinDialog();
    } else if (_gameOver) {
      if (mounted) _showGameOverDialog();
    }
  }

  void _showWinDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('2048達成！'),
        content: const Text('おめでとうございます！このまま続けて遊べます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('続ける'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text('新しく始める'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームオーバー'),
        content: Text('スコア: $_score'),
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
        title: const Text('2048'),
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
                  _ScoreBox(label: 'スコア', value: '$_score'),
                  _ScoreBox(label: 'ベスト', value: '${_bestScore ?? 0}'),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 100) return;
                    _handleMove(
                      velocity > 0 ? SwipeDirection.right : SwipeDirection.left,
                    );
                  },
                  onVerticalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 100) return;
                    _handleMove(
                      velocity > 0 ? SwipeDirection.down : SwipeDirection.up,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _Board2048View(board: _board),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('上下左右にスワイプしてタイルを動かそう'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
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
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Board2048View extends StatelessWidget {
  const _Board2048View({required this.board});

  final Board2048 board;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Board2048.size,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: Board2048.size * Board2048.size,
        itemBuilder: (context, index) {
          final value = board.tiles[index];
          return _Tile(value: value);
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value});

  final int value;

  Color _backgroundColor() {
    const colors = {
      2: Color(0xFFEEE4DA),
      4: Color(0xFFEDE0C8),
      8: Color(0xFFF2B179),
      16: Color(0xFFF59563),
      32: Color(0xFFF67C5F),
      64: Color(0xFFF65E3B),
      128: Color(0xFFEDCF72),
      256: Color(0xFFEDCC61),
      512: Color(0xFFEDC850),
      1024: Color(0xFFEDC53F),
      2048: Color(0xFFEDC22E),
    };
    return colors[value] ?? const Color(0xFF3C3A32);
  }

  Color _textColor() => value <= 4 ? const Color(0xFF776E65) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: value == 0
            ? Colors.white.withValues(alpha: 0.35)
            : _backgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: value == 0
          ? null
          : Text(
              '$value',
              style: TextStyle(
                color: _textColor(),
                fontWeight: FontWeight.bold,
                fontSize: value >= 1024 ? 22 : 26,
              ),
            ),
    );
  }
}
