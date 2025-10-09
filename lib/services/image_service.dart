import 'package:flutter/material.dart';

class ImageService {
  static const String characterRun = 'assets/images/characters/character_run.png';
  static const String characterJump = 'assets/images/characters/character_jump.png';
  static const String characterDuck = 'assets/images/characters/character_duck.png';
  static const String characterAttack = 'assets/images/characters/character_attack.png';

  static const String duckIcon = 'assets/images/ui/duck_icon.png';
  static const String pipe = 'assets/images/obstacles/pipe.png';
  static const String brick = 'assets/images/obstacles/brick.png';
  static const String coin = 'assets/images/resources/coin.png';
  static const String package = 'assets/images/resources/package.png';

  // ✅ إضافة صورة المنصة
  static const String platform = 'assets/images/platforms/platform.png';

  // الأعداء
  static const String enemyGoomba = 'assets/images/enemies/goomba.png';
  static const String enemyMushroom = 'assets/images/enemies/mushroom.png';
  static const String enemyKoopa = 'assets/images/enemies/koopa.png';
  static const String enemyFlying = 'assets/images/enemies/flying_enemy.png';

  // الزعماء
  static const String boss1 = 'assets/images/bosses/boss1.png';
  static const String boss2 = 'assets/images/bosses/boss2.png';
  static const String boss3 = 'assets/images/bosses/boss3.png';
  static const String boss4 = 'assets/images/bosses/boss4.png';
  static const String boss5 = 'assets/images/bosses/boss5.png';
  static const String rareBoss1 = 'assets/images/bosses/rare_boss1.png';
  static const String rareBoss2 = 'assets/images/bosses/rare_boss2.png';
  static const String rareBoss3 = 'assets/images/bosses/rare_boss3.png';
  static const String rareBoss4 = 'assets/images/bosses/rare_boss4.png';
  static const String rareBoss5 = 'assets/images/bosses/rare_boss5.png';
  static const String finalBoss = 'assets/images/bosses/final_boss.png';

  // الباور أب
  static const String powerUpPoints = 'assets/images/powerups/points.png';
  static const String powerUpShield = 'assets/images/powerups/shield.png';
  static const String powerUpHealth = 'assets/images/powerups/health.png';

  // الواجهة
  static const String heart = 'assets/images/ui/heart.png';
  static const String emptyHeart = 'assets/images/ui/empty_heart.png';
  static const String playButton = 'assets/images/ui/play_button.png';
  static const String bossHealthBar = 'assets/images/ui/boss_health_bar.png';

  static Future<void> preloadImages(BuildContext context) async {
    try {
      // الشخصيات
      await precacheImage(const AssetImage(characterRun), context);
      await precacheImage(const AssetImage(characterJump), context);
      await precacheImage(const AssetImage(characterDuck), context);
      await precacheImage(const AssetImage(characterAttack), context);

      // العوائق والمنصات
      await precacheImage(const AssetImage(pipe), context);
      await precacheImage(const AssetImage(brick), context);
      await precacheImage(const AssetImage(platform), context); // ✅ المنصة

      // الأعداء
      await precacheImage(const AssetImage(enemyGoomba), context);
      await precacheImage(const AssetImage(enemyMushroom), context);
      await precacheImage(const AssetImage(enemyKoopa), context);
      await precacheImage(const AssetImage(enemyFlying), context);

      // الزعماء
      await precacheImage(const AssetImage(boss1), context);
      await precacheImage(const AssetImage(boss2), context);
      await precacheImage(const AssetImage(boss3), context);
      await precacheImage(const AssetImage(boss4), context);
      await precacheImage(const AssetImage(boss5), context);
      await precacheImage(const AssetImage(rareBoss1), context);
      await precacheImage(const AssetImage(rareBoss2), context);
      await precacheImage(const AssetImage(rareBoss3), context);
      await precacheImage(const AssetImage(rareBoss4), context);
      await precacheImage(const AssetImage(rareBoss5), context);
      await precacheImage(const AssetImage(finalBoss), context);

      // الباور أب
      await precacheImage(const AssetImage(powerUpPoints), context);
      await precacheImage(const AssetImage(powerUpShield), context);
      await precacheImage(const AssetImage(powerUpHealth), context);

      // الموارد
      await precacheImage(const AssetImage(coin), context);
      await precacheImage(const AssetImage(package), context);

      // الواجهة
      await precacheImage(const AssetImage(heart), context);
      await precacheImage(const AssetImage(emptyHeart), context);
      await precacheImage(const AssetImage(playButton), context);
      await precacheImage(const AssetImage(bossHealthBar), context);

    } catch (e) {
      print('خطأ في تحميل الصور: $e');
    }
  }

  static String getEnemyImage(String enemyType) {
    switch (enemyType) {
      case 'goomba': return enemyGoomba;
      case 'mushroom': return enemyMushroom;
      case 'koopa': return enemyKoopa;
      case 'koopa': return enemyFlying;
      default: return enemyGoomba;
    }
  }

  static String getBossImage(int level, bool isRare, bool isFinal) {
    if (isFinal) return finalBoss;
    if (isRare) {
      final rareIndex = _getRareBossIndex(level);
      switch (rareIndex) {
        case 0: return rareBoss1;
        case 1: return rareBoss2;
        case 2: return rareBoss3;
        case 3: return rareBoss4;
        case 4: return rareBoss5;
        default: return rareBoss1;
      }
    } else {
      final normalIndex = level % 5;
      switch (normalIndex) {
        case 0: return boss1;
        case 1: return boss2;
        case 2: return boss3;
        case 3: return boss4;
        case 4: return boss5;
        default: return boss1;
      }
    }
  }

  static int _getRareBossIndex(int level) {
    final rareLevels = [15, 25, 50, 75, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99];
    return rareLevels.indexOf(level) % 5;
  }

  static String getPowerUpImage(String powerUpType) {
    switch (powerUpType) {
      case 'points': return powerUpPoints;
      case 'shield': return powerUpShield;
      case 'health': return powerUpHealth;
      default: return powerUpPoints;
    }
  }
}