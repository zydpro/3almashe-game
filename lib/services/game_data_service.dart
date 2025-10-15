// services/game_data_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // ✅ استخدم مكتبة json الرسمية
import '../models/character_model.dart';

class GameDataService with ChangeNotifier {
  static final GameDataService _instance = GameDataService._internal();
  factory GameDataService() => _instance;
  GameDataService._internal();

  // ✅ نظام الإشعارات للتحديثات
  final List<VoidCallback> _updateCallbacks = [];

  void addUpdateListener(VoidCallback callback) {
    _updateCallbacks.add(callback);
  }

  void removeUpdateListener(VoidCallback callback) {
    _updateCallbacks.remove(callback);
  }

  void _notifyDataUpdated() {
    for (var callback in _updateCallbacks) {
      callback();
    }
    notifyListeners();
  }

  // مفاتيح البيانات الأساسية
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

  // مفاتيح نظام الشخصيات
  static const String _ownedCharactersKey = 'owned_characters';
  static const String _selectedCharacterKey = 'selected_character';
  static const String _userCoinsKey = 'user_coins';

  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ========== نظام الشخصيات المحسن ==========

  static Future<List<GameCharacter>> getOwnedCharacters() async {
    final prefs = await _prefs;
    final ownedCharactersJson = prefs.getStringList(_ownedCharactersKey) ?? [];

    List<GameCharacter> ownedCharacters = [];

    // ✅ الشخصية الافتراضية دائماً مملوكة
    final defaultCharacter = GameCharacter.getDefaultCharacter();
    defaultCharacter.isLocked = false;
    if (!ownedCharacters.any((char) => char.id == defaultCharacter.id)) {
      ownedCharacters.add(defaultCharacter);
    }

    for (var jsonString in ownedCharactersJson) {
      try {
        final character = _characterFromJsonString(jsonString);
        if (character != null && !ownedCharacters.any((c) => c.id == character.id)) {
          character.isLocked = false;
          ownedCharacters.add(character);
        }
      } catch (e) {
        print('❌ خطأ في تحليل الشخصية: $e');
        continue;
      }
    }

    print('💎 الشخصيات المملوكة: ${ownedCharacters.length}');
    return ownedCharacters;
  }

