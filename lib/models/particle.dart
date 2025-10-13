import 'dart:math';
import 'package:flutter/material.dart';

class GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;
  Color color;
  double size;

  GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy;
    life -= 0.02;

    // ✅ تطبيق الجاذبية المحسنة
    vy += 0.001;

    // ✅ مقاومة الهواء المحسنة
    vx *= 0.95;
    vy *= 0.95;
  }

  bool get isDead => life <= 0;

  double get opacity => (life / maxLife).clamp(0.0, 1.0);

  // إنشاء جسيمات القفز
  static List<GameParticle> createJumpParticles(double x, double y, int count, Random random) {
    final particles = <GameParticle>[];

    for (int i = 0; i < count; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 0.02,
        vy: -random.nextDouble() * 0.03 - 0.01,
        life: 0.8 + random.nextDouble() * 0.4,
        maxLife: 1.2,
        color: Colors.white.withOpacity(0.8),
        size: 2.0 + random.nextDouble() * 3.0,
      ));
    }

    return particles;
  }

  // إنشاء جسيمات الباور أب
  static List<GameParticle> createPowerUpParticles(double x, double y, Color color, int count, Random random) {
    final particles = <GameParticle>[];

    for (int i = 0; i < count; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 0.04,
        vy: (random.nextDouble() - 0.5) * 0.04,
        life: 1.2 + random.nextDouble() * 0.6,
        maxLife: 1.8,
        color: color,
        size: 3.0 + random.nextDouble() * 4.0,
      ));
    }

    return particles;
  }

  // إنشاء جسيمات الدرع
  static List<GameParticle> createShieldParticles(double x, double y, int count, Random random) {
    final particles = <GameParticle>[];

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 3.14159 * 2;
      final speed = 0.015 + random.nextDouble() * 0.02;

      particles.add(GameParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 1.5 + random.nextDouble() * 0.5,
        maxLife: 2.0,
        color: Colors.blue.withOpacity(0.7),
        size: 3.0 + random.nextDouble() * 3.0,
      ));
    }

    return particles;
  }

  // إنشاء جسيمات الكومبو
  static List<GameParticle> createComboParticles(double x, double y, double multiplier, int count, Random random) {
    final particles = <GameParticle>[];
    final color = _getComboColor(multiplier);

    for (int i = 0; i < count; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 0.06,
        vy: -random.nextDouble() * 0.08 - 0.04,
        life: 1.0 + random.nextDouble() * 0.8,
        maxLife: 1.8,
        color: color,
        size: 3.5 + random.nextDouble() * 4.5,
      ));
    }

    return particles;
  }

  // إنشاء جسيمات الضربة
  static List<GameParticle> createHitParticles(double x, double y, int count, Random random) {
    final particles = <GameParticle>[];

    for (int i = 0; i < count; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 0.03,
        vy: (random.nextDouble() - 0.5) * 0.03,
        life: 0.5 + random.nextDouble() * 0.3,
        maxLife: 0.8,
        color: Colors.red.withOpacity(0.8),
        size: 1.5 + random.nextDouble() * 2.5,
      ));
    }

    return particles;
  }

  // إنشاء جسيمات هزيمة العدو
  static List<GameParticle> createEnemyDefeatParticles(double x, double y, int count, Random random) {
    final particles = <GameParticle>[];

    for (int i = 0; i < count; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 0.05,
        vy: -random.nextDouble() * 0.06 - 0.02,
        life: 0.8 + random.nextDouble() * 0.4,
        maxLife: 1.2,
        color: Colors.green.withOpacity(0.8),
        size: 2.0 + random.nextDouble() * 3.0,
      ));
    }

    return particles;
  }

  // إنشاء جسيمات ضربة الزعيم
  static List<GameParticle> createBossHitParticles(double x, double y, int count, Random random) {
    final particles = <GameParticle>[];

    for (int i = 0; i < count; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 0.07,
        vy: (random.nextDouble() - 0.5) * 0.07,
        life: 1.0 + random.nextDouble() * 0.5,
        maxLife: 1.5,
        color: Colors.purple.withOpacity(0.8),
        size: 3.0 + random.nextDouble() * 4.0,
      ));
    }

    return particles;
  }

  // إنشاء جسيمات النصر
  static List<GameParticle> createVictoryParticles(double x, double y, int count, Random random) {
    final particles = <GameParticle>[];

    for (int i = 0; i < count; i++) {
      particles.add(GameParticle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 0.08,
        vy: -random.nextDouble() * 0.12 - 0.04,
        life: 1.5 + random.nextDouble() * 1.0,
        maxLife: 2.5,
        color: _getRandomVictoryColor(random),
        size: 4.0 + random.nextDouble() * 5.0,
      ));
    }

    return particles;
  }

  static Color _getComboColor(double multiplier) {
    if (multiplier >= 3.0) return Colors.purple;
    if (multiplier >= 2.0) return Colors.red;
    if (multiplier >= 1.5) return Colors.orange;
    return Colors.yellow;
  }

  static Color _getRandomVictoryColor(Random random) {
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.red,
    ];
    return colors[random.nextInt(colors.length)];
  }
}