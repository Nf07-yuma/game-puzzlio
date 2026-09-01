import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/games/territory/territory_logic.dart';
import 'package:puzzlio/games/territory/territory_screen.dart';
import 'package:puzzlio/services/game_state_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // SharedPreferences and the app's storage singletons cache their data
    // for the lifetime of the test process, so resetting the mock values
    // alone doesn't clear state a previous test already saved -- explicitly
    // clear the saved-game slot each of these tests reads/writes.
    SharedPreferences.setMockInitialValues({});
    await GameStateStorage.instance.clear('territory_puzzle_current');
  });

  // Level 1 always uses a size-5 board (TerritoryPuzzle.sizeForLevel(1)),
  // regardless of the randomly generated layout, so cell centers can be
  // computed without needing to know the puzzle's contents.
  final boardSize = TerritoryPuzzle.sizeForLevel(1);

  Offset cellCenter(WidgetTester tester, int row, int col) {
    final gridBox = tester.getRect(find.byType(GridView));
    final cellWidth = gridBox.width / boardSize;
    final cellHeight = gridBox.height / boardSize;
    return gridBox.topLeft +
        Offset((col + 0.5) * cellWidth, (row + 0.5) * cellHeight);
  }

  testWidgets('tapping a cell cycles empty -> X -> flag -> empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TerritoryScreen()),
    );
    await tester.pumpAndSettle();

    final center = cellCenter(tester, 0, 0);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsNothing);

    await tester.tapAt(center);
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsNothing);

    await tester.tapAt(center);
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsOneWidget);

    await tester.tapAt(center);
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsNothing);
  });

  testWidgets(
    'tapping X again within the flag window places a flag',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TerritoryScreen()),
      );
      await tester.pumpAndSettle();

      final center = cellCenter(tester, 3, 3);
      await tester.tapAt(center); // -> X
      await tester.pump();

      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 500)),
      );

      await tester.tapAt(center); // well within the 3s window -> flag
      await tester.pump();
      expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping X again after the flag window elapses clears the cell instead',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TerritoryScreen()),
      );
      await tester.pumpAndSettle();

      final center = cellCenter(tester, 3, 3);
      await tester.tapAt(center); // -> X
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.runAsync(
        () => Future.delayed(const Duration(seconds: 3, milliseconds: 200)),
      );

      await tester.tapAt(center); // window elapsed -> empty, not flag
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'dragging across cells marks each one with an X without lifting',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TerritoryScreen()),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(cellCenter(tester, 1, 0));
      await gesture.moveTo(cellCenter(tester, 1, 1));
      await gesture.moveTo(cellCenter(tester, 1, 2));
      await gesture.moveTo(cellCenter(tester, 1, 3));
      await gesture.up();
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsNWidgets(4));
    },
  );

  testWidgets('dragging over a placed flag does not clear it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TerritoryScreen()),
    );
    await tester.pumpAndSettle();

    final flagCell = cellCenter(tester, 2, 2);
    await tester.tapAt(flagCell); // -> X
    await tester.pump();
    await tester.tapAt(flagCell); // -> flag
    await tester.pump();
    expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsOneWidget);

    final gesture = await tester.startGesture(cellCenter(tester, 2, 0));
    await gesture.moveTo(cellCenter(tester, 2, 1));
    await gesture.moveTo(flagCell);
    await gesture.moveTo(cellCenter(tester, 2, 3));
    await gesture.up();
    await tester.pump();

    // The flag cell is untouched; only the other three dragged-over cells
    // picked up an X.
    expect(
        find.descendant(of: find.byType(GridView), matching: find.text('🚩')),
        findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(3));
  });
}
