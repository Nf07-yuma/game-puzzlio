import 'package:shared_preferences/shared_preferences.dart';

/// Persists best scores / best times per game across app launches.
class ScoreService {
  ScoreService._();
  static final ScoreService instance = ScoreService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<int?> getBestScore(String gameId) async {
    final prefs = await _prefsInstance;
    return prefs.getInt('best_score_$gameId');
  }

  /// Saves [score] as the new best if it beats the current one.
  /// Returns true if a new record was set.
  Future<bool> submitScore(String gameId, int score) async {
    final prefs = await _prefsInstance;
    final key = 'best_score_$gameId';
    final current = prefs.getInt(key);
    if (current == null || score > current) {
      await prefs.setInt(key, score);
      return true;
    }
    return false;
  }

  Future<int?> getBestTimeSeconds(String gameId) async {
    final prefs = await _prefsInstance;
    return prefs.getInt('best_time_$gameId');
  }

  /// Saves [seconds] as the new best (lowest) time if it beats the
  /// current one. Returns true if a new record was set.
  Future<bool> submitTime(String gameId, int seconds) async {
    final prefs = await _prefsInstance;
    final key = 'best_time_$gameId';
    final current = prefs.getInt(key);
    if (current == null || seconds < current) {
      await prefs.setInt(key, seconds);
      return true;
    }
    return false;
  }
}
