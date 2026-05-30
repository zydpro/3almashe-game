import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/online_character_system.dart';
import 'online_game_service.dart';

// ========== 1. نظام التطور المتقدم ==========
class AdvancedEvolutionSystem {
  int level = 1;
  int experience = 0;
  int experienceToNextLevel = 100;

  // عوامل الذكاء
  double intelligenceFactor = 1.0;    // سرعة التعلم
  double reactionFactor = 1.0;       // سرعة رد الفعل
  double predictionFactor = 1.0;     // دقة التنبؤ
  double aggressionFactor = 1.0;     // الميل للهجوم

  // القدرات المفتوحة
  Map<String, bool> unlockedAbilities = {
    'quick_dash': false,
    'counter_attack': false,
    'air_combo': false,
    'rage_mode': false,
    'ultimate_attack': false,
  };

  // أنماط اللاعب
  Map<String, Map<String, dynamic>> playerPatterns = {};
  Map<String, List<String>> playerWeaknesses = {};

  void updateExperience(int exp) {
    experience += exp;
    while (experience >= experienceToNextLevel) {
      _levelUp();
    }
  }

  void _levelUp() {
    experience -= experienceToNextLevel;
    level++;
    experienceToNextLevel = (experienceToNextLevel * 1.5).toInt();

    // تحسين العوامل
    intelligenceFactor += 0.1;
    reactionFactor += 0.08;
    predictionFactor += 0.07;
    aggressionFactor += 0.05;

    _unlockNewAbility();

    print('🆙 البوت ارتقى للمستوى $level');
    print('   🧠 عامل الذكاء: ${intelligenceFactor.toStringAsFixed(2)}');
    print('   ⚡ عامل رد الفعل: ${reactionFactor.toStringAsFixed(2)}');
  }

  void _unlockNewAbility() {
    final abilities = unlockedAbilities.keys.toList();
    for (final ability in abilities) {
      if (!unlockedAbilities[ability]!) {
        // فتح القدرة بناءً على المستوى
        switch (ability) {
          case 'quick_dash':
            if (level >= 2) {
              unlockedAbilities[ability] = true;
              print('✅ فتح قدرة: حركة سريعة');
            }
            break;
          case 'counter_attack':
            if (level >= 3) {
              unlockedAbilities[ability] = true;
              print('✅ فتح قدرة: هجوم مضاد');
            }
            break;
          case 'air_combo':
            if (level >= 4) {
              unlockedAbilities[ability] = true;
              print('✅ فتح قدرة: كومبو هوائي');
            }
            break;
          case 'rage_mode':
            if (level >= 5) {
              unlockedAbilities[ability] = true;
              print('✅ فتح قدرة: وضع الغضب');
            }
            break;
          case 'ultimate_attack':
            if (level >= 6) {
              unlockedAbilities[ability] = true;
              print('✅ فتح قدرة: الهجوم النهائي');
            }
            break;
        }
      }
    }
  }

  void learnPlayerPattern(String playerId, String action, String situation, bool successful) {
    final key = '$action-$situation';

    if (!playerPatterns.containsKey(playerId)) {
      playerPatterns[playerId] = {};
    }

    if (!playerPatterns[playerId]!.containsKey(key)) {
      playerPatterns[playerId]![key] = {
        'total': 0,
        'successful': 0,
        'recent': [],
      };
    }

    final pattern = playerPatterns[playerId]![key]! as Map<String, dynamic>;
    pattern['total'] = (pattern['total'] as int) + 1;
    if (successful) {
      pattern['successful'] = (pattern['successful'] as int) + 1;
    }

    // حفظ آخر 10 أفعال
    final recent = pattern['recent'] as List<bool>;
    recent.add(successful);
    if (recent.length > 10) {
      recent.removeAt(0);
    }

    // اكتشاف نقاط الضعف
    _detectPlayerWeaknesses(playerId);
  }

  void _detectPlayerWeaknesses(String playerId) {
    if (!playerPatterns.containsKey(playerId)) return;

    final weaknesses = <String>[];
    final patterns = playerPatterns[playerId]!;

    for (final entry in patterns.entries) {
      final pattern = entry.value as Map<String, dynamic>;
      final successRate = (pattern['successful'] as int) / (pattern['total'] as int);

      if (successRate < 0.3) { // إذا كان معدل النجاح أقل من 30%
        weaknesses.add(entry.key);
      }
    }

    playerWeaknesses[playerId] = weaknesses;
  }

  List<String> getPlayerWeaknesses(String playerId) {
    return playerWeaknesses[playerId] ?? [];
  }

  double getSuccessProbability(String playerId, String action, String situation) {
    final key = '$action-$situation';
    if (!playerPatterns.containsKey(playerId) || !playerPatterns[playerId]!.containsKey(key)) {
      return 0.5; // احتمال افتراضي
    }

    final pattern = playerPatterns[playerId]![key]! as Map<String, dynamic>;
    final total = pattern['total'] as int;
    final successful = pattern['successful'] as int;

    return total > 0 ? successful / total : 0.5;
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'experience': experience,
      'experienceToNextLevel': experienceToNextLevel,
      'intelligenceFactor': intelligenceFactor,
      'reactionFactor': reactionFactor,
      'predictionFactor': predictionFactor,
      'aggressionFactor': aggressionFactor,
      'unlockedAbilities': unlockedAbilities,
      'playerPatterns': playerPatterns,
      'playerWeaknesses': playerWeaknesses,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    level = json['level'] ?? 1;
    experience = json['experience'] ?? 0;
    experienceToNextLevel = json['experienceToNextLevel'] ?? 100;
    intelligenceFactor = (json['intelligenceFactor'] as num?)?.toDouble() ?? 1.0;
    reactionFactor = (json['reactionFactor'] as num?)?.toDouble() ?? 1.0;
    predictionFactor = (json['predictionFactor'] as num?)?.toDouble() ?? 1.0;
    aggressionFactor = (json['aggressionFactor'] as num?)?.toDouble() ?? 1.0;

    if (json['unlockedAbilities'] != null) {
      final abilities = json['unlockedAbilities'] as Map<String, dynamic>;
      unlockedAbilities = abilities.map((key, value) =>
          MapEntry(key, value == true));
    }

    if (json['playerPatterns'] != null) {
      final patterns = json['playerPatterns'] as Map<String, dynamic>;
      playerPatterns = {};
      patterns.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          playerPatterns[key] = value;
        }
      });
    }

    if (json['playerWeaknesses'] != null) {
      final weaknesses = json['playerWeaknesses'] as Map<String, dynamic>;
      playerWeaknesses = {};
      weaknesses.forEach((key, value) {
        if (value is List) {
          playerWeaknesses[key] = List<String>.from(value.cast<String>());
        }
      });
    }
  }
}

// ========== 2. نظام الأسلحة المتقدم ==========
class AdvancedWeaponSystem {
  // إحصائيات استخدام الأسلحة
  Map<OnlineWeaponType, Map<String, dynamic>> weaponStats = {};

  // نظام التبريد
  Map<String, int> weaponCooldowns = {};
  Timer? _cooldownTimer;

  // فعالية الأسلحة حسب المسافة
  Map<OnlineWeaponType, Map<String, double>> distanceEffectiveness = {};

  AdvancedWeaponSystem() {
    _initializeWeaponStats();
    _startCooldownSystem();
  }