  // ✅ دالة محسنة لتحويل JSON string إلى GameCharacter
  static GameCharacter? _characterFromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return GameCharacter.fromJson(jsonMap);
    } catch (e) {
      print('❌ خطأ في _characterFromJsonString: $e');
      return null;
    }
  }

  static Future<void> saveOwnedCharacters(List<GameCharacter> characters) async {
    final prefs = await _prefs;

    try {
      // ✅ تصفية الشخصيات المملوكة فقط (غير مقفلة)
      final ownedCharacters = characters.where((char) => !char.isLocked).toList();

      // ✅ تحويل إلى JSON باستخدام json.encode
      final charactersJson = ownedCharacters.map((character) {
        return json.encode(character.toJson());
      }).toList();

      await prefs.setStringList(_ownedCharactersKey, charactersJson);
      print('💾 تم حفظ ${ownedCharacters.length} شخصية مملوكة');

      // ✅ إرسال إشعار بالتحديث
      _instance._notifyDataUpdated();
    } catch (e) {
      print('❌ خطأ في حفظ الشخصيات المملوكة: $e');
    }
  }

  // ✅ دالة شراء محسنة
  static Future<bool> purchaseCharacter(GameCharacter character) async {
    try {
      final userCoins = await getUserCoins();
      print('💰 محاولة شراء ${character.name} بسعر ${character.price}، النقاط: $userCoins');

      if (userCoins < character.price) {
        print('❌ نقاط غير كافية');
        return false;
      }

      final ownedCharacters = await getOwnedCharacters();

      // ✅ التحقق إذا كانت الشخصية مملوكة مسبقاً
      if (ownedCharacters.any((c) => c.id == character.id)) {
        print('⚠️ الشخصية مملوكة مسبقاً: ${character.name}');
        return false;
      }

      // ✅ إنشاء نسخة جديدة من الشخصية وفتحها
      final purchasedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        nameEn: character.nameEn,
        imagePath: character.imagePath,
        price: character.price,
        isLocked: false, // ✅ فتح الشخصية
        color: character.color,
        animations: List.from(character.animations),
        description: character.description,
        descriptionEn: character.descriptionEn,
        type: character.type,
        abilities: List.from(character.abilities),
      );

      ownedCharacters.add(purchasedCharacter);
      await saveOwnedCharacters(ownedCharacters);
      await spendCharacterCoins(character.price);

      print('✅ تم شراء الشخصية: ${character.name}');
      _instance._notifyDataUpdated();
      return true;

    } catch (e) {
      print('❌ خطأ في شراء الشخصية: $e');
      return false;
    }
  }

  static Future<GameCharacter> getSelectedCharacter() async {
    try {
      final prefs = await _prefs;
      final selectedId = prefs.getInt(_selectedCharacterKey);
      final ownedCharacters = await getOwnedCharacters();

      GameCharacter selectedCharacter;

      if (selectedId != null) {
        selectedCharacter = ownedCharacters.firstWhere(
              (character) => character.id == selectedId,
          orElse: () => GameCharacter.getDefaultCharacter(),
        );
      } else {
        selectedCharacter = GameCharacter.getDefaultCharacter();
        await setSelectedCharacter(selectedCharacter);
      }

      print('🎯 الشخصية المختارة: ${selectedCharacter.name}');
      return selectedCharacter;
    } catch (e) {
      print('❌ خطأ في الحصول على الشخصية المختارة: $e');
      return GameCharacter.getDefaultCharacter();
    }
  }

  static Future<void> setSelectedCharacter(GameCharacter character) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(_selectedCharacterKey, character.id);
      print('🎯 تم تعيين الشخصية المختارة: ${character.name}');
      _instance._notifyDataUpdated();
    } catch (e) {
      print('❌ خطأ في تعيين الشخصية المختارة: $e');
    }
  }

  static Future<int> getUserCoins() async {
    try {
      final prefs = await _prefs;
      return prefs.getInt(_userCoinsKey) ?? 1000;
    } catch (e) {
      print('❌ خطأ في الحصول على النقاط: $e');
      return 1000;
    }
  }

  static Future<void> setUserCoins(int coins) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(_userCoinsKey, coins);
      print('💰 تم تعيين النقاط: $coins');
    } catch (e) {
      print('❌ خطأ في تعيين النقاط: $e');
    }
  }

  static Future<bool> spendCharacterCoins(int amount) async {
    try {
      final currentCoins = await getUserCoins();
      if (currentCoins >= amount) {
        await setUserCoins(currentCoins - amount);
        print('💰 تم خصم $amount نقطة، المتبقي: ${currentCoins - amount}');
        _instance._notifyDataUpdated();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في خصم النقاط: $e');
      return false;
    }
  }

  static Future<void> addCharacterCoins(int amount) async {
    try {
      final currentCoins = await getUserCoins();
      await setUserCoins(currentCoins + amount);
      print('💰 تم إضافة $amount نقطة، الإجمالي: ${currentCoins + amount}');
      _instance._notifyDataUpdated();
    } catch (e) {
      print('❌ خطأ في إضافة النقاط: $e');
    }
  }

  static Future<bool> isCharacterOwned(int characterId) async {
    final ownedCharacters = await getOwnedCharacters();
    return ownedCharacters.any((character) => character.id == characterId);
  }

  static Future<List<GameCharacter>> getAvailableCharacters() async {
    final allCharacters = GameCharacter.getAllCharacters();
    final ownedCharacters = await getOwnedCharacters();

    return allCharacters.where((character) {
      return !ownedCharacters.any((owned) => owned.id == character.id);
    }).toList();
  }

  // ✅ دالة محسنة للحصول على جميع الشخصيات مع حالة القفل الصحيحة
  static Future<List<GameCharacter>> getAllCharactersWithLockStatus() async {
    try {
      final allCharacters = GameCharacter.getAllCharacters();
      final ownedCharacters = await getOwnedCharacters();

      // ✅ إنشاء نسخ جديدة لتجنب مشاكل المرجع
      final updatedCharacters = allCharacters.map((character) {
        final isOwned = ownedCharacters.any((owned) => owned.id == character.id);
        return GameCharacter(
          id: character.id,
          name: character.name,
          nameEn: character.nameEn,
          imagePath: character.imagePath,
          price: character.price,
          isLocked: !isOwned, // ✅ تعيين حالة القفل
          color: character.color,
          animations: List.from(character.animations),
          description: character.description,
          descriptionEn: character.descriptionEn,
          type: character.type,
          abilities: List.from(character.abilities),
        );
      }).toList();

      print('🔍 ${updatedCharacters.length} شخصية - المملوكة: ${ownedCharacters.length}');
      return updatedCharacters;
    } catch (e) {
      print('❌ خطأ في getAllCharactersWithLockStatus: $e');
      final defaultCharacter = GameCharacter.getDefaultCharacter();
      defaultCharacter.isLocked = false;
      return [defaultCharacter];
    }
  }

  // ✅ دالة لفحص وتصحيح بيانات الشخصيات
  static Future<void> debugCharacterData() async {
    print('🐛 === فحص بيانات الشخصيات ===');

    final coins = await getUserCoins();
    final allCharacters = await getAllCharactersWithLockStatus();
    final ownedCharacters = await getOwnedCharacters();
    final selected = await getSelectedCharacter();

    print('💰 النقاط: $coins');
    print('👤 جميع الشخصيات: ${allCharacters.length}');
    print('💎 الشخصيات المملوكة: ${ownedCharacters.length}');
    print('🎯 الشخصية المختارة: ${selected.name} (ID: ${selected.id})');

    for (var char in allCharacters) {
      print('🔍 ${char.name} - ID: ${char.id} - مقفلة: ${char.isLocked} - السعر: ${char.price}');
    }

    print('🐛 === نهاية الفحص ===');
  }

  // ========== دوال عامة محسنة ==========

  static Future<Map<String, dynamic>> getPlayerStats() async {
    return {
      'highScore': await getHighScore(),
      'currentLevel': await getCurrentLevel(),
      'totalCoins': await getTotalCoins(),
      'userCoins': await getUserCoins(),
      'unlockedLevels': await getUnlockedLevels(),
      'playerName': await getPlayerName(),
      'gamesPlayed': await getGamesPlayed(),
      'totalPlayTime': await getTotalPlayTime(),
      'enemiesDefeated': await getEnemiesDefeated(),
      'bossesDefeated': await getBossesDefeated(),
      'packagesThrown': await getPackagesThrown(),
      'ownedCharacters': await getOwnedCharacters(),
      'selectedCharacter': await getSelectedCharacter(),
    };
  }

  // دوال البيانات الأساسية (نفسها بدون تغيير)
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

  static Future<void> resetGameData() async {
    final prefs = await _prefs;

    // مسح جميع البيانات
    await prefs.remove(_highScoreKey);
    await prefs.remove(_currentLevelKey);
    await prefs.remove(_totalCoinsKey);
    await prefs.remove(_unlockedLevelsKey);
    await prefs.remove(_gamesPlayedKey);
    await prefs.remove(_totalPlayTimeKey);
    await prefs.remove(_enemiesDefeatedKey);
    await prefs.remove(_bossesDefeatedKey);
    await prefs.remove(_packagesThrownKey);
    await prefs.remove(_ownedCharactersKey);
    await prefs.remove(_selectedCharacterKey);
    await prefs.remove(_userCoinsKey);

    // إعادة تعيين البيانات الأساسية
    await prefs.setString(_unlockedLevelsKey, '1');
    await prefs.setInt(_userCoinsKey, 1000);

    // حفظ الشخصية الافتراضية
    final defaultCharacter = GameCharacter.getDefaultCharacter();
    await setSelectedCharacter(defaultCharacter);
    await saveOwnedCharacters([defaultCharacter]);

    // ✅ إرسال إشعار بالتحديث
    _instance._notifyDataUpdated();
  }
}