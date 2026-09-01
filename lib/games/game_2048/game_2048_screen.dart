import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_state_storage.dart';
import '../../services/score_service.dart';
import '../../widgets/stat_box.dart';
import 'game_2048_logic.dart';
import 'game_2048_tile_animation.dart';

enum _GameMenuAction { restart, newGame }

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const String _gameId = '2048';

  final Random _random = Random();

  late Board2048 _board;
  late Board2048 _initialBoard;
  List<AnimatedTile> _tiles = [];
  int _nextTileId = 0;
  int _score = 0;
  int? _bestScore;
  bool _gameOver = false;
  bool _wonBannerShown = false;

  @override
  void initState() {
    super.initState();
    _resetBoard();
    _loadBestScore();
    _restoreSavedGame();
  }

  Future<void> _loadBestScore() async {
    final best = await ScoreService.instance.getBestScore(_gameId);
    if (mounted) setState(() => _bestScore = best);
  }

  /// Restores an in-progress game saved before navigating away, if any.
  /// Runs after the initial fresh board is already showing, so a missing
  /// save simply persists that fresh board instead of leaving it unsaved.
  Future<void> _restoreSavedGame() async {
    final saved = await GameStateStorage.instance.load(_gameId);
    if (!mounted) return;
    if (saved == null) {
      await _saveGame();
      return;
    }
    final tiles = (saved['tiles'] as List).cast<int>();
    final board = Board2048(tiles);
    final initialTilesRaw = saved['initialTiles'] as List?;
    final initialBoard = initialTilesRaw != null
        ? Board2048(initialTilesRaw.cast<int>())
        : board;
    setState(() {
      _board = board;
      _tiles = _tilesFromBoard(board);
      _initialBoard = initialBoard;
      _score = saved['score'] as int;
      _gameOver = !board.canMove;
      _wonBannerShown = board.hasWon;
    });
  }

  /// Assigns fresh, unique ids to every occupied cell of [board], in
  /// row-major order. Used whenever tile identity doesn't need to carry
  /// over from a previous frame (initial deal, restoring a saved game).
  List<AnimatedTile> _tilesFromBoard(Board2048 board) {
    final tiles = <AnimatedTile>[];
    for (var i = 0; i < board.tiles.length; i++) {
      final value = board.tiles[i];
      if (value == 0) continue;
      tiles.add(
        AnimatedTile(
          id: _nextTileId++,
          value: value,
          row: i ~/ Board2048.size,
          col: i % Board2048.size,
        ),
      );
    }
    return tiles;
  }

  Future<void> _saveGame() async {
    await GameStateStorage.instance.save(_gameId, {
      'tiles': _board.tiles,
      'initialTiles': _initialBoard.tiles,
      'score': _score,
    });
  }

  void _resetBoard() {
    var board = Board2048.empty();
    board = board.withRandomTile(_random);
    board = board.withRandomTile(_random);
    final tiles = _tilesFromBoard(board);
    setState(() {
      _board = board;
      _tiles = tiles;
      _initialBoard = board;
      _score = 0;
      _gameOver = false;
      _wonBannerShown = false;
    });
  }

  void _startNewGame() {
    GameStateStorage.instance.clear(_gameId);
    _resetBoard();
    _saveGame();
  }

  /// Restarts the current game from its original two starting tiles,
  /// discarding every move -- unlike [_startNewGame], this replays the
  /// same deal instead of dealing a new one.
  void _resetToInitialState() {
    setState(() {
      _board = _initialBoard;
      _tiles = _tilesFromBoard(_initialBoard);
      _score = 0;
      _gameOver = false;
      _wonBannerShown = false;
    });
    _saveGame();
  }

  Future<void> _handleMove(SwipeDirection direction) async {
    if (_gameOver) return;
    final result = _board.move(direction);
    if (!result.moved) return;
    HapticFeedback.lightImpact();

    final slidTiles = slideAnimatedTiles(_tiles, direction);
    final newBoard = result.board.withRandomTile(_random);
    var newTiles = slidTiles;
    for (var i = 0; i < newBoard.tiles.length; i++) {
      if (result.board.tiles[i] == 0 && newBoard.tiles[i] != 0) {
        newTiles = [
          ...slidTiles,
          AnimatedTile(
            id: _nextTileId++,
            value: newBoard.tiles[i],
            row: i ~/ Board2048.size,
            col: i % Board2048.size,
            isNew: true,
          ),
        ];
        break;
      }
    }

    final newScore = _score + result.scoreGained;
    setState(() {
      _board = newBoard;
      _tiles = newTiles;
      _score = newScore;
      _gameOver = !newBoard.canMove;
    });

    if (_gameOver) {
      HapticFeedback.heavyImpact();
      await GameStateStorage.instance.clear(_gameId);
    } else {
      await _saveGame();
    }

    if (await ScoreService.instance.submitScore(_gameId, newScore)) {
      if (mounted) setState(() => _bestScore = newScore);
    }

    if (!_wonBannerShown && newBoard.hasWon) {
      _wonBannerShown = true;
      HapticFeedback.mediumImpact();
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
                  StatBox(
                      label: 'スコア', value: '$_score', width: 120, accent: true),
                  StatBox(
                      label: 'ベスト', value: '${_bestScore ?? 0}', width: 120),
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
                      child: _Board2048View(tiles: _tiles),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '上下左右にスワイプしてタイルを動かそう',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Board2048View extends StatelessWidget {
  const _Board2048View({required this.tiles});

  final List<AnimatedTile> tiles;

  static const double _spacing = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell =
              (constraints.maxWidth - _spacing * (Board2048.size - 1)) /
                  Board2048.size;
          return Stack(
            children: [
              for (var i = 0; i < Board2048.size * Board2048.size; i++)
                Positioned(
                  left: (i % Board2048.size) * (cell + _spacing),
                  top: (i ~/ Board2048.size) * (cell + _spacing),
                  width: cell,
                  height: cell,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              for (final tile in tiles)
                AnimatedPositioned(
                  key: ValueKey(tile.id),
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.easeOutCubic,
                  left: tile.col * (cell + _spacing),
                  top: tile.row * (cell + _spacing),
                  width: cell,
                  height: cell,
                  child: _Tile(
                    value: tile.value,
                    isNew: tile.isNew,
                    justMerged: tile.justMerged,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    this.isNew = false,
    this.justMerged = false,
  });

  final int value;
  final bool isNew;
  final bool justMerged;

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
    final tile = Container(
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: TextStyle(
          color: _textColor(),
          fontWeight: FontWeight.bold,
          fontSize: value >= 1024 ? 22 : 26,
        ),
      ),
    );

    final beginScale = isNew ? 0.4 : (justMerged ? 1.18 : 1.0);
    return TweenAnimationBuilder<double>(
      key: ValueKey('$value-$isNew-$justMerged'),
      tween: Tween(begin: beginScale, end: 1.0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: tile,
    );
  }
}
