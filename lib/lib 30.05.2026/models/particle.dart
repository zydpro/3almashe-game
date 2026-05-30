// lib/models/particle.dart
import 'dart:math';
import 'package:flutter/material.dart';

class GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double size;
  Color color;
  double maxLife;

  GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
    required this.maxLife,
  });

  // إضافة خاصية opacity
  double get opacity => life;

  void update() {
    x += vx;
    y += vy;
    life -= 0.02;
    vy += 0.0005;
  }

  bool get isDead => life <= 0;

  static List<GameParticle> createJumpParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.005,
        vy: (random.nextDouble() - 0.5) * 0.005 - 0.002,
        life: 1.0,
        size: random.nextDouble() * 3 + 2,
        color: Colors.yellow,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createPowerUpParticles(double x, double y, Color color, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.006,
        vy: (random.nextDouble() - 0.5) * 0.006 - 0.003,
        life: 1.0,
        size: random.nextDouble() * 4 + 2,
        color: color,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createShieldParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.004,
        vy: (random.nextDouble() - 0.5) * 0.004 - 0.002,
        life: 1.0,
        size: random.nextDouble() * 5 + 3,
        color: Colors.blue,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createComboParticles(double x, double y, double multiplier, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.007,
        vy: (random.nextDouble() - 0.5) * 0.007 - 0.004,
        life: 1.0,
        size: random.nextDouble() * 6 + 4,
        color: _getComboColor(multiplier),
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createHitParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.008,
        vy: (random.nextDouble() - 0.5) * 0.008 - 0.005,
        life: 1.0,
        size: random.nextDouble() * 4 + 2,
        color: Colors.red,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createPlatformBreakParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.15,
        y: y + (random.nextDouble() - 0.5) * 0.15,
        vx: (random.nextDouble() - 0.5) * 0.008,
        vy: (random.nextDouble() - 0.5) * 0.008 - 0.004,
        life: 1.0,
        size: random.nextDouble() * 6 + 4,
        color: Colors.brown,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createBrickBreakParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.2,
        y: y + (random.nextDouble() - 0.5) * 0.2,
        vx: (random.nextDouble() - 0.5) * 0.01,
        vy: (random.nextDouble() - 0.5) * 0.01 - 0.006,
        life: 1.0,
        size: random.nextDouble() * 5 + 3,
        color: Colors.orange,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createEnemyHitParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.007,
        vy: (random.nextDouble() - 0.5) * 0.007 - 0.004,
        life: 1.0,
        size: random.nextDouble() * 4 + 2,
        color: Colors.orange,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createEnemyDefeatParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.01,
        vy: (random.nextDouble() - 0.5) * 0.01 - 0.006,
        life: 1.0,
        size: random.nextDouble() * 5 + 3,
        color: Colors.red,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createBossHitParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.012,
        vy: (random.nextDouble() - 0.5) * 0.012 - 0.008,
        life: 1.0,
        size: random.nextDouble() * 8 + 5,
        color: Colors.purple,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createVictoryParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.2,
        y: y + (random.nextDouble() - 0.5) * 0.2,
        vx: (random.nextDouble() - 0.5) * 0.015,
        vy: (random.nextDouble() - 0.5) * 0.015 - 0.01,
        life: 1.0,
        size: random.nextDouble() * 10 + 6,
        color: _getRandomVictoryColor(random),
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createHealingParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.005,
        vy: (random.nextDouble() - 0.5) * 0.005 - 0.002,
        life: 1.0,
        size: random.nextDouble() * 3 + 2,
        color: Colors.green,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createSpeedBoostParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.008,
        vy: (random.nextDouble() - 0.5) * 0.008 - 0.003,
        life: 1.0,
        size: random.nextDouble() * 2 + 1,
        color: Colors.yellow,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createSlowEffectParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.002,
        vy: (random.nextDouble() - 0.5) * 0.002 - 0.001,
        life: 1.0,
        size: random.nextDouble() * 4 + 3,
        color: Colors.blue,
        maxLife: 1.0,
      );
    });
  }

  static List<GameParticle> createSlowCharacterParticles(double x, double y, int count, Random random) {
    return List.generate(count, (index) {
      return GameParticle(
        x: x + (random.nextDouble() - 0.5) * 0.1,
        y: y + (random.nextDouble() - 0.5) * 0.1,
        vx: (random.nextDouble() - 0.5) * 0.002,
        vy: (random.nextDouble() - 0.5) * 0.002 - 0.001,
        life: 1.0,
        size: random.nextDouble() * 4 + 3,
        color: Colors.red,
        maxLife: 1.0,
      );
    });
  }


  static Color _getComboColor(double multiplier) {
    if (multiplier >= 3.0) return Colors.purple;
    if (multiplier >= 2.5) return Colors.red;
    if (multiplier >= 2.0) return Colors.orange;
    return Colors.green;
  }

  static Color _getRandomVictoryColor(Random random) {
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];
    return colors[random.nextInt(colors.length)];
  }
}