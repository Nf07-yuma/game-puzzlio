import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists in-progress game state so a game can be resumed after
/// navigating away (e.g. back to the home screen) instead of restarting.
/// Callers are responsible for clearing the state once a round finishes.
class GameStateStorage {
  GameStateStorage._();
  static final GameStateStorage instance = GameStateStorage._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _key(String gameId) => 'game_state_$gameId';

  Future<void> save(String gameId, Map<String, dynamic> state) async {
    final prefs = await _prefsInstance;
    await prefs.setString(_key(gameId), jsonEncode(state));
  }

  Future<Map<String, dynamic>?> load(String gameId) async {
    final prefs = await _prefsInstance;
    final raw = prefs.getString(_key(gameId));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String gameId) async {
    final prefs = await _prefsInstance;
    await prefs.remove(_key(gameId));
  }
}
