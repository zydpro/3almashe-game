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
}

enum CharacterState {
  running,
  jumping,
  ducking,
  attacking,
  dead,
}