  void _initializeWeaponStats() {
    // تهيئة إحصائيات جميع الأسلحة
    for (final weaponType in OnlineWeaponType.values) {
      weaponStats[weaponType] = {
        'uses': 0,
        'hits': 0,
        'misses': 0,
        'totalDamage': 0,
        'averageDamage': 0.0,
        'successRate': 0.0,
        'lastUsed': 0,
      };

      distanceEffectiveness[weaponType] = {
        'close': 0.0,
        'medium': 0.0,
        'far': 0.0,
      };
    }
  }

  void _startCooldownSystem() {
    _cooldownTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      weaponCooldowns.forEach((weaponId, cooldown) {
        if (cooldown > 0) {
          weaponCooldowns[weaponId] = cooldown - 1;
        }
      });
    });
  }

  OnlineWeaponType? selectOptimalWeapon(
      double distance,
      OnlinePlayer bot,
      OnlinePlayer enemy,
      List<OnlineWeapon> availableWeapons
      ) {
    if (availableWeapons.isEmpty) return null;

    // تحليل الوضع الحالي
    final botHealth = bot.health;
    final enemyHealth = enemy.health;
    final isBotLowHealth = botHealth < 30;
    final isEnemyLowHealth = enemyHealth < 30;

    // تصنيف المسافة
    String distanceCategory;
    if (distance < 0.08) {
      distanceCategory = 'very_close';
    } else if (distance < 0.15) {
      distanceCategory = 'close';
    } else if (distance < 0.25) {
      distanceCategory = 'medium';
    } else {
      distanceCategory = 'far';
    }

    // حساب نقاط كل سلاح
    final weaponScores = <OnlineWeaponType, double>{};

    for (final weapon in availableWeapons) {
      double score = 0.0;

      // 1. فعالية المسافة
      final distanceScore = _getDistanceScore(weapon.type, distanceCategory);
      score += distanceScore * 40;

      // 2. إحصائيات النجاح
      final stats = weaponStats[weapon.type]!;
      final successRate = stats['successRate'] as double;
      score += successRate * 30;

      // 3. ضرر السلاح
      final damageScore = weapon.damage / 50.0;
      score += damageScore * 20;

      // 4. سرعة السلاح
      final speedScore = weapon.speed / 2.0;
      score += speedScore * 10;

      // 5. تبريد السلاح
      final cooldownKey = '${weapon.type}_${bot.playerId}';
      final isOnCooldown = weaponCooldowns[cooldownKey] != null &&
          weaponCooldowns[cooldownKey]! > 0;
      if (isOnCooldown) {
        score *= 0.5; // تقليل النقاط إذا كان السلاح تحت التبريد
      }

      // 6. اعتبارات الصحة
      if (isBotLowHealth && distanceCategory == 'far') {
        // إذا كان البوت منخفض الصحة وبعيد، يفضل الأسلحة بعيدة المدى
        final rangeScore = weapon.range / 0.3;
        score += rangeScore * 15;
      }

      if (isEnemyLowHealth && distanceCategory == 'close') {
        // إذا كان العدو منخفض الصحة وقريب، يفضل الأسلحة القوية
        score += (weapon.damage / 50.0) * 20;
      }

      weaponScores[weapon.type] = score;
    }

    // اختيار السلاح بأعلى نقاط
    if (weaponScores.isNotEmpty) {
      final bestWeaponType = weaponScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      print('🎯 اختيار السلاح الأمثل: ${OnlineWeaponLibrary.weapons[bestWeaponType]?.name}');
      print('   📏 المسافة: ${distance.toStringAsFixed(3)} ($distanceCategory)');
      print('   💯 النقاط: ${weaponScores[bestWeaponType]!.toStringAsFixed(2)}');

      // وضع السلاح تحت التبريد
      final cooldownKey = '${bestWeaponType}_${bot.playerId}';
      weaponCooldowns[cooldownKey] = 60; // 1 ثانية (60 إطار)

      return bestWeaponType;
    }

    return null;
  }

  double _getDistanceScore(OnlineWeaponType weaponType, String distanceCategory) {
    final effectiveness = distanceEffectiveness[weaponType]!;

    switch (distanceCategory) {
      case 'very_close':
        return effectiveness['close'] ?? 0.0;
      case 'close':
        return effectiveness['close'] ?? 0.0;
      case 'medium':
        return effectiveness['medium'] ?? 0.0;
      case 'far':
        return effectiveness['far'] ?? 0.0;
      default:
        return 0.5;
    }
  }

  void recordWeaponSuccess(
      OnlineWeaponType weaponType,
      bool wasHit,
      int damageDealt,
      double distance
      ) {
    final stats = weaponStats[weaponType]!;

    stats['uses'] = (stats['uses'] as int) + 1;

    if (wasHit) {
      stats['hits'] = (stats['hits'] as int) + 1;
      stats['totalDamage'] = (stats['totalDamage'] as int) + damageDealt;
      stats['averageDamage'] = (stats['totalDamage'] as int) / (stats['hits'] as int);
    } else {
      stats['misses'] = (stats['misses'] as int) + 1;
    }

    stats['successRate'] = (stats['hits'] as int) / (stats['uses'] as int);
    stats['lastUsed'] = DateTime.now().millisecondsSinceEpoch;

    // تحديث فعالية المسافة
    final distanceCat = _categorizeDistance(distance);
    _updateDistanceEffectiveness(weaponType, distanceCat, wasHit);

    print('📊 تحديث إحصائيات السلاح: ${OnlineWeaponLibrary.weapons[weaponType]?.name}');
    print('   🎯 معدل النجاح: ${(stats['successRate'] as double).toStringAsFixed(2)}');
    print('   💥 متوسط الضرر: ${stats['averageDamage'].toStringAsFixed(1)}');
  }

  String _categorizeDistance(double distance) {
    if (distance < 0.15) return 'close';
    if (distance < 0.25) return 'medium';
    return 'far';
  }

  void _updateDistanceEffectiveness(
      OnlineWeaponType weaponType,
      String distanceCategory,
      bool wasHit
      ) {
    final effectiveness = distanceEffectiveness[weaponType]!;
    final currentScore = effectiveness[distanceCategory] ?? 0.5;

    // تحديث النتيجة بناءً على النجاح/الفشل
    final newScore = wasHit
        ? currentScore + 0.05  // زيادة إذا نجح
        : currentScore - 0.03; // نقصان إذا فشل

    effectiveness[distanceCategory] = newScore.clamp(0.0, 1.0);
  }

  void _analyzeWeaponEffectiveness() {
    print('📈 === تحليل فعالية الأسلحة ===');

    for (final entry in weaponStats.entries) {
      final weaponType = entry.key;
      final stats = entry.value;
      final weapon = OnlineWeaponLibrary.weapons[weaponType];

      if (weapon != null && (stats['uses'] as int) > 0) {
        print('${weapon.name}:');
        print('   استخدامات: ${stats['uses']}');
        print('   نجاحات: ${stats['hits']}');
        print('   معدل النجاح: ${((stats['successRate'] as double) * 100).toStringAsFixed(1)}%');
        print('   متوسط الضرر: ${stats['averageDamage'].toStringAsFixed(1)}');

        final distanceEff = distanceEffectiveness[weaponType]!;
        print('   فعالية المسافات:');
        print('     قريب: ${(distanceEff['close']! * 100).toStringAsFixed(1)}%');
        print('     متوسط: ${(distanceEff['medium']! * 100).toStringAsFixed(1)}%');
        print('     بعيد: ${(distanceEff['far']! * 100).toStringAsFixed(1)}%');
      }
    }

    print('=============================');
  }

  void dispose() {
    _cooldownTimer?.cancel();
  }
}

