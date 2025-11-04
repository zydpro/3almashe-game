// lib/models/power_up_system.dart
import 'package:flutter/material.dart';
import 'enums.dart';
import '../services/image_service.dart';
import '../Languages/localization.dart';

class AdvancedPowerUp {
  final PowerUpType type;
  final String nameKey;
  final String descriptionKey;
  final String effectDescriptionKey;
  final String imagePath;
  final Color color;
  final Duration effectDuration;
  final int maxSpawnsPerLevel;
  final double spawnDifficulty;
  final double effectStrength;

  const AdvancedPowerUp({
    required this.type,
    required this.nameKey,
    required this.descriptionKey,
    required this.effectDescriptionKey,
    required this.imagePath,
    required this.color,
    required this.effectDuration,
    required this.maxSpawnsPerLevel,
    required this.spawnDifficulty,
    required this.effectStrength,
  });

  // دالة للحصول على الاسم المترجم
  String getName(AppLocalizations l10n) {
    switch (nameKey) {
      case 'powerUpHealth': return l10n.powerUpHealth;
      case 'powerUpSpeedBoost': return l10n.powerUpSpeedBoost;
      case 'powerUpSlowEnemies': return l10n.powerUpSlowEnemies;
      case 'powerUpCoin': return l10n.powerUpCoin;
      case 'powerUpPoints': return l10n.powerUpPoints;
      case 'powerUpShield': return l10n.powerUpShield;
      case 'powerUpSlowMotion': return l10n.powerUpSlowMotion;
      case 'powerUpDoublePoints': return l10n.powerUpDoublePoints;
      case 'powerUpSlowCharacter': return l10n.powerUpSlowCharacter;
      default: return l10n.powerUpPoints;
    }
  }

  // دالة للحصول على الوصف المترجم
  String getDescription(AppLocalizations l10n) {
    switch (descriptionKey) {
      case 'powerUpHealthDesc': return l10n.powerUpHealthDesc;
      case 'powerUpSpeedBoostDesc': return l10n.powerUpSpeedBoostDesc;
      case 'powerUpSlowEnemiesDesc': return l10n.powerUpSlowEnemiesDesc;
      case 'powerUpCoinDesc': return l10n.powerUpCoinDesc;
      case 'powerUpPointsDesc': return l10n.powerUpPointsDesc;
      case 'powerUpShieldDesc': return l10n.powerUpShieldDesc;
      case 'powerUpSlowMotionDesc': return l10n.powerUpSlowMotionDesc;
      case 'powerUpDoublePointsDesc': return l10n.powerUpDoublePointsDesc;
      case 'powerUpSlowCharacterDesc': return l10n.powerUpSlowCharacterDesc;
      default: return l10n.powerUpPointsDesc;
    }
  }

  // دالة للحصول على وصف التأثير المترجم
  String getEffectDescription(AppLocalizations l10n) {
    switch (effectDescriptionKey) {
      case 'powerUpHealthEffect': return l10n.powerUpHealthEffect;
      case 'powerUpSpeedBoostEffect': return l10n.powerUpSpeedBoostEffect;
      case 'powerUpSlowEnemiesEffect': return l10n.powerUpSlowEnemiesEffect;
      case 'powerUpCoinEffect': return l10n.powerUpCoinEffect;
      case 'powerUpPointsEffect': return l10n.powerUpPointsEffect;
      case 'powerUpShieldEffect': return l10n.powerUpShieldEffect;
      case 'powerUpSlowMotionEffect': return l10n.powerUpSlowMotionEffect;
      case 'powerUpDoublePointsEffect': return l10n.powerUpDoublePointsEffect;
      case 'powerUpSlowCharacterEffect': return l10n.powerUpSlowCharacterEffect;
      default: return l10n.powerUpPointsEffect;
    }
  }
}

