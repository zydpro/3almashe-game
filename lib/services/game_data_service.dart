// services/game_data_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/character_model.dart';

class GameDataService with ChangeNotifier {
  static final GameDataService _instance = GameDataService._internal();
  factory GameDataService() => _instance;
  GameDataService._internal();

  // نظام الإشعارات للتحديثات
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
  static const String _unlockedLevelsKey = 'unlocked_levels';
  static const String _playerNameKey = 'player_name';
  static const String _gamesPlayedKey = 'games_played';
  static const String _totalPlayTimeKey = 'total_play_time';
  static const String _enemiesDefeatedKey = 'enemies_defeated';
  static const String _bossesDefeatedKey = 'bosses_defeated';
  static const String _packagesThrownKey = 'packages_thrown';

  // مفاتيح نظام الشخصيات والعملات الموحدة
  static const String _ownedCharactersKey = 'owned_characters';
  static const String _selectedCharacterKey = 'selected_character';
  static const String _coinsKey = 'user_coins';

  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ========== نظام العملات الموحد ==========

  static Future<int> getCoins() async {
    try {
      final prefs = await _prefs;
      return prefs.getInt(_coinsKey) ?? 1;
    } catch (e) {
      return 1;
    }
  }

  static Future<void> setCoins(int coins) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(_coinsKey, coins);
      _instance._notifyDataUpdated();
    } catch (e) {}
  }

  static Future<void> addCoins(int amount) async {
    try {
      final currentCoins = await getCoins();
      await setCoins(currentCoins + amount);
      _instance._notifyDataUpdated();
    } catch (e) {}
  }

  static Future<bool> spendCoins(int amount) async {
    try {
      final currentCoins = await getCoins();
      if (currentCoins >= amount) {
        await setCoins(currentCoins - amount);
        _instance._notifyDataUpdated();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasEnoughCoins(int amount) async {
    final currentCoins = await getCoins();
    return currentCoins >= amount;
  }

  // ========== دوال التوافق مع الشاشات القديمة ==========

  static Future<int> getUserCoins() async => await getCoins();
  static Future<int> getTotalCoins() async => await getCoins();
  static Future<void> addCharacterCoins(int amount) async => await addCoins(amount);
  static Future<bool> spendCharacterCoins(int amount) async => await spendCoins(amount);

  // ========== نظام الشخصيات المحسن ==========

  static Future<List<GameCharacter>> getOwnedCharacters() async {
    final prefs = await _prefs;
    final ownedCharactersJson = prefs.getStringList(_ownedCharactersKey) ?? [];

    List<GameCharacter> ownedCharacters = [];

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
        continue;
      }
    }

    return ownedCharacters;
  }

  static GameCharacter? _characterFromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return GameCharacter.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveOwnedCharacters(List<GameCharacter> characters) async {
    final prefs = await _prefs;

    try {
      final ownedCharacters = characters.where((char) => !char.isLocked).toList();
      final charactersJson = ownedCharacters.map((character) {
        return json.encode(character.toJson());
      }).toList();

      await prefs.setStringList(_ownedCharactersKey, charactersJson);
      _instance._notifyDataUpdated();
    } catch (e) {}
  }

  static Future<bool> purchaseCharacter(GameCharacter character) async {
    try {
      final userCoins = await getCoins();

      // ✅ التصحيح: استخدام integerPrice للمقارنة
      if (userCoins < character.integerPrice) {
        return false;
      }

      final ownedCharacters = await getOwnedCharacters();

      if (ownedCharacters.any((c) => c.id == character.id)) {
        return false;
      }

      // ✅ تحديث المنشئ ليشمل جميع معلمات الهجوم
      final purchasedCharacter = GameCharacter(
        id: character.id,
        name: character.name,
        nameEn: character.nameEn,
        imagePath: character.imagePath,
        price: character.price, // ✅ يبقى double للتخزين
        isLocked: false,
        color: character.color,
        animations: List.from(character.animations),
        description: character.description,
        descriptionEn: character.descriptionEn,
        type: character.type,
        abilities: List.from(character.abilities),
        characterKey: character.characterKey,

        // ✅ إضافة جميع معلمات الهجوم
        attackName: character.attackName,
        attackNameEn: character.attackNameEn,
        attackDescription: character.attackDescription,
        attackDescriptionEn: character.attackDescriptionEn,
        attackType: character.attackType,
        attackDamage: character.attackDamage,
        attackSpeed: character.attackSpeed,
        attackCooldown: character.attackCooldown,
        attackEffects: List.from(character.attackEffects),
        attackSound: character.attackSound,
      );

      ownedCharacters.add(purchasedCharacter);
      await saveOwnedCharacters(ownedCharacters);

      // ✅ التصحيح: استخدام integerPrice للخصم
      await spendCoins(character.integerPrice);

      _instance._notifyDataUpdated();
      return true;

    } catch (e) {
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

      return selectedCharacter;
    } catch (e) {
      return GameCharacter.getDefaultCharacter();
    }
  }

  static Future<void> setSelectedCharacter(GameCharacter character) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(_selectedCharacterKey, character.id);
      _instance._notifyDataUpdated();
    } catch (e) {}
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

  static Future<List<GameCharacter>> getAllCharactersWithLockStatus() async {
    try {
      final allCharacters = GameCharacter.getAllCharacters();
      final ownedCharacters = await getOwnedCharacters();

      final updatedCharacters = allCharacters.map((character) {
        final isOwned = ownedCharacters.any((owned) => owned.id == character.id);

        // ✅ إضافة جميع معلمات الهجوم المطلوبة
        return GameCharacter(
          id: character.id,
          name: character.name,
          nameEn: character.nameEn,
          imagePath: character.imagePath,
          price: character.price, // ✅ يبقى double
          isLocked: !isOwned,
          color: character.color,
          animations: List.from(character.animations),
          description: character.description,
          descriptionEn: character.descriptionEn,
          type: character.type,
          abilities: List.from(character.abilities),
          characterKey: character.characterKey,

          // ✅ إضافة جميع معلمات الهجوم المطلوبة
          attackName: character.attackName,
          attackNameEn: character.attackNameEn,
          attackDescription: character.attackDescription,
          attackDescriptionEn: character.attackDescriptionEn,
          attackType: character.attackType,
          attackDamage: character.attackDamage,
          attackSpeed: character.attackSpeed,
          attackCooldown: character.attackCooldown,
          attackEffects: List.from(character.attackEffects),
          attackSound: character.attackSound,
        );
      }).toList();

      return updatedCharacters;
    } catch (e) {
      final defaultCharacter = GameCharacter.getDefaultCharacter();
      defaultCharacter.isLocked = false;
      return [defaultCharacter];
    }
  }

  // ========== دوال البيانات الأساسية ==========

  static Future<Map<String, dynamic>> getPlayerStats() async {
    return {
      'highScore': await getHighScore(),
      'currentLevel': await getCurrentLevel(),
      'coins': await getCoins(),
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

  static Future<void> incrementGamesPlayed() async {
    final currentGames = await getGamesPlayed();
    final prefs = await _prefs;
    await prefs.setInt(_gamesPlayedKey, currentGames + 1);
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

  static Future<void> saveGameProgress(int score, int level) async {
    await setHighScore(score);
    await setCurrentLevel(level);

    await incrementGamesPlayed();

    if (score >= getLevelTargetScore(level)) {
      await unlockLevel(level + 1);
    }
  }

  static int getLevelTargetScore(int level) {
    return level * 100;
  }

  // ========== نظام إزالة الإعلانات ==========
  static Future<Map<String, dynamic>> getAdsRemovalData() async {
    final prefs = await _prefs;
    return {
      'adsRemoved': prefs.getBool('ads_removal_purchased') ?? false,
      'temporaryRemoval': prefs.getBool('ads_temporary_removal') ?? false,
      'expiryDate': prefs.getInt('ads_removal_expiry'),
    };
  }

  static Future<void> setAdsRemovalData(bool adsRemoved, bool temporaryRemoval, DateTime? expiryDate) async {
    final prefs = await _prefs;

    await prefs.setBool('ads_removal_purchased', adsRemoved);
    await prefs.setBool('ads_temporary_removal', temporaryRemoval);

    if (expiryDate != null) {
      await prefs.setInt('ads_removal_expiry', expiryDate.millisecondsSinceEpoch);
    } else {
      await prefs.remove('ads_removal_expiry');
    }

    _instance._notifyDataUpdated();
  }

  static Future<bool> shouldShowAds() async {
    final adsData = await getAdsRemovalData();
    final adsRemoved = adsData['adsRemoved'] as bool;
    final temporaryRemoval = adsData['temporaryRemoval'] as bool;
    final expiryTimestamp = adsData['expiryDate'] as int?;

    if (temporaryRemoval && expiryTimestamp != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      if (expiryDate.isAfter(DateTime.now())) {
        return false;
      }
    }

    if (adsRemoved) {
      if (expiryTimestamp == null) return false;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      return expiryDate.isBefore(DateTime.now());
    }

    return true;
  }

  static Future<void> resetGameData() async {
    final prefs = await _prefs;

    await prefs.remove(_highScoreKey);
    await prefs.remove(_currentLevelKey);
    await prefs.remove(_unlockedLevelsKey);
    await prefs.remove(_gamesPlayedKey);
    await prefs.remove(_totalPlayTimeKey);
    await prefs.remove(_enemiesDefeatedKey);
    await prefs.remove(_bossesDefeatedKey);
    await prefs.remove(_packagesThrownKey);
    await prefs.remove(_ownedCharactersKey);
    await prefs.remove(_selectedCharacterKey);
    await prefs.remove(_coinsKey);

    await prefs.setString(_unlockedLevelsKey, '1');
    await prefs.setInt(_coinsKey, 1);

    final defaultCharacter = GameCharacter.getDefaultCharacter();
    await setSelectedCharacter(defaultCharacter);

    // ✅ تحديث المنشئ ليشمل جميع معلمات الهجوم
    final List<GameCharacter> initialOwnedCharacters = [
      GameCharacter(
        id: defaultCharacter.id,
        name: defaultCharacter.name,
        nameEn: defaultCharacter.nameEn,
        imagePath: defaultCharacter.imagePath,
        price: defaultCharacter.price,
        isLocked: false,
        color: defaultCharacter.color,
        animations: List.from(defaultCharacter.animations),
        description: defaultCharacter.description,
        descriptionEn: defaultCharacter.descriptionEn,
        type: defaultCharacter.type,
        abilities: List.from(defaultCharacter.abilities),
        characterKey: defaultCharacter.characterKey,

        // ✅ إضافة جميع معلمات الهجوم
        attackName: defaultCharacter.attackName,
        attackNameEn: defaultCharacter.attackNameEn,
        attackDescription: defaultCharacter.attackDescription,
        attackDescriptionEn: defaultCharacter.attackDescriptionEn,
        attackType: defaultCharacter.attackType,
        attackDamage: defaultCharacter.attackDamage,
        attackSpeed: defaultCharacter.attackSpeed,
        attackCooldown: defaultCharacter.attackCooldown,
        attackEffects: List.from(defaultCharacter.attackEffects),
        attackSound: defaultCharacter.attackSound,
      )
    ];

    await saveOwnedCharacters(initialOwnedCharacters);
    _instance._notifyDataUpdated();
  }
}