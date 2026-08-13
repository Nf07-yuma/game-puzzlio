import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/services/game_state_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameStateStorage', () {
    test('load returns null when nothing has been saved', () async {
      final result = await GameStateStorage.instance.load('unknown_game');
      expect(result, isNull);
    });

    test('save then load round-trips the state', () async {
      await GameStateStorage.instance.save('game_a', {
        'tiles': [1, 2, 3],
        'score': 42,
      });

      final result = await GameStateStorage.instance.load('game_a');

      expect(result, isNotNull);
      expect(result!['tiles'], [1, 2, 3]);
      expect(result['score'], 42);
    });

    test('clear removes the saved state', () async {
      await GameStateStorage.instance.save('game_b', {'moves': 5});
      await GameStateStorage.instance.clear('game_b');

      final result = await GameStateStorage.instance.load('game_b');

      expect(result, isNull);
    });

    test('state for different game ids does not collide', () async {
      await GameStateStorage.instance.save('game_c', {'value': 1});
      await GameStateStorage.instance.save('game_d', {'value': 2});

      final resultC = await GameStateStorage.instance.load('game_c');
      final resultD = await GameStateStorage.instance.load('game_d');

      expect(resultC!['value'], 1);
      expect(resultD!['value'], 2);
    });
  });
}
