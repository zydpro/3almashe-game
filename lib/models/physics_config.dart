class PhysicsConfig {
  // === إعدادات الفيزياء للحركة الواقعية ===
  static const double realisticGravity = 0.002;
  static const double realisticJumpPower = -0.038;
  static const double characterWeight = 1.5;
  static const double groundFriction = 0.98;

  // === إعدادات القفز المحسنة ===
  static const double maxJumpHeight = 0.25;
  static const double minJumpHeight = 0.15;
  static const double jumpVelocityDecay = 0.95;

  // === إعدادات الحركة الأفقية ===
  static const double runSpeed = 0.015;
  static const double acceleration = 0.001;
  static const double deceleration = 0.002;

  // === إعدادات الانحناء ===
  static const double duckDuration = 0.5;
  static const double duckHeightMultiplier = 0.6;

  // === إعدادات التصادم ===
  static const double collisionTolerance = 0.02;
  static const double groundLevel = 0.75;

  // === إعدادات العوائق ===
  static const double obstacleBaseSpeed = 0.015;
  static const double obstacleSpeedIncrement = 0.001;
  static const double maxObstacleSpeed = 0.03;

  // === مساعدات فيزيائية ===
  static double calculateJumpForce(double weight) {
    return realisticJumpPower * weight;
  }

  static double calculateFallSpeed(double weight) {
    return realisticGravity * weight;
  }

  static bool isOnGround(double y, double height) {
    return (y - (groundLevel - height)).abs() < collisionTolerance;
  }
}