// ========== 3. وحدة التحكم الذكية ==========
class AdvancedAIController {
  final OnlinePlayer botPlayer;
  final OnlinePlayer humanPlayer;
  final AdvancedEvolutionSystem evolutionSystem;
  final AdvancedWeaponSystem weaponSystem;

  // إعدادات السلوك
  String behavior = 'balanced'; // balanced, aggressive, defensive, tactical
  int difficulty = 3; // 1-5

  // الذاكرة
  List<Map<String, dynamic>> shortTermMemory = []; // آخر 10 أفعال
  Map<String, List<Map<String, dynamic>>> longTermMemory = {}; // سجل كامل
  Map<String, List<String>> patternMemory = {}; // أنماط الحركة

  // التنبؤ
  List<Offset> playerTrajectory = [];
  Offset? predictedPosition;
  Timer? _predictionTimer;

  // التكيف
  Map<String, double> adaptationFactors = {
    'aggression': 0.5,
    'defense': 0.5,
    'mobility': 0.5,
    'accuracy': 0.5,
  };

  AdvancedAIController({
    required this.botPlayer,
    required this.humanPlayer,
    required this.evolutionSystem,
    required this.weaponSystem,
    this.behavior = 'balanced',
    this.difficulty = 3,
  }) {
    _startPredictionSystem();
    _initializeAdaptation();
  }