class PowerUpSystem {
  static final Map<PowerUpType, AdvancedPowerUp> _powerUps = {
    PowerUpType.health: AdvancedPowerUp(
      type: PowerUpType.health,
      nameKey: 'powerUpHealth',
      descriptionKey: 'powerUpHealthDesc',
      effectDescriptionKey: 'powerUpHealthEffect',
      imagePath: ImageService.powerUpHealth,
      color: Colors.red,
      effectDuration: Duration.zero,
      maxSpawnsPerLevel: 20,
      spawnDifficulty: 0.15,
      effectStrength: 0.25,
    ),
    PowerUpType.speedBoost: AdvancedPowerUp(
      type: PowerUpType.speedBoost,
      nameKey: 'powerUpSpeedBoost',
      descriptionKey: 'powerUpSpeedBoostDesc',
      effectDescriptionKey: 'powerUpSpeedBoostEffect',
      imagePath: ImageService.powerUpSpeedBoost,
      color: Colors.yellow,
      effectDuration: const Duration(seconds: 4),
      maxSpawnsPerLevel: 15,
      spawnDifficulty: 0.20,
      effectStrength: 1.5,
    ),
    PowerUpType.slowEnemies: AdvancedPowerUp(
      type: PowerUpType.slowEnemies,
      nameKey: 'powerUpSlowEnemies',
      descriptionKey: 'powerUpSlowEnemiesDesc',
      effectDescriptionKey: 'powerUpSlowEnemiesEffect',
      imagePath: ImageService.powerUpSlowEnemies,
      color: Colors.blue,
      effectDuration: const Duration(seconds: 4),
      maxSpawnsPerLevel: 12,
      spawnDifficulty: 0.18,
      effectStrength: 0.4,
    ),
    PowerUpType.coin: AdvancedPowerUp(
      type: PowerUpType.coin,
      nameKey: 'powerUpCoin',
      descriptionKey: 'powerUpCoinDesc',
      effectDescriptionKey: 'powerUpCoinEffect',
      imagePath: ImageService.coin,
      color: Colors.amber,
      effectDuration: Duration.zero,
      maxSpawnsPerLevel: 25,
      spawnDifficulty: 0.25,
      effectStrength: 1.0,
    ),
    PowerUpType.points: AdvancedPowerUp(
      type: PowerUpType.points,
      nameKey: 'powerUpPoints',
      descriptionKey: 'powerUpPointsDesc',
      effectDescriptionKey: 'powerUpPointsEffect',
      imagePath: ImageService.powerUpPoints,
      color: Colors.amber,
      effectDuration: Duration.zero,
      maxSpawnsPerLevel: 18,
      spawnDifficulty: 0.22,
      effectStrength: 8.0,
    ),
    PowerUpType.shield: AdvancedPowerUp(
      type: PowerUpType.shield,
      nameKey: 'powerUpShield',
      descriptionKey: 'powerUpShieldDesc',
      effectDescriptionKey: 'powerUpShieldEffect',
      imagePath: ImageService.powerUpShield,
      color: Colors.blue.shade700,
      effectDuration: const Duration(seconds: 4),
      maxSpawnsPerLevel: 10,
      spawnDifficulty: 0.12,
      effectStrength: 1.0,
    ),
    PowerUpType.slowMotion: AdvancedPowerUp(
      type: PowerUpType.slowMotion,
      nameKey: 'powerUpSlowMotion',
      descriptionKey: 'powerUpSlowMotionDesc',
      effectDescriptionKey: 'powerUpSlowMotionEffect',
      imagePath: ImageService.powerUpSlowMotion,
      color: Colors.green,
      effectDuration: const Duration(seconds: 3),
      maxSpawnsPerLevel: 8,
      spawnDifficulty: 0.10,
      effectStrength: 0.3,
    ),
    PowerUpType.doublePoints: AdvancedPowerUp(
      type: PowerUpType.doublePoints,
      nameKey: 'powerUpDoublePoints',
      descriptionKey: 'powerUpDoublePointsDesc',
      effectDescriptionKey: 'powerUpDoublePointsEffect',
      imagePath: ImageService.powerUpDoublePoints,
      color: Colors.purple,
      effectDuration: const Duration(seconds: 6),
      maxSpawnsPerLevel: 6,
      spawnDifficulty: 0.08,
      effectStrength: 2.0,
    ),
    PowerUpType.slowCharacter: AdvancedPowerUp(
      type: PowerUpType.slowCharacter,
      nameKey: 'powerUpSlowCharacter',
      descriptionKey: 'powerUpSlowCharacterDesc',
      effectDescriptionKey: 'powerUpSlowCharacterEffect',
      imagePath: ImageService.powerUpSlowEnemies,
      color: Colors.purple.shade600,
      effectDuration: const Duration(seconds: 3),
      maxSpawnsPerLevel: 8,
      spawnDifficulty: 0.15,
      effectStrength: 0.6,
    ),
  };

