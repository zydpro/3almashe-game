// import '../models/obstacle.dart';
// import '../models/power_up_system.dart';
// import '../models/Boss.dart';
//
// // ملف حفظ حالة اللعبة عند الضغط على استمرار يشاهد اعلان ويكمل اللعبة من حيث خسر
// class GameStateRestore {
//   final int score;
//   final int level;
//   final double characterX;
//   final double characterY;
//   final int characterHealth;
//   final int characterLives;
//   final List<Obstacle> obstacles;
//   final List<Obstacle> enemies;
//   final List<PowerUp> powerUps;
//   final List<Obstacle> platforms;
//   final double gameTime;
//   final bool isBossFight;
//   final Boss? currentBoss;
//   final bool hasShield;
//   final bool isSlowMotion;
//   final bool isDoublePoints;
//
//   GameStateRestore({
//     required this.score,
//     required this.level,
//     required this.characterX,
//     required this.characterY,
//     required this.characterHealth,
//     required this.characterLives,
//     required this.obstacles,
//     required this.enemies,
//     required this.powerUps,
//     required this.platforms,
//     required this.gameTime,
//     required this.isBossFight,
//     required this.currentBoss,
//     required this.hasShield,
//     required this.isSlowMotion,
//     required this.isDoublePoints,
//   });
//
//   // دالة لتحويل النموذج إلى Map
//   Map<String, dynamic> toMap() {
//     return {
//       'score': score,
//       'level': level,
//       'characterX': characterX,
//       'characterY': characterY,
//       'characterHealth': characterHealth,
//       'characterLives': characterLives,
//       'gameTime': gameTime,
//       'isBossFight': isBossFight,
//       'hasShield': hasShield,
//       'isSlowMotion': isSlowMotion,
//       'isDoublePoints': isDoublePoints,
//       // إضافة العناصر الأخرى التي تحتاجها
//       'obstacles': obstacles.map((obs) => obs.toMap()).toList(),
//       'enemies': enemies.map((enemy) => enemy.toMap()).toList(),
//       'powerUps': powerUps.map((powerUp) => powerUp.toMap()).toList(),
//       'platforms': platforms.map((platform) => platform.toMap()).toList(),
//     };
//   }
//
//   // دالة لإنشاء النموذج من Map
//   factory GameStateRestore.fromMap(Map<String, dynamic> map) {
//     return GameStateRestore(
//       score: map['score'] ?? 0,
//       level: map['level'] ?? 1,
//       characterX: map['characterX'] ?? 0.2,
//       characterY: map['characterY'] ?? 0.7,
//       characterHealth: map['characterHealth'] ?? 100,
//       characterLives: map['characterLives'] ?? 3,
//       obstacles: (map['obstacles'] as List?)?.map((obs) => Obstacle.fromMap(obs)).toList() ?? [],
//       enemies: (map['enemies'] as List?)?.map((enemy) => Obstacle.fromMap(enemy)).toList() ?? [],
//       powerUps: (map['powerUps'] as List?)?.map((powerUp) => PowerUp.fromMap(powerUp)).toList() ?? [],
//       platforms: (map['platforms'] as List?)?.map((platform) => Obstacle.fromMap(platform)).toList() ?? [],
//       gameTime: map['gameTime'] ?? 0.0,
//       isBossFight: map['isBossFight'] ?? false,
//       currentBoss: map['currentBoss'] != null ? Boss.fromMap(map['currentBoss']) : null,
//       hasShield: map['hasShield'] ?? false,
//       isSlowMotion: map['isSlowMotion'] ?? false,
//       isDoublePoints: map['isDoublePoints'] ?? false,
//     );
//   }
//
//   // دالة لإضافة عناصر إلى القوائم
//   GameStateRestore copyWith({
//     int? score,
//     int? level,
//     double? characterX,
//     double? characterY,
//     int? characterHealth,
//     int? characterLives,
//     List<Obstacle>? obstacles,
//     List<Obstacle>? enemies,
//     List<PowerUp>? powerUps,
//     List<Obstacle>? platforms,
//     double? gameTime,
//     bool? isBossFight,
//     Boss? currentBoss,
//     bool? hasShield,
//     bool? isSlowMotion,
//     bool? isDoublePoints,
//   }) {
//     return GameStateRestore(
//       score: score ?? this.score,
//       level: level ?? this.level,
//       characterX: characterX ?? this.characterX,
//       characterY: characterY ?? this.characterY,
//       characterHealth: characterHealth ?? this.characterHealth,
//       characterLives: characterLives ?? this.characterLives,
//       obstacles: obstacles ?? this.obstacles,
//       enemies: enemies ?? this.enemies,
//       powerUps: powerUps ?? this.powerUps,
//       platforms: platforms ?? this.platforms,
//       gameTime: gameTime ?? this.gameTime,
//       isBossFight: isBossFight ?? this.isBossFight,
//       currentBoss: currentBoss ?? this.currentBoss,
//       hasShield: hasShield ?? this.hasShield,
//       isSlowMotion: isSlowMotion ?? this.isSlowMotion,
//       isDoublePoints: isDoublePoints ?? this.isDoublePoints,
//     );
//   }
// }