  void _startPredictionSystem() {
    _predictionTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      _updatePlayerTrajectory();
      _predictNextMove();
    });
  }

  void _initializeAdaptation() {
    // تعديل عوامل التكيف بناءً على الصعوبة
    final difficultyFactor = difficulty / 5.0;

    adaptationFactors['aggression'] = 0.3 + (difficultyFactor * 0.4);
    adaptationFactors['defense'] = 0.4 + (difficultyFactor * 0.3);
    adaptationFactors['mobility'] = 0.5 + (difficultyFactor * 0.3);
    adaptationFactors['accuracy'] = 0.4 + (difficultyFactor * 0.4);

    // تعديل إضافي بناءً على السلوك
    switch (behavior) {
      case 'aggressive':
        adaptationFactors['aggression'] = 0.8;
        adaptationFactors['defense'] = 0.2;
        break;
      case 'defensive':
        adaptationFactors['aggression'] = 0.2;
        adaptationFactors['defense'] = 0.8;
        break;
      case 'tactical':
        adaptationFactors['accuracy'] = 0.7;
        adaptationFactors['mobility'] = 0.6;
        break;
    }
  }

  void _updatePlayerTrajectory() {
    // تسجيل مسار اللاعب
    playerTrajectory.add(Offset(humanPlayer.x, humanPlayer.y));

    // الحفاظ على آخر 20 موقع
    if (playerTrajectory.length > 20) {
      playerTrajectory.removeAt(0);
    }

    // تحليل نمط الحركة
    if (playerTrajectory.length >= 5) {
      _analyzeMovementPattern();
    }
  }

  void _analyzeMovementPattern() {
    final lastPositions = playerTrajectory.sublist(playerTrajectory.length - 5);

    // حساب متوسط السرعة والاتجاه
    double totalXMovement = 0;
    double totalYMovement = 0;

    for (int i = 1; i < lastPositions.length; i++) {
      totalXMovement += lastPositions[i].dx - lastPositions[i-1].dx;
      totalYMovement += lastPositions[i].dy - lastPositions[i-1].dy;
    }

    final avgXMovement = totalXMovement / 4;
    final avgYMovement = totalYMovement / 4;

    // تصنيف نمط الحركة
    String pattern = 'stationary';

    if (avgXMovement.abs() > 0.02) {
      pattern = avgXMovement > 0 ? 'moving_right' : 'moving_left';
    }

    if (avgYMovement.abs() > 0.015) {
      if (avgYMovement < 0) {
        pattern = 'jumping';
      } else {
        pattern = 'falling';
      }
    }

    // تخزين النمط في الذاكرة
    if (!patternMemory.containsKey(humanPlayer.playerId)) {
      patternMemory[humanPlayer.playerId] = [];
    }

    patternMemory[humanPlayer.playerId]!.add(pattern);
    if (patternMemory[humanPlayer.playerId]!.length > 50) {
      patternMemory[humanPlayer.playerId]!.removeAt(0);
    }

    print('🎯 نمط حركة اللاعب: $pattern');
    print('   📍 السرعة: (${avgXMovement.toStringAsFixed(4)}, ${avgYMovement.toStringAsFixed(4)})');
  }

  void _predictNextMove() {
    if (playerTrajectory.length < 3) return;

    final lastPositions = playerTrajectory.sublist(playerTrajectory.length - 3);

    // التنبؤ الخطي البسيط
    final dx = lastPositions[2].dx - lastPositions[0].dx;
    final dy = lastPositions[2].dy - lastPositions[0].dy;

    // تطبيق عامل التنبؤ من نظام التطور
    final predictionFactor = evolutionSystem.predictionFactor;

    predictedPosition = Offset(
      humanPlayer.x + (dx * predictionFactor * 1.2),
      humanPlayer.y + (dy * predictionFactor * 1.2),
    );

    // تسجيل في الذاكرة قصيرة المدى
    shortTermMemory.add({
      'type': 'prediction',
      'position': predictedPosition,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'actual_position': Offset(humanPlayer.x, humanPlayer.y),
    });

    if (shortTermMemory.length > 10) {
      shortTermMemory.removeAt(0);
    }
  }

  Map<String, dynamic> _makeStrategicDecision() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final distance = _calculateDistance();
    final botHealth = botPlayer.health;
    final enemyHealth = humanPlayer.health;

    // تقييم الوضع
    final situation = _evaluateSituation(distance, botHealth, enemyHealth);

    // اتخاذ القرار بناءً على الوضع
    Map<String, dynamic> decision;

    switch (situation['priority']) {
      case 'attack':
        decision = _makeAttackDecision(distance, situation);
        break;
      case 'defend':
        decision = _makeDefenseDecision(distance, situation);
        break;
      case 'reposition':
        decision = _makeRepositionDecision(distance, situation);
        break;
      case 'evade':
        decision = _makeEvasionDecision(distance, situation);
        break;
      default:
        decision = {
          'action': 'idle',
          'target_position': Offset(botPlayer.x, botPlayer.y),
          'weapon': null,
          'attack_type': null,
        };
    }

    // إضافة معلومات إضافية
    decision['timestamp'] = currentTime;
    decision['situation'] = situation;
    decision['distance'] = distance;
    decision['predicted_position'] = predictedPosition;

    return decision;
  }

  Map<String, dynamic> _evaluateSituation(double distance, double botHealth, double enemyHealth) {
    // حساب نقاط الوضع مع القيم الافتراضية
    Map<String, double> scores = {
      'attack': 0.0,
      'defend': 0.0,
      'reposition': 0.0,
      'evade': 0.0,
    };

    // 1. عامل الصحة
    final healthRatio = enemyHealth > 0 ? botHealth / enemyHealth : 1.0;
    if (healthRatio > 1.5) {
      scores['attack'] = scores['attack']! + 40;  // ⭐ استخدم ! هنا
    } else if (healthRatio < 0.7) {
      scores['defend'] = scores['defend']! + 30;  // ⭐ استخدم ! هنا
      scores['evade'] = scores['evade']! + 20;    // ⭐ استخدم ! هنا
    }

    // 2. عامل المسافة
    if (distance < 0.08) {
      scores['attack'] = scores['attack']! + 30;  // ⭐ استخدم ! هنا
      scores['evade'] = scores['evade']! + 10;    // ⭐ استخدم ! هنا
    } else if (distance < 0.15) {
      scores['attack'] = scores['attack']! + 20;  // ⭐ استخدم ! هنا
      scores['reposition'] = scores['reposition']! + 15;  // ⭐ استخدم ! هنا
    } else if (distance < 0.25) {
      scores['reposition'] = scores['reposition']! + 25;  // ⭐ استخدم ! هنا
      scores['attack'] = scores['attack']! + 10;  // ⭐ استخدم ! هنا
    } else {
      scores['reposition'] = scores['reposition']! + 30;  // ⭐ استخدم ! هنا
    }

    // 3. عامل العدوانية
    final aggression = (adaptationFactors['aggression'] ?? 0.5) * evolutionSystem.aggressionFactor;
    scores['attack'] = scores['attack']! + (aggression * 20);  // ⭐ استخدم ! هنا

    // 4. عامل الدفاع
    final defense = adaptationFactors['defense'] ?? 0.5;
    scores['defend'] = scores['defend']! + (defense * 15);  // ⭐ استخدم ! هنا

    // 5. اعتبارات الأسلحة
    if (botPlayer.weapons.isNotEmpty) {
      final weapon = botPlayer.currentWeapon;
      if (weapon != null) {
        final optimalDistance = _getOptimalWeaponDistance(weapon.type);
        final distanceDiff = (distance - optimalDistance).abs();

        if (distanceDiff < 0.05) {
          scores['attack'] = scores['attack']! + 25;  // ⭐ استخدم ! هنا
        } else {
          scores['reposition'] = scores['reposition']! + 20;  // ⭐ استخدم ! هنا
        }
      }
    }

    // 6. نمط اللاعب
    final patterns = patternMemory[humanPlayer.playerId] ?? [];
    if (patterns.isNotEmpty) {
      final lastPattern = patterns.last;
      if (lastPattern == 'jumping') {
        scores['attack'] = scores['attack']! + 15;  // ⭐ استخدم ! هنا
      } else if (lastPattern.contains('moving')) {
        scores['attack'] = scores['attack']! + 10;  // ⭐ استخدم ! هنا
      }
    }

    // تحديد الأولوية
    String priority = 'reposition';
    double highestScore = 0.0;

    for (final entry in scores.entries) {
      if (entry.value > highestScore) {
        highestScore = entry.value;
        priority = entry.key;
      }
    }

    return {
      'priority': priority,
      'scores': scores,
      'health_ratio': healthRatio,
      'distance_category': _categorizeDistance(distance),
    };
  }

  Map<String, dynamic> _makeAttackDecision(double distance, Map<String, dynamic> situation) {
    final availableWeapons = botPlayer.weapons;
    OnlineWeaponType? weaponType;
    OnlineAttackType attackType = OnlineAttackType.light;

    if (availableWeapons.isNotEmpty) {
      // اختيار السلاح الأمثل
      weaponType = weaponSystem.selectOptimalWeapon(
          distance,
          botPlayer,
          humanPlayer,
          availableWeapons
      );

      // اختيار نوع الهجوم
      if (distance < 0.08 && evolutionSystem.unlockedAbilities['air_combo'] == true) {
        attackType = OnlineAttackType.aerial;
      } else if (distance < 0.12 && Random().nextDouble() < 0.3) {
        attackType = OnlineAttackType.heavy;
      } else if (evolutionSystem.unlockedAbilities['ultimate_attack'] == true &&
          botPlayer.health < 50 &&
          Random().nextDouble() < 0.1) {
        attackType = OnlineAttackType.signature;
      }
    }

    // تحديد موقع الهدف
    Offset targetPosition;
    if (predictedPosition != null && distance > 0.1) {
      // إطلاق نار مسبق نحو الموقع المتوقع
      targetPosition = predictedPosition!;
    } else {
      // التصويب مباشرة على اللاعب
      targetPosition = Offset(humanPlayer.x, humanPlayer.y);
    }

    return {
      'action': 'attack',
      'target_position': targetPosition,
      'weapon': weaponType,
      'attack_type': attackType,
      'is_predicted_shot': predictedPosition != null && distance > 0.1,
    };
  }

  Map<String, dynamic> _makeDefenseDecision(double distance, Map<String, dynamic> situation) {
    // البحث عن موقع دفاعي آمن
    final safePosition = _findSafePosition();

    return {
      'action': 'move_to',
      'target_position': safePosition,
      'weapon': null,
      'attack_type': null,
      'is_defensive': true,
    };
  }

  Map<String, dynamic> _makeRepositionDecision(double distance, Map<String, dynamic> situation) {
    // العثور على موقع استراتيجي أفضل
    final strategicPosition = _findStrategicPosition();

    return {
      'action': 'move_to',
      'target_position': strategicPosition,
      'weapon': null,
      'attack_type': null,
      'is_strategic': true,
    };
  }

  Map<String, dynamic> _makeEvasionDecision(double distance, Map<String, dynamic> situation) {
    // تنفيذ حركة تجنب
    final evasionPosition = _calculateEvasionPosition();

    // التحقق مما إذا كان هناك سلاح متاح للهجوم أثناء التحرك
    OnlineWeaponType? weaponType;
    if (botPlayer.weapons.isNotEmpty && Random().nextDouble() < 0.4) {
      weaponType = weaponSystem.selectOptimalWeapon(
          distance,
          botPlayer,
          humanPlayer,
          botPlayer.weapons
      );
    }

    return {
      'action': 'evade',
      'target_position': evasionPosition,
      'weapon': weaponType,
      'attack_type': OnlineAttackType.light,
      'is_evasive': true,
    };
  }

  Offset _findSafePosition() {
    // البحث عن موقع آمن بعيد عن اللاعب
    final random = Random();
    final currentX = botPlayer.x;
    final currentY = botPlayer.y;

    double targetX, targetY;

    // اختيار موقع عشوائي آمن
    final safePositions = [
      Offset(0.2, 0.7),  // يسار
      Offset(0.8, 0.7),  // يمين
      Offset(0.5, 0.9),  // أعلى
      Offset(0.5, 0.5),  // وسط
    ];

    // اختيار أبعد موقع عن اللاعب
    Offset farthestPosition = safePositions[0];
    double maxDistance = 0;

    for (final position in safePositions) {
      final distance = _calculateDistanceBetween(
          position.dx, position.dy,
          humanPlayer.x, humanPlayer.y
      );

      if (distance > maxDistance) {
        maxDistance = distance;
        farthestPosition = position;
      }
    }

    // إضافة بعض العشوائية
    targetX = farthestPosition.dx + (random.nextDouble() * 0.2 - 0.1);
    targetY = farthestPosition.dy + (random.nextDouble() * 0.1 - 0.05);

    return Offset(targetX.clamp(0.1, 0.9), targetY.clamp(0.3, 0.9));
  }

  Offset _findStrategicPosition() {
    // العثور على موقع استراتيجي للهجوم
    final random = Random();
    final enemyX = humanPlayer.x;
    final enemyY = humanPlayer.y;

    double targetX, targetY;

    // إذا كان لدينا سلاح، نحاول الوصول للمدى المثالي
    if (botPlayer.weapons.isNotEmpty) {
      final weapon = botPlayer.currentWeapon;
      if (weapon != null) {
        final optimalDistance = _getOptimalWeaponDistance(weapon.type);

        // وضع أنفسنا في المسافة المثالية من العدو
        final angle = random.nextDouble() * 2 * pi;
        targetX = enemyX + cos(angle) * optimalDistance;
        targetY = enemyY + sin(angle) * optimalDistance;
      } else {
        // موقع افتراضي
        targetX = enemyX + (random.nextDouble() * 0.3 - 0.15);
        targetY = enemyY + (random.nextDouble() * 0.2 - 0.1);
      }
    } else {
      // بدون سلاح، الاقتراب للملاكمة
      targetX = enemyX + (random.nextDouble() * 0.1 - 0.05);
      targetY = enemyY + (random.nextDouble() * 0.05 - 0.025);
    }

    return Offset(
        targetX.clamp(0.1, 0.9),
        targetY.clamp(0.3, 0.9)
    );
  }

  Offset _calculateEvasionPosition() {
    // حساب موقع للتجنب بناءً على حركة اللاعب
    final random = Random();
    final enemyX = humanPlayer.x;
    final enemyY = humanPlayer.y;
    final currentX = botPlayer.x;
    final currentY = botPlayer.y;

    // اتجاه التحرك بعيداً عن اللاعب
    double dx = currentX - enemyX;
    double dy = currentY - enemyY;

    // تطبيع المتجه
    final distance = sqrt(dx * dx + dy * dy);
    if (distance > 0) {
      dx /= distance;
      dy /= distance;
    }

    // إضافة عشوائية للحركة
    dx += (random.nextDouble() * 0.4 - 0.2);
    dy += (random.nextDouble() * 0.3 - 0.15);

    // تطبيع مرة أخرى
    final newDistance = sqrt(dx * dx + dy * dy);
    if (newDistance > 0) {
      dx /= newDistance;
      dy /= newDistance;
    }

    // حساب الموقع النهائي
    final evasionDistance = 0.15 + random.nextDouble() * 0.1;
    double targetX = currentX + dx * evasionDistance;
    double targetY = currentY + dy * evasionDistance;

    // إذا كانت القدرة متاحة، تنفيذ حركة سريعة
    if (evolutionSystem.unlockedAbilities['quick_dash'] == true) {
      targetX = currentX + dx * (evasionDistance * 1.5);
      targetY = currentY + dy * (evasionDistance * 1.5);
    }

    return Offset(
        targetX.clamp(0.1, 0.9),
        targetY.clamp(0.3, 0.9)
    );
  }

  double _getOptimalWeaponDistance(OnlineWeaponType weaponType) {
    switch (weaponType) {
      case OnlineWeaponType.sword:
      case OnlineWeaponType.katars:
      case OnlineWeaponType.gauntlets:
      case OnlineWeaponType.dagger:
        return 0.08; // أسلحة قريبة المدى
      case OnlineWeaponType.spear:
      case OnlineWeaponType.staff:
      case OnlineWeaponType.axe:
        return 0.12; // أسلحة متوسطة المدى
      case OnlineWeaponType.hammer:
        return 0.1;  // مطرقة (مدى متوسط-قريب)
      case OnlineWeaponType.bow:
      case OnlineWeaponType.blasters:
        return 0.18; // أسلحة بعيدة المدى
      case OnlineWeaponType.orb:
        return 0.14; // كرة (مدى متوسط)
      default:
        return 0.1;
    }
  }

  String _categorizeDistance(double distance) {
    if (distance < 0.08) return 'very_close';
    if (distance < 0.15) return 'close';
    if (distance < 0.25) return 'medium';
    return 'far';
  }

  double _calculateDistance() {
    return sqrt(
        pow(botPlayer.x - humanPlayer.x, 2) +
            pow(botPlayer.y - humanPlayer.y, 2)
    );
  }

  double _calculateDistanceBetween(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
  }

  void executeDecision(Map<String, dynamic> decision) {
    final action = decision['action'] as String;

    switch (action) {
      case 'attack':
        _executeAttack(decision);
        break;
      case 'move_to':
        _executeMovement(decision);
        break;
      case 'evade':
        _executeEvasion(decision);
        break;
      case 'idle':
        _executeIdle();
        break;
    }

    // تسجيل القرار في الذاكرة
    _recordDecision(decision);
  }

  void _executeAttack(Map<String, dynamic> decision) {
    final weaponType = decision['weapon'] as OnlineWeaponType?;
    final attackType = decision['attack_type'] as OnlineAttackType;
    final targetPosition = decision['target_position'] as Offset;
    final isPredictedShot = decision['is_predicted_shot'] as bool? ?? false;

    // توجيه البوت نحو الهدف
    botPlayer.isFacingRight = targetPosition.dx > botPlayer.x;

    if (weaponType != null && botPlayer.weapons.isNotEmpty) {
      // التبديل للسلاح المختار إن لزم
      final currentWeapon = botPlayer.currentWeapon;
      if (currentWeapon?.type != weaponType) {
        final weaponIndex = botPlayer.weapons.indexWhere((w) => w.type == weaponType);
        if (weaponIndex != -1) {
          botPlayer.currentWeaponIndex = weaponIndex;
        }
      }

      // تنفيذ الهجوم
      botPlayer.performAttack(attackType);

      print('⚔️ البوت يهاجم باستخدام: ${OnlineWeaponLibrary.weapons[weaponType]?.name}');
      print('   🎯 نوع الهجوم: $attackType');
      if (isPredictedShot) {
        print('   🔮 إطلاق نار مسبق نحو الموقع المتوقع');
      }
    } else {
      // هجوم ملاكمة
      botPlayer.performPunch();
      print('👊 البوت يهاجم بالملاكمة');
    }
  }

  void _executeMovement(Map<String, dynamic> decision) {
    final targetPosition = decision['target_position'] as Offset;
    final isDefensive = decision['is_defensive'] as bool? ?? false;
    final isStrategic = decision['is_strategic'] as bool? ?? false;

    // حساب اتجاه الحركة
    final dx = targetPosition.dx - botPlayer.x;
    final dy = targetPosition.dy - botPlayer.y;

    // تحديد سرعة الحركة بناءً على نوع الحركة
    double moveSpeed = 0.03;

    if (isDefensive && evolutionSystem.unlockedAbilities['quick_dash'] == true) {
      moveSpeed = 0.045; // حركة دفاعية سريعة
    } else if (isStrategic) {
      moveSpeed = 0.035; // حركة استراتيجية متوسطة السرعة
    }

    // تطبيق الحركة
    botPlayer.velocityX = dx.sign * moveSpeed;
    botPlayer.isFacingRight = dx > 0;

    // إذا كان الهدف أعلى، محاولة القفز
    if (dy < -0.05 && botPlayer.isGrounded) {
      botPlayer.velocityY = -0.035;
    }

    print('🏃 البوت يتحرك نحو: (${targetPosition.dx.toStringAsFixed(2)}, ${targetPosition.dy.toStringAsFixed(2)})');
    if (isDefensive) print('   🛡️ حركة دفاعية');
    if (isStrategic) print('   🧠 حركة استراتيجية');
  }

  void _executeEvasion(Map<String, dynamic> decision) {
    final targetPosition = decision['target_position'] as Offset;
    final weaponType = decision['weapon'] as OnlineWeaponType?;

    // حركة تجنب سريعة
    final dx = targetPosition.dx - botPlayer.x;

    // استخدام قدرة الحركة السريعة إذا كانت متاحة
    double evasionSpeed = 0.04;
    if (evolutionSystem.unlockedAbilities['quick_dash'] == true) {
      evasionSpeed = 0.06;
    }

    botPlayer.velocityX = dx.sign * evasionSpeed;
    botPlayer.isFacingRight = dx > 0;

    // قفز تجنبي
    if (botPlayer.isGrounded) {
      botPlayer.velocityY = -0.03;
    }

    // هجوم أثناء التحرك إن أمكن
    if (weaponType != null && Random().nextDouble() < 0.5) {
      botPlayer.performAttack(OnlineAttackType.light);
    }

    print('🔄 البوت ينفذ حركة تجنب');
  }

  void _executeIdle() {
    // حركة عشوائية خفيفة
    if (Random().nextDouble() < 0.3) {
      botPlayer.velocityX = (Random().nextDouble() * 0.04 - 0.02);
    } else {
      botPlayer.velocityX *= 0.9;
    }

    print('💤 البوت في وضع السكون التكتيكي');
  }

  void _recordDecision(Map<String, dynamic> decision) {
    final memoryEntry = {
      'decision': decision,
      'bot_state': {
        'position': Offset(botPlayer.x, botPlayer.y),
        'health': botPlayer.health,
        'weapon': botPlayer.currentWeapon?.type.toString(),
      },
      'enemy_state': {
        'position': Offset(humanPlayer.x, humanPlayer.y),
        'health': humanPlayer.health,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // حفظ في الذاكرة طويلة المدى
    if (!longTermMemory.containsKey(botPlayer.playerId)) {
      longTermMemory[botPlayer.playerId] = [];
    }

    longTermMemory[botPlayer.playerId]!.add(memoryEntry);

    // الحفاظ على آخر 100 قرار
    if (longTermMemory[botPlayer.playerId]!.length > 100) {
      longTermMemory[botPlayer.playerId]!.removeAt(0);
    }
  }

  void adaptToPlayer() {
    // تحليل آخر 20 قرار
    final memoryList = longTermMemory[botPlayer.playerId] ?? [];
    if (memoryList.isEmpty) return;

    // أخذ آخر 20 قرار (أو أقل إذا لم يتوفر)
    final startIndex = memoryList.length > 20 ? memoryList.length - 20 : 0;
    final recentDecisions = memoryList.sublist(startIndex);

    if (recentDecisions.length < 5) return;

    int successfulAttacks = 0;
    int totalAttacks = 0;
    int successfulDefenses = 0;
    int totalDefenses = 0;

    for (final decision in recentDecisions) {
      final action = decision['decision']['action'] as String;
      final botState = decision['bot_state'] as Map<String, dynamic>;
      final enemyState = decision['enemy_state'] as Map<String, dynamic>;

      final botHealthAfter = botPlayer.health;
      final enemyHealthAfter = humanPlayer.health;

      // تحليل النجاح بناءً على التغيير في الصحة
      if (action == 'attack') {
        totalAttacks++;
        // يعتبر الهجوم ناجحاً إذا سبب ضرراً للعدو
        if (enemyHealthAfter < (enemyState['health'] as double)) {
          successfulAttacks++;
        }
      } else if (action == 'move_to' || action == 'evade') {
        totalDefenses++;
        // يعتبر الدفاع ناجحاً إذا لم يتلقَ البوت ضرراً
        if (botHealthAfter >= (botState['health'] as double)) {
          successfulDefenses++;
        }
      }
    }

    // تحديث عوامل التكيف - ⭐ أضف null checks هنا
    if (totalAttacks > 0) {
      final attackSuccessRate = successfulAttacks / totalAttacks;

      // ⭐ استخدم ?? للإشارة إلى القيمة الافتراضية إذا كانت null
      final currentAggression = adaptationFactors['aggression'] ?? 0.5;
      final currentAccuracy = adaptationFactors['accuracy'] ?? 0.5;

      adaptationFactors['aggression'] = (currentAggression + attackSuccessRate) / 2;
      adaptationFactors['accuracy'] = (currentAccuracy + attackSuccessRate) / 2;
    }

    if (totalDefenses > 0) {
      final defenseSuccessRate = successfulDefenses / totalDefenses;

      // ⭐ استخدم ?? للإشارة إلى القيمة الافتراضية إذا كانت null
      final currentDefense = adaptationFactors['defense'] ?? 0.5;
      final currentMobility = adaptationFactors['mobility'] ?? 0.5;

      adaptationFactors['defense'] = (currentDefense + defenseSuccessRate) / 2;
      adaptationFactors['mobility'] = (currentMobility + defenseSuccessRate) / 2;
    }

    print('🔄 تكيف البوت مع أسلوب اللاعب');
    print('   ⚔️ معدل نجاح الهجوم: ${totalAttacks > 0 ? (successfulAttacks/totalAttacks*100).toStringAsFixed(1) : 0}%');
    print('   🛡️ معدل نجاح الدفاع: ${totalDefenses > 0 ? (successfulDefenses/totalDefenses*100).toStringAsFixed(1) : 0}%');
  }

  void dispose() {
    _predictionTimer?.cancel();
  }
}

// ========== 4. الخدمة الرئيسية للبوت ==========
class AIBotService {
  static AIBotService? _instance;

  // الأنظمة
  AdvancedEvolutionSystem? _evolutionSystem;
  AdvancedWeaponSystem? _weaponSystem;
  AdvancedAIController? _aiController;

  // حالة البوت
  OnlinePlayer? _botPlayer;
  OnlinePlayer? _humanPlayer;
  bool _isInitialized = false;
  Timer? _updateTimer;

  // الذاكرة المستمرة
  Map<String, dynamic> _persistentMemory = {};

  static AIBotService get instance {
    _instance ??= AIBotService._internal();
    return _instance!;
  }

  AIBotService._internal() {
    // تحميل الذاكرة المستمرة إذا كانت موجودة
    _loadPersistentMemory();
  }

  void initializeBot({
    required OnlinePlayer botPlayer,
    required OnlinePlayer humanPlayer,
    int difficulty = 3,
    String behavior = 'balanced',
  }) {
    print('🤖 === تهيئة البوت الذكي ===');

    _botPlayer = botPlayer;
    _humanPlayer = humanPlayer;

    // 1. تهيئة نظام التطور
    _evolutionSystem = AdvancedEvolutionSystem();

    final botId = botPlayer.playerId;
    if (_persistentMemory.containsKey(botId)) {
      final savedData = _persistentMemory[botId];

      // ⭐ إصلاح الترميز: تحويل Map<OnlineWeaponType, dynamic> إلى Map<String, dynamic>
      if (savedData is Map<String, dynamic> && savedData.containsKey('evolution')) {
        final evolutionData = savedData['evolution'];

        // ⭐ تأكد أن البيانات من النوع الصحيح
        if (evolutionData is Map<String, dynamic>) {
          _evolutionSystem!.fromJson(evolutionData);
          print('📂 تم تحميل بيانات التطور السابقة للمستوى ${_evolutionSystem!.level}');
        }
      }
    }

    // 2. تهيئة نظام الأسلحة
    _weaponSystem = AdvancedWeaponSystem();

    // تحميل إحصائيات الأسلحة السابقة
    if (_persistentMemory.containsKey(botId) &&
        _persistentMemory[botId].containsKey('weapon_stats')) {
      final savedStats = _persistentMemory[botId]['weapon_stats'] as Map<String, dynamic>;
      // يمكن إضافة تحميل الإحصائيات هنا
    }

    // 3. تهيئة وحدة التحكم
    _aiController = AdvancedAIController(
      botPlayer: botPlayer,
      humanPlayer: humanPlayer,
      evolutionSystem: _evolutionSystem!,
      weaponSystem: _weaponSystem!,
      behavior: behavior,
      difficulty: difficulty,
    );

    _isInitialized = true;

    // 4. بدء نظام التحديث
    _startUpdateSystem();

    print('✅ تم تهيئة البوت بنجاح');
    print('   👤 البوت: ${botPlayer.playerId}');
    print('   🎮 الصعوبة: $difficulty');
    print('   🧠 السلوك: $behavior');
    print('   📊 المستوى: ${_evolutionSystem!.level}');
  }

  void _startUpdateSystem() {
    // تحديث البوت كل 100ms (10 مرات في الثانية)
    _updateTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_isInitialized && _botPlayer != null && _humanPlayer != null) {
        _updateBot();
      }
    });
  }

  void _updateBot() {
    try {
      if (_botPlayer!.state == PlayerState.death
          || _humanPlayer!.state == PlayerState.death) {
        return;
      }

      // 1. اتخاذ قرار استراتيجي
      final decision = _aiController!._makeStrategicDecision();

      // 2. تنفيذ القرار
      _aiController!.executeDecision(decision);

      // 3. التعلم من النتيجة (سيتم تحديثه في الأحداث)

    } catch (e) {
      print('❌ خطأ في تحديث البوت: $e');
    }
  }

  void notifyEvent(String eventType, Map<String, dynamic> data) {
    if (!_isInitialized) return;

    switch (eventType) {
      case 'player_attacked':
        _handleAttackEvent(data);
        break;
      case 'player_hit':
        _handleHitEvent(data);
        break;
      case 'player_missed':
        _handleMissEvent(data);
        break;
      case 'player_damaged':
        _handleDamageEvent(data);
        break;
      case 'player_killed':
        _handleKillEvent(data);
        break;
      case 'weapon_picked_up':
        _handleWeaponPickupEvent(data);
        break;
      case 'player_respawned':
        _handleRespawnEvent(data);
        break;
    }
  }

  void _handleAttackEvent(Map<String, dynamic> data) {
    final attackerId = data['attacker_id'] as String?;
    final weaponType = data['weapon_type'] as OnlineWeaponType?;
    final attackType = data['attack_type'] as OnlineAttackType?;

    if (attackerId == _botPlayer!.playerId && weaponType != null) {
      // البوت هاجم
      final situation = _getCurrentSituation();

      // التعلم من الهجوم
      _evolutionSystem!.learnPlayerPattern(
        _humanPlayer!.playerId,
        'attack_${attackType?.toString() ?? "unknown"}',
        situation,
        false, // سيتم تحديثه عند معرفة النتيجة
      );
    }
  }

  void _handleHitEvent(Map<String, dynamic> data) {
    final attackerId = data['attacker_id'] as String?;
    final targetId = data['target_id'] as String?;
    final weaponType = data['weapon_type'] as OnlineWeaponType?;
    final damage = data['damage'] as int?;
    final distance = data['distance'] as double?;

    if (attackerId == _botPlayer!.playerId && weaponType != null) {
      // البوت أصاب الهدف
      final situation = _getCurrentSituation();

      // تحديث نظام التطور
      _evolutionSystem!.learnPlayerPattern(
        _humanPlayer!.playerId,
        'attack_hit',
        situation,
        true,
      );

      // تحديث نظام الأسلحة
      if (damage != null && distance != null) {
        _weaponSystem!.recordWeaponSuccess(weaponType, true, damage, distance);
      }

      // زيادة الخبرة
      _evolutionSystem!.updateExperience(10 + (damage ?? 0));
    } else if (targetId == _botPlayer!.playerId) {
      // البوت تعرض لإصابة
      final situation = _getCurrentSituation();

      // التعلم من الهجوم الذي تعرض له
      _evolutionSystem!.learnPlayerPattern(
        _humanPlayer!.playerId,
        'got_hit',
        situation,
        false, // فشل في تجنب الهجوم
      );
    }
  }

  void _handleMissEvent(Map<String, dynamic> data) {
    final attackerId = data['attacker_id'] as String?;
    final weaponType = data['weapon_type'] as OnlineWeaponType?;
    final distance = data['distance'] as double?;

    if (attackerId == _botPlayer!.playerId && weaponType != null) {
      // البوت أخطأ الهدف
      final situation = _getCurrentSituation();

      _evolutionSystem!.learnPlayerPattern(
        _humanPlayer!.playerId,
        'attack_miss',
        situation,
        false,
      );

      if (distance != null) {
        _weaponSystem!.recordWeaponSuccess(weaponType, false, 0, distance);
      }
    }
  }

  void _handleDamageEvent(Map<String, dynamic> data) {
    final targetId = data['target_id'] as String?;
    final damage = data['damage'] as int?;

    if (targetId == _humanPlayer!.playerId) {
      // البوت تسبب بضرر للاعب
      if (damage != null) {
        // زيادة الخبرة بناءً على الضرر
        _evolutionSystem!.updateExperience(damage * 2);
      }
    }
  }

  void _handleKillEvent(Map<String, dynamic> data) {
    final killerId = data['killer_id'] as String?;
    final victimId = data['victim_id'] as String?;

    if (killerId == _botPlayer!.playerId) {
      // البوت قتل اللاعب
      _evolutionSystem!.updateExperience(100);

      print('🏆 البوت قتل اللاعب! +100 خبرة');
    } else if (victimId == _botPlayer!.playerId) {
      // البوت مات
      _evolutionSystem!.updateExperience(20); // خبرة أقل للموت

      // التكيف مع أسلوب اللاعب
      _aiController!.adaptToPlayer();
    }
  }

  void _handleWeaponPickupEvent(Map<String, dynamic> data) {
    final playerId = data['player_id'] as String?;
    final weaponType = data['weapon_type'] as OnlineWeaponType?;

    if (playerId == _botPlayer!.playerId && weaponType != null) {
      print('🗡️ البوت التقط سلاح: ${OnlineWeaponLibrary.weapons[weaponType]?.name}');
    }
  }

  void _handleRespawnEvent(Map<String, dynamic> data) {
    final playerId = data['player_id'] as String?;

    if (playerId == _botPlayer!.playerId) {
      // البوت عاد للحياة
      print('🔄 البوت عاد للحياة');

      // تحليل الأداء السابق
      _aiController!.adaptToPlayer();
    }
  }

  String _getCurrentSituation() {
    final distance = _calculateDistance();
    final botHealth = _botPlayer!.health;
    final humanHealth = _humanPlayer!.health;

    if (distance < 0.08) {
      return botHealth > humanHealth ? 'close_advantage' : 'close_disadvantage';
    } else if (distance < 0.15) {
      return 'medium_range';
    } else if (distance < 0.25) {
      return 'far_range';
    } else {
      return 'very_far';
    }
  }

  double _calculateDistance() {
    return sqrt(
        pow(_botPlayer!.x - _humanPlayer!.x, 2) +
            pow(_botPlayer!.y - _humanPlayer!.y, 2)
    );
  }

  Map<String, dynamic> getAdvancedBotInfo() {
    if (!_isInitialized) {
      return {'error': 'Bot not initialized'};
    }

    return {
      'is_initialized': _isInitialized,
      'bot_player_id': _botPlayer!.playerId,
      'evolution': _evolutionSystem!.toJson(),
      'weapon_stats': _weaponSystem!.weaponStats,
      'difficulty': _aiController!.difficulty,
      'behavior': _aiController!.behavior,
      'unlocked_abilities': _evolutionSystem!.unlockedAbilities,
      'player_weaknesses': _evolutionSystem!.getPlayerWeaknesses(_humanPlayer!.playerId),
      'adaptation_factors': _aiController!.adaptationFactors,
      'short_term_memory_count': _aiController!.shortTermMemory.length,
      'long_term_memory_count': _aiController!.longTermMemory[_botPlayer!.playerId]?.length ?? 0,
      'pattern_memory_count': _aiController!.patternMemory[_humanPlayer!.playerId]?.length ?? 0,
    };
  }

  void _loadPersistentMemory() {
    try {
      // يمكن هنا تحميل الذاكرة من SharedPreferences أو قاعدة بيانات
      _persistentMemory = {}; // سيتم تنفيذه لاحقاً
    } catch (e) {
      print('❌ خطأ في تحميل الذاكرة المستمرة: $e');
      _persistentMemory = {};
    }
  }

  void _savePersistentMemory() {
    try {
      if (_botPlayer != null && _evolutionSystem != null) {
        final botId = _botPlayer!.playerId;

        _persistentMemory[botId] = {
          'evolution': _evolutionSystem!.toJson(),
          'weapon_stats': _weaponSystem!.weaponStats,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        };

        // يمكن هنا حفظ الذاكرة في SharedPreferences أو قاعدة بيانات
        print('💾 تم حفظ بيانات البوت للذاكرة المستمرة');
      }
    } catch (e) {
      print('❌ خطأ في حفظ الذاكرة المستمرة: $e');
    }
  }

  void stop() {
    print('🛑 إيقاف البوت الذكي...');

    _updateTimer?.cancel();
    _aiController?.dispose();
    _weaponSystem?.dispose();

    // حفظ الذاكرة المستمرة
    _savePersistentMemory();

    _isInitialized = false;
    _botPlayer = null;
    _humanPlayer = null;

    print('✅ تم إيقاف البوت');
  }

  void reset() {
    print('🔄 إعادة تعيين البوت...');

    stop();

    _evolutionSystem = null;
    _weaponSystem = null;
    _aiController = null;
    _persistentMemory.clear();

    print('✅ تم إعادة تعيين البوت');
  }

  // دالة مساعدة للحصول على معلومات تصحيح الأخطاء
  void debugPrintInfo() {
    if (!_isInitialized) {
      print('❌ البوت غير مهيئ');
      return;
    }

    print('''
🤖 === معلومات البوت الذكي ===
المستوى: ${_evolutionSystem!.level}
الخبرة: ${_evolutionSystem!.experience}/${_evolutionSystem!.experienceToNextLevel}
عامل الذكاء: ${_evolutionSystem!.intelligenceFactor.toStringAsFixed(2)}
عامل رد الفعل: ${_evolutionSystem!.reactionFactor.toStringAsFixed(2)}
عامل التنبؤ: ${_evolutionSystem!.predictionFactor.toStringAsFixed(2)}
عامل العدوانية: ${_evolutionSystem!.aggressionFactor.toStringAsFixed(2)}

القدرات المفتوحة:
${_evolutionSystem!.unlockedAbilities.entries.map((e) => '  ${e.key}: ${e.value ? "✅" : "❌"}').join('\n')}

عوامل التكيف:
  العدوانية: ${(_aiController!.adaptationFactors['aggression']! * 100).toStringAsFixed(1)}%
  الدفاع: ${(_aiController!.adaptationFactors['defense']! * 100).toStringAsFixed(1)}%
  الحركة: ${(_aiController!.adaptationFactors['mobility']! * 100).toStringAsFixed(1)}%
  الدقة: ${(_aiController!.adaptationFactors['accuracy']! * 100).toStringAsFixed(1)}%

نقاط ضعف اللاعب:
${_evolutionSystem!.getPlayerWeaknesses(_humanPlayer!.playerId).map((w) => '  • $w').join('\n')}
============================
''');
  }
}

