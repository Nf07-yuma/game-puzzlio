import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen lists all puzzle games', (tester) async {
    await tester.pumpWidget(const PuzzlioApp());
    await tester.pumpAndSettle();

    expect(find.text('Puzzlio'), findsOneWidget);
    expect(find.text('2048'), findsOneWidget);
    expect(find.text('スライドパズル'), findsOneWidget);
    expect(find.text('数独'), findsOneWidget);
  });

  testWidgets('tapping a game card opens its screen', (tester) async {
    await tester.pumpWidget(const PuzzlioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('2048'));
    await tester.pumpAndSettle();

    expect(find.text('スコア'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
