import 'package:shared_preferences/shared_preferences.dart';

class GameDataService {
  static const String _highScoreKey = 'high_score';
  static const String _currentLevelKey = 'current_level';
  static const String _totalCoinsKey = 'total_coins';
  static const String _unlockedLevelsKey = 'unlocked_levels';
  static const String _playerNameKey = 'player_name';
  static const String _gamesPlayedKey = 'games_played';
  static const String _totalPlayTimeKey = 'total_play_time';
  static const String _enemiesDefeatedKey = 'enemies_defeated';
  static const String _bossesDefeatedKey = 'bosses_defeated';
  static const String _packagesThrownKey = 'packages_thrown';

  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  static Future<int> getHighScore() async {
    final prefs = await _prefs;
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  static Future<void> setHighScore(int score) async {
    final prefs = await _prefs;
    final currentHighScore = await getHighScore();
    if (score > currentHighScore) {
      await prefs.setInt(_highScoreKey, score);
    }
  }

  static Future<int> getCurrentLevel() async {
    final prefs = await _prefs;
    return prefs.getInt(_currentLevelKey) ?? 1;
  }

  static Future<void> setCurrentLevel(int level) async {
    final prefs = await _prefs;
    await prefs.setInt(_currentLevelKey, level);
  }

  static Future<List<int>> getUnlockedLevels() async {
    final prefs = await _prefs;
    final unlockedLevelsString = prefs.getString(_unlockedLevelsKey) ?? '1';
    return unlockedLevelsString.split(',').map(int.parse).toList();
  }

  static Future<void> unlockLevel(int level) async {
    final unlockedLevels = await getUnlockedLevels();
    if (!unlockedLevels.contains(level)) {
      unlockedLevels.add(level);
      final prefs = await _prefs;
      await prefs.setString(_unlockedLevelsKey, unlockedLevels.join(','));
    }
  }

  static Future<bool> isLevelUnlocked(int level) async {
    final unlockedLevels = await getUnlockedLevels();
    return unlockedLevels.contains(level);
  }

  static Future<int> getTotalCoins() async {
    final prefs = await _prefs;
    return prefs.getInt(_totalCoinsKey) ?? 0;
  }

  static Future<void> addCoins(int coins) async {
    final currentCoins = await getTotalCoins();
    final prefs = await _prefs;
    await prefs.setInt(_totalCoinsKey, currentCoins + coins);
  }

  static Future<bool> spendCoins(int coins) async {
    final currentCoins = await getTotalCoins();
    if (currentCoins >= coins) {
      final prefs = await _prefs;
      await prefs.setInt(_totalCoinsKey, currentCoins - coins);
      return true;
    }
    return false;
  }

  static Future<void> saveGameProgress(int score, int level) async {
    await setHighScore(score);
    await setCurrentLevel(level);

    int coinsEarned = score ~/ 10;
    await addCoins(coinsEarned);

    // زيادة عدد الألعاب الملعوبة
    final gamesPlayed = await getGamesPlayed();
    final prefs = await _prefs;
    await prefs.setInt(_gamesPlayedKey, gamesPlayed + 1);

    if (score >= getLevelTargetScore(level)) {
      await unlockLevel(level + 1);
    }
  }

  static int getLevelTargetScore(int level) {
    return level * 100;
  }

  static Future<void> resetGameData() async {
    final prefs = await _prefs;
    await prefs.remove(_highScoreKey);
    await prefs.remove(_currentLevelKey);
    await prefs.remove(_totalCoinsKey);
    await prefs.remove(_unlockedLevelsKey);
    await prefs.remove(_gamesPlayedKey);
    await prefs.remove(_totalPlayTimeKey);
    await prefs.remove(_enemiesDefeatedKey);
    await prefs.remove(_bossesDefeatedKey);
    await prefs.remove(_packagesThrownKey);

    // إعادة تعيين المستوى الأول
    await prefs.setString(_unlockedLevelsKey, '1');
  }

  static Future<String> getPlayerName() async {
    final prefs = await _prefs;
    return prefs.getString(_playerNameKey) ?? 'اللاعب';
  }

  static Future<void> setPlayerName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_playerNameKey, name);
  }

  static Future<int> getGamesPlayed() async {
    final prefs = await _prefs;
    return prefs.getInt(_gamesPlayedKey) ?? 0;
  }

  static Future<int> getTotalPlayTime() async {
    final prefs = await _prefs;
    return prefs.getInt(_totalPlayTimeKey) ?? 0;
  }

  static Future<void> addPlayTime(int seconds) async {
    final currentTime = await getTotalPlayTime();
    final prefs = await _prefs;
    await prefs.setInt(_totalPlayTimeKey, currentTime + seconds);
  }

  static Future<int> getEnemiesDefeated() async {
    final prefs = await _prefs;
    return prefs.getInt(_enemiesDefeatedKey) ?? 0;
  }

  static Future<void> addEnemiesDefeated(int count) async {
    final currentCount = await getEnemiesDefeated();
    final prefs = await _prefs;
    await prefs.setInt(_enemiesDefeatedKey, currentCount + count);
  }

  static Future<int> getBossesDefeated() async {
    final prefs = await _prefs;
    return prefs.getInt(_bossesDefeatedKey) ?? 0;
  }

  static Future<void> addBossDefeated() async {
    final currentCount = await getBossesDefeated();
    final prefs = await _prefs;
    await prefs.setInt(_bossesDefeatedKey, currentCount + 1);
  }

  static Future<int> getPackagesThrown() async {
    final prefs = await _prefs;
    return prefs.getInt(_packagesThrownKey) ?? 0;
  }

  static Future<void> addPackagesThrown(int count) async {
    final currentCount = await getPackagesThrown();
    final prefs = await _prefs;
    await prefs.setInt(_packagesThrownKey, currentCount + count);
  }

  // الحصول على إحصائيات اللاعب
  static Future<Map<String, dynamic>> getPlayerStats() async {
    return {
      'highScore': await getHighScore(),
      'currentLevel': await getCurrentLevel(),
      'totalCoins': await getTotalCoins(),
      'unlockedLevels': await getUnlockedLevels(),
      'playerName': await getPlayerName(),
      'gamesPlayed': await getGamesPlayed(),
      'totalPlayTime': await getTotalPlayTime(),
      'enemiesDefeated': await getEnemiesDefeated(),
      'bossesDefeated': await getBossesDefeated(),
      'packagesThrown': await getPackagesThrown(),
    };
  }

  // التحقق إذا تم تختيم اللعبة
  static Future<bool> isGameCompleted() async {
    final unlockedLevels = await getUnlockedLevels();
    return unlockedLevels.contains(100);
  }
}