// ========== 5. مدير ظهور الأسلحة (اختياري) ==========
class WeaponSpawnManager {
  static void spawnStrategicWeapon(OnlineGameService gameService, OnlinePlayer bot) {
    final random = Random();

    // ظهور أسلحة في مواقع استراتيجية مفيدة للبوت
    final strategicPositions = [
      Offset(0.3, 0.7),  // قريب من موقع البوت المحتمل
      Offset(0.7, 0.7),  // موقع مركزي
      Offset(0.5, 0.5),  // موقع عالي استراتيجي
    ];

    // اختيار موقع عشوائي
    final position = strategicPositions[random.nextInt(strategicPositions.length)];

    // اختيار سلاح مفيد للبوت بناءً على أسلوبه
    final availableWeapons = OnlineWeaponLibrary.weapons.values.toList();
    OnlineWeapon selectedWeapon;

    // اختيار سلاح بناءً على نمط البوت
    if (bot.weapons.isNotEmpty) {
      final currentWeapon = bot.currentWeapon;
      if (currentWeapon != null) {
        // اختيار سلاح يكمّل السلاح الحالي
        switch (currentWeapon.type) {
          case OnlineWeaponType.sword:
          // سلاح بعيد المدى للتمييز
            selectedWeapon = OnlineWeaponLibrary.weapons[OnlineWeaponType.bow] ?? availableWeapons[0];
            break;
          case OnlineWeaponType.bow:
          // سلاح قريب للدفاع
            selectedWeapon = OnlineWeaponLibrary.weapons[OnlineWeaponType.sword] ?? availableWeapons[0];
            break;
          case OnlineWeaponType.hammer:
          // سلاح سريع لتعويض البطء
            selectedWeapon = OnlineWeaponLibrary.weapons[OnlineWeaponType.katars] ?? availableWeapons[0];
            break;
          default:
            selectedWeapon = availableWeapons[random.nextInt(availableWeapons.length)];
        }
      } else {
        selectedWeapon = availableWeapons[random.nextInt(availableWeapons.length)];
      }
    } else {
      selectedWeapon = availableWeapons[random.nextInt(availableWeapons.length)];
    }

    print('🎯 ظهور سلاح استراتيجي للبوت: ${selectedWeapon.name}');
    print('   📍 الموقع: (${position.dx.toStringAsFixed(2)}, ${position.dy.toStringAsFixed(2)})');

    // هنا يمكنك إضافة السلاح للأرض في gameService
    // gameService.addWeaponToGround(selectedWeapon, position.dx, position.dy);
  }
}