  // === دوال الحصول على خصائص الباور أب ===

  static int getPowerUpPoints(PowerUpType type) {
    switch (type) {
      case PowerUpType.points: return 10;
      case PowerUpType.doublePoints: return 5;
      case PowerUpType.coin: return 2;
      case PowerUpType.health: return 4;
      case PowerUpType.shield: return 6;
      default: return 3;
    }
  }

  static Duration getPowerUpDuration(PowerUpType type) {
    switch (type) {
      case PowerUpType.speedBoost: return const Duration(seconds: 4);
      case PowerUpType.slowEnemies: return const Duration(seconds: 4);
      case PowerUpType.shield: return const Duration(seconds: 4);
      case PowerUpType.doublePoints: return const Duration(seconds: 6);
      case PowerUpType.slowMotion: return const Duration(seconds: 3);
      case PowerUpType.slowCharacter: return const Duration(seconds: 3);
      default: return Duration.zero;
    }
  }

  static double getPowerUpEffectStrength(PowerUpType type) {
    return getPowerUp(type).effectStrength;
  }

  static String getPowerUpEffectDescription(PowerUpType type, AppLocalizations l10n) {
    return getPowerUp(type).getEffectDescription(l10n);
  }

  static int getHealAmount(int maxHealth) {
    return (maxHealth * getPowerUpEffectStrength(PowerUpType.health)).toInt();
  }

  static double getSpeedBoostMultiplier() {
    return getPowerUpEffectStrength(PowerUpType.speedBoost);
  }

  static double getSlowEnemiesMultiplier() {
    return getPowerUpEffectStrength(PowerUpType.slowEnemies);
  }

  static double getSlowMotionMultiplier() {
    return getPowerUpEffectStrength(PowerUpType.slowMotion);
  }

  static double getSlowCharacterMultiplier() {
    return getPowerUpEffectStrength(PowerUpType.slowCharacter);
  }

  static int getDoublePointsMultiplier() {
    return getPowerUpEffectStrength(PowerUpType.doublePoints).toInt();
  }

  static int getMaxSpawnsForLevel(PowerUpType type, int level) {
    final baseSpawns = getPowerUp(type).maxSpawnsPerLevel;
    final levelBonus = (level / 10).floor();
    return baseSpawns + levelBonus.clamp(0, 5);
  }

  static double getSpawnDifficulty(PowerUpType type, int level) {
    final baseDifficulty = getPowerUp(type).spawnDifficulty;
    final levelReduction = (level * 0.001).clamp(0.0, 0.1);
    return (baseDifficulty - levelReduction).clamp(0.05, 1.0);
  }

  static AdvancedPowerUp getPowerUp(PowerUpType type) {
    return _powerUps[type] ?? _powerUps[PowerUpType.points]!;
  }

  static List<AdvancedPowerUp> getAllPowerUps() {
    return _powerUps.values.toList();
  }

  static List<AdvancedPowerUp> getTemporaryEffectPowerUps() {
    return _powerUps.values.where((powerUp) =>
    powerUp.effectDuration > Duration.zero
    ).toList();
  }

  static List<AdvancedPowerUp> getInstantEffectPowerUps() {
    return _powerUps.values.where((powerUp) =>
    powerUp.effectDuration == Duration.zero
    ).toList();
  }

  // === دوال التقييم والتوازن ===

  static double getPowerUpRarity(PowerUpType type) {
    final spawnDifficulty = getPowerUp(type).spawnDifficulty;
    return (1.0 - spawnDifficulty) * 10.0;
  }

  static String getPowerUpRarityName(PowerUpType type, AppLocalizations l10n) {
    final rarity = getPowerUpRarity(type);
    if (rarity >= 8.0) return l10n.powerUpRarityLegendary;
    if (rarity >= 6.0) return l10n.powerUpRarityRare;
    if (rarity >= 4.0) return l10n.powerUpRarityUncommon;
    return l10n.powerUpRarityCommon;
  }

  static Color getPowerUpRarityColor(PowerUpType type) {
    final rarity = getPowerUpRarity(type);
    if (rarity >= 8.0) return Colors.orange;
    if (rarity >= 6.0) return Colors.purple;
    if (rarity >= 4.0) return Colors.blue;
    return Colors.green;
  }

  // === نظام الإحصائيات ===

  static Map<PowerUpType, int> _powerUpStats = {};
  static Map<PowerUpType, int> _powerUpSpawns = {};
  static Map<PowerUpType, int> _powerUpEffectTime = {};

  static void initializeStats() {
    for (var type in PowerUpType.values) {
      _powerUpStats[type] = 0;
      _powerUpSpawns[type] = 0;
      _powerUpEffectTime[type] = 0;
    }
  }

  static void recordPowerUpSpawn(PowerUpType type) {
    _powerUpSpawns[type] = (_powerUpSpawns[type] ?? 0) + 1;
  }

  static void recordPowerUpCollection(PowerUpType type) {
    _powerUpStats[type] = (_powerUpStats[type] ?? 0) + 1;

    if (getPowerUpDuration(type) > Duration.zero) {
      final effectSeconds = getPowerUpDuration(type).inSeconds;
      _powerUpEffectTime[type] = (_powerUpEffectTime[type] ?? 0) + effectSeconds;
    }
  }

  static Map<PowerUpType, int> getPowerUpStats() {
    return Map.from(_powerUpStats);
  }

  static Map<PowerUpType, int> getPowerUpSpawns() {
    return Map.from(_powerUpSpawns);
  }

  static Map<PowerUpType, int> getPowerUpEffectTime() {
    return Map.from(_powerUpEffectTime);
  }

  static int getTotalPowerUpsCollected() {
    return _powerUpStats.values.fold(0, (sum, count) => sum + count);
  }

  static int getTotalEffectTime() {
    return _powerUpEffectTime.values.fold(0, (sum, time) => sum + time);
  }

  static void resetStats() {
    initializeStats();
  }

  // === دوال المساعدة للعرض ===

  static String formatDuration(Duration duration, AppLocalizations l10n) {
    if (duration == Duration.zero) return l10n.powerUpEffectInstant;
    return '${duration.inSeconds} ${l10n.powerUpSeconds}';
  }

  static String getPowerUpFullDescription(PowerUpType type, AppLocalizations l10n) {
    final powerUp = getPowerUp(type);
    final durationText = formatDuration(powerUp.effectDuration, l10n);

    if (powerUp.effectDuration > Duration.zero) {
      return '${powerUp.getDescription(l10n)} ($durationText)';
    }
    return powerUp.getDescription(l10n);
  }

  static Widget buildPowerUpInfoWidget(PowerUpType type, AppLocalizations l10n) {
    final powerUp = getPowerUp(type);
    final rarity = getPowerUpRarityName(type, l10n);
    final rarityColor = getPowerUpRarityColor(type);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: powerUp.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: powerUp.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                child: Image.asset(
                  powerUp.imagePath,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.star, color: powerUp.color);
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      powerUp.getName(l10n),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: powerUp.color,
                      ),
                    ),
                    Text(
                      '${l10n.powerUpRarity}: $rarity',
                      style: TextStyle(
                        fontSize: 12,
                        color: rarityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            getPowerUpFullDescription(type, l10n),
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 4),
          Text(
            '${l10n.powerUpEffect}: ${powerUp.getEffectDescription(l10n)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // === دوال للحصول على إحصائيات مترجمة ===

  static String getPowerUpStatsSummary(AppLocalizations l10n) {
    final totalCollected = getTotalPowerUpsCollected();
    final totalTime = getTotalEffectTime();

    return '${l10n.powerUpTotalCollected}: $totalCollected\n${l10n.powerUpTotalEffectTime}: ${totalTime} ${l10n.powerUpSeconds}';
  }

  static Map<String, String> getPowerUpDetailedStats(AppLocalizations l10n) {
    final stats = <String, String>{};

    for (var type in PowerUpType.values) {
      final collected = _powerUpStats[type] ?? 0;
      final spawns = _powerUpSpawns[type] ?? 0;
      final powerUp = getPowerUp(type);

      stats[powerUp.getName(l10n)] = '${l10n.powerUpCollected}: $collected, ${l10n.powerUpSpawned}: $spawns';
    }

    return stats;
  }
}