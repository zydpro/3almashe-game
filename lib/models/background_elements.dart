import 'package:flutter/material.dart';
import 'dart:math';

/// ---------------- BACKGROUND ELEMENT ----------------
class BackgroundElement {
  double x;
  double y;
  double speed;
  double size;
  Color color;
  IconData icon;
  BackgroundElementType type;

  BackgroundElement({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.icon,
    required this.type,
  });

  void move() {
    x -= speed;
  }

  bool isOffScreen() => x < -0.2;
}

enum BackgroundElementType { cloud, tree, building, mountain, bird, star }

/// ---------------- BACKGROUND MANAGER ----------------
class BackgroundManager {
  List<BackgroundElement> elements = [];
  final Random random = Random();

  void initialize() {
    elements.clear();

    // إنشاء عناصر خلفية متنوعة بمواقع منظمة
    for (int i = 0; i < 4; i++) _createElement(BackgroundElementType.cloud, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.mountain, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.bird, true);
    for (int i = 0; i < 3; i++) _createElement(BackgroundElementType.tree, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.building, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.star, true);
  }

  void update() {
    // قائمة العناصر التي يجب إزالتها
    final elementsToRemove = <BackgroundElement>[];

    // تحريك العناصر والتحقق من الخروج من الشاشة
    for (var element in elements) {
      element.move();
      if (element.isOffScreen()) {
        elementsToRemove.add(element);
      }
    }

    // إزالة العناصر التي خرجت من الشاشة
    for (var element in elementsToRemove) {
      elements.remove(element);
      _createElement(element.type, false); // إنشاء بديل
    }
  }

  void _createElement(BackgroundElementType type, bool initialSpawn) {
    double yPosition;
    double speed;
    double size;
    Color color;
    IconData icon;

    switch (type) {
      case BackgroundElementType.cloud:
        yPosition = 0.1 + random.nextDouble() * 0.25;
        speed = 0.002 + random.nextDouble() * 0.003;
        size = 35 + random.nextDouble() * 20;
        color = Colors.white.withOpacity(0.9);
        icon = Icons.cloud;
        break;

      case BackgroundElementType.tree:
        yPosition = 0.72;
        speed = 0.008 + random.nextDouble() * 0.006;
        size = 50 + random.nextDouble() * 30;
        color = Colors.green.shade800;
        icon = Icons.park;
        break;

      case BackgroundElementType.building:
        yPosition = 0.65;
        speed = 0.005 + random.nextDouble() * 0.004;
        size = 70 + random.nextDouble() * 40;
        color = Colors.grey.shade700;
        icon = Icons.business;
        break;

      case BackgroundElementType.mountain:
        yPosition = 0.55;
        speed = 0.0015 + random.nextDouble() * 0.0015;
        size = 90 + random.nextDouble() * 50;
        color = Colors.brown.shade600.withOpacity(0.8);
        icon = Icons.terrain;
        break;

      case BackgroundElementType.bird:
        yPosition = 0.3 + random.nextDouble() * 0.3;
        speed = 0.01 + random.nextDouble() * 0.008;
        size = 18 + random.nextDouble() * 8;
        color = Colors.black.withOpacity(0.8);
        icon = Icons.flight;
        break;

      case BackgroundElementType.star:
        yPosition = 0.05 + random.nextDouble() * 0.15;
        speed = 0.001 + random.nextDouble() * 0.0015;
        size = 6 + random.nextDouble() * 6;
        color = Colors.yellow.withOpacity(0.95);
        icon = Icons.star;
        break;
    }

    double startX = initialSpawn
        ? random.nextDouble() * 1.5
        : 1.2 + random.nextDouble() * 0.3;

    elements.add(BackgroundElement(
      x: startX,
      y: yPosition,
      speed: speed,
      size: size,
      color: color,
      icon: icon,
      type: type,
    ));
  }

  void dispose() {
    elements.clear();
  }
}

/// ---------------- BUMP MANAGER ----------------
class Bump {
  double x;
  double y;
  double width;
  double height;
  double speed;
  Color color;

  Bump({
    required this.x,
    required this.y,
    this.width = 80,
    this.height = 20,
    this.speed = 0.015,
    this.color = const Color(0xFF8B4513),
  });

  void move() {
    x -= speed;
  }

  bool isOffScreen() => x < -0.2;
}

class BumpManager {
  List<Bump> bumps = [];
  final Random random = Random();

  void spawnBump() {
    if (random.nextDouble() < 0.3) {
      bumps.add(Bump(
        x: 1.2,
        y: 0.75,
        speed: 0.018 + random.nextDouble() * 0.01,
        width: 50 + random.nextDouble() * 50,
        height: 15 + random.nextDouble() * 20,
        color: Color.fromRGBO(
          139 + random.nextInt(40),
          69 + random.nextInt(40),
          19 + random.nextInt(30),
          1.0,
        ),
      ));
    }
  }

  void update() {
    // قائمة المطبات التي يجب إزالتها
    final bumpsToRemove = <Bump>[];

    for (var bump in bumps) {
      bump.move();
      if (bump.isOffScreen()) {
        bumpsToRemove.add(bump);
      }
    }

    // إزالة المطبات بعد الانتهاء من التكرار
    for (var bump in bumpsToRemove) {
      bumps.remove(bump);
    }
  }

  void dispose() {
    bumps.clear();
  }
}