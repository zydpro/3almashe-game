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
  double opacity;
  double rotation;

  BackgroundElement({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.icon,
    required this.type,
    this.opacity = 1.0,
    this.rotation = 0.0,
  });

  void move() {
    x -= speed;
    // إضافة حركة دورانية للعناصر
    rotation += 0.01;
  }

  bool isOffScreen() => x < -0.2;
}

enum BackgroundElementType { cloud, tree, building, mountain, bird, star, special }

/// ---------------- GROUND SYSTEM ----------------
class GroundSystem {
  static final Random _random = Random();

  // === الزوج الحالي للخلفية والأرضية ===
  static Map<String, String> _currentPair = {
    'background': 'assets/images/backgrounds/city.png',
    'ground': 'assets/images/ground/city_ground.png',
  };

  // === نظام تحريك الخلفية والأرضية معاً ===
  static double _backgroundOffset = 0.0;
  static double _groundOffset = 0.0;

  // === سرعة متوسطة ومتوازنة للخلفية والأرضية ===
  static double _backgroundSpeed = 0.0015; // سرعة بطيئة للخلفية
  static double _groundSpeed = 0.003; // سرعة متوسطة للأرضية

  // === أبعاد مناسبة للشاشات 9:16 ===
  static double _backgroundHeight = 1.0; // ارتفاع الخلفية الكامل
  static double _groundHeight = 0.25; // ارتفاع الأرضية (25% من الشاشة)

  // ✅ الحصول على إزاحة الخلفية
  static double get backgroundOffset => _backgroundOffset;

  // ✅ الحصول على إزاحة الأرضية
  static double get groundOffset => _groundOffset;

  // ✅ الحصول على ارتفاع الخلفية
  static double get backgroundHeight => _backgroundHeight;

  // ✅ الحصول على ارتفاع الأرضية
  static double get groundHeight => _groundHeight;

  // ✅ تهيئة النظام
  static void initialize() {
    _backgroundOffset = 0.0;
    _groundOffset = 0.0;
    print('🎨 نظام الخلفية والأرضية تم تهيئته');
  }

  // ✅ تحديث النظام مع تحريك الخلفية والأرضية معاً
  static void update(double gameTime) {
    // تحريك الخلفية بسرعة بطيئة
    _backgroundOffset -= _backgroundSpeed;
    if (_backgroundOffset <= -1.0) {
      _backgroundOffset = 0.0;
    }

    // تحريك الأرضية بسرعة متوسطة (أسرع قليلاً من الخلفية)
    _groundOffset -= _groundSpeed;
    if (_groundOffset <= -1.0) {
      _groundOffset = 0.0;
    }
  }

  // ✅ تعيين الزوج الحالي للخلفية والأرضية
  static void setCurrentPair(Map<String, String> pair) {
    _currentPair = pair;
    print('🎨 تم تعيين الزوج: ${pair['background']} مع ${pair['ground']}');
  }

  // ✅ الحصول على معلومات الخلفية والأرضية الحالية
  static Map<String, dynamic> getCurrentGroundInfo() {
    return _currentPair;
  }

  // ✅ الحصول على صورة الأرضية
  static String getGroundImage() {
    return _currentPair['ground']!;
  }

  // ✅ الحصول على الخلفية الحالية
  static String get currentBackground => _currentPair['background']!;

  // ✅ ضبط سرعة الخلفية
  static void setBackgroundSpeed(double speed) {
    _backgroundSpeed = speed;
  }

  // ✅ ضبط سرعة الأرضية
  static void setGroundSpeed(double speed) {
    _groundSpeed = speed;
  }

  // ✅ الحصول على مضاعف الحركة حسب نوع الأرضية
  static double getGroundMovementMultiplier() {
    final groundImage = _currentPair['ground'] ?? '';

    // إعدادات سرعة مختلفة حسب نوع الأرضية
    if (groundImage.contains('city')) return 1.0;
    if (groundImage.contains('desert')) return 0.9;
    if (groundImage.contains('forest')) return 0.8;
    if (groundImage.contains('snow')) return 1.1;
    if (groundImage.contains('water') || groundImage.contains('ocean')) return 1.2;

    return 1.0;
  }

  // ✅ الحصول على احتكاك الأرضية
  static double getGroundFriction() {
    final groundImage = _currentPair['ground'] ?? '';

    // إعدادات احتكاك مختلفة حسب نوع الأرضية
    if (groundImage.contains('ice') || groundImage.contains('snow')) return 0.85;
    if (groundImage.contains('sand') || groundImage.contains('desert')) return 0.92;
    if (groundImage.contains('mud') || groundImage.contains('forest')) return 0.95;

    return 0.98;
  }

  // ✅ الحصول على الجاذبية المعدلة
  static double getAdjustedGravity() {
    final groundImage = _currentPair['ground'] ?? '';

    // إعدادات جاذبية مختلفة حسب نوع الأرضية
    if (groundImage.contains('space')) return 0.0009;
    if (groundImage.contains('water') || groundImage.contains('ocean')) return 0.0012;

    return 0.0018;
  }

  // ✅ إعادة تعيين الإزاحات
  static void resetOffsets() {
    _backgroundOffset = 0.0;
    _groundOffset = 0.0;
  }
}

/// ---------------- EVENTS ENUM ----------------
enum GroundChangeEvent {
  newLevel,
  bossFight,
  levelComplete,
}

/// ---------------- BACKGROUND MANAGER ----------------
class BackgroundManager {
  List<BackgroundElement> elements = [];
  final Random random = Random();

  // ✅ نظام تحريك الخلفية والأرضية معاً
  void initialize() {
    elements.clear();

    // ✅ تهيئة نظام الأرضيات والخلفيات
    GroundSystem.initialize();

    // إنشاء عناصر خلفية متنوعة بمواقع منظمة
    for (int i = 0; i < 4; i++) _createElement(BackgroundElementType.cloud, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.mountain, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.bird, true);
    for (int i = 0; i < 3; i++) _createElement(BackgroundElementType.tree, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.building, true);
    for (int i = 0; i < 2; i++) _createElement(BackgroundElementType.star, true);
  }

  void update() {
    // ✅ تحديث نظام الخلفية والأرضية (سيحرك كلاهما معاً)
    GroundSystem.update(_getGameTime());

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
        speed = 0.001 + random.nextDouble() * 0.002; // سرعة بطيئة للغيوم
        size = 30 + random.nextDouble() * 15; // حجم مناسب للشاشات الصغيرة
        color = Colors.white.withOpacity(0.9);
        icon = Icons.cloud;
        break;

      case BackgroundElementType.tree:
        yPosition = 0.72;
        speed = 0.006 + random.nextDouble() * 0.004; // سرعة متوسطة للأشجار
        size = 40 + random.nextDouble() * 20; // حجم مناسب
        color = Colors.green.shade800;
        icon = Icons.park;
        break;

      case BackgroundElementType.building:
        yPosition = 0.65;
        speed = 0.004 + random.nextDouble() * 0.002; // سرعة بطيئة للمباني
        size = 40 + random.nextDouble() * 20;
        color = Colors.grey.shade700;
        icon = Icons.sunny;
        break;

      case BackgroundElementType.mountain:
        yPosition = 0.55;
        speed = 0.0008 + random.nextDouble() * 0.001; // سرعة بطيئة جداً للجبال
        size = 50 + random.nextDouble() * 25; // حجم مناسب
        color = Colors.amber;
        icon = Icons.mood_rounded;
        break;

      case BackgroundElementType.bird:
        yPosition = 0.3 + random.nextDouble() * 0.3;
        speed = 0.008 + random.nextDouble() * 0.005; // سرعة متوسطة للطيور
        size = 15 + random.nextDouble() * 6; // حجم صغير مناسب
        color = Colors.black.withOpacity(0.8);
        icon = Icons.flight;
        break;

      case BackgroundElementType.star:
        yPosition = 0.05 + random.nextDouble() * 0.15;
        speed = 0.0008 + random.nextDouble() * 0.001; // سرعة بطيئة للنجوم
        size = 5 + random.nextDouble() * 4; // حجم صغير
        color = Colors.yellow.withOpacity(0.95);
        icon = Icons.star;
        break;

      default:
        yPosition = 0.5;
        speed = 0.005;
        size = 25;
        color = Colors.grey;
        icon = Icons.circle;
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

  // ✅ الحصول على معلومات الخلفية والأرضية الحالية
  Map<String, dynamic> getCurrentGroundInfo() {
    return GroundSystem.getCurrentGroundInfo();
  }

  // ✅ الحصول على الخلفية الحالية
  String get currentBackground => GroundSystem.currentBackground;

  // ✅ الحصول على إزاحة الخلفية
  double get currentBackgroundOffset => GroundSystem.backgroundOffset;

  // ✅ الحصول على إزاحة الأرضية
  double get currentGroundOffset => GroundSystem.groundOffset;

  // ✅ الحصول على ارتفاع الخلفية
  double get backgroundHeight => GroundSystem.backgroundHeight;

  // ✅ الحصول على ارتفاع الأرضية
  double get groundHeight => GroundSystem.groundHeight;

  // ✅ تغيير الخلفية والأرضية لحدث معين
  void changeGroundForEvent(GroundChangeEvent event) {
    switch (event) {
      case GroundChangeEvent.newLevel:
      // سيتم تعيين الزوج الجديد من خلال GameEngine
        print('🔄 تغيير الخلفية والأرضية لبداية مستوى جديد');
        break;
      case GroundChangeEvent.bossFight:
        _setBossPair();
        print('🔥 تغيير الخلفية والأرضية لمعركة الزعيم');
        break;
      case GroundChangeEvent.levelComplete:
        _setVictoryPair();
        print('🎉 تغيير الخلفية والأرضية لانتهاء المستوى');
        break;
    }
  }

  // ✅ خلفية وأرضية خاصة بالزعيم
  void _setBossPair() {
    GroundSystem.setCurrentPair({
      'background': 'assets/images/backgrounds/night.png',
      'ground': 'assets/images/ground/boss_ground.png',
    });

    // زيادة السرعة قليلاً لمعركة الزعيم
    GroundSystem.setBackgroundSpeed(0.002);
    GroundSystem.setGroundSpeed(0.004);
  }

  // ✅ خلفية وأرضية خاصة بالنصر
  void _setVictoryPair() {
    GroundSystem.setCurrentPair({
      'background': 'assets/images/backgrounds/rainbow.png',
      'ground': 'assets/images/ground/victory_ground.png',
    });

    // تقليل السرعة للنصر
    GroundSystem.setBackgroundSpeed(0.001);
    GroundSystem.setGroundSpeed(0.002);
  }

  // ✅ تغيير الخلفية والأرضية يدوياً
  void changeGroundManually() {
    // يمكن إضافة منطق للتغيير اليدوي إذا لزم الأمر
    print('🎮 تغيير الخلفية والأرضية بطلب اللاعب');
  }

  // ✅ ضبط سرعة الخلفية
  void setBackgroundSpeed(double speed) {
    GroundSystem.setBackgroundSpeed(speed);
  }

  // ✅ ضبط سرعة الأرضية
  void setGroundSpeed(double speed) {
    GroundSystem.setGroundSpeed(speed);
  }

  double _getGameTime() {
    return DateTime.now().millisecondsSinceEpoch / 1000.0;
  }

  void dispose() {
    elements.clear();
  }
}