// lib/models/enums.dart
enum ObstacleType {
  groundLong,
  groundShort,
  groundWide,
  skyLong,
  skyShort,
  skyWide,
  comboSequence,
  enemy,
  flyingEnemy,
  boss,
}

enum PowerUpType {
  points,
  shield,
  slowMotion,
  doublePoints,
  health,
  speedBoost,
  slowEnemies,
  coin,
  slowCharacter
}

enum CharacterState {
  running,
  jumping,
  ducking,
  attacking,
  dead,
}

enum GameState {
  menu,
  playing,
  paused,
  gameOver,
  levelComplete,
  bossFight
}

class Position {
  final double x;
  final double y;

  const Position({required this.x, required this.y});
}