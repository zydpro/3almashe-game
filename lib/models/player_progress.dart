class PlayerProgress {
  int level;
  int xp;
  int totalXp;
  int coins;
  int gamesPlayed;
  int totalScore;
  DateTime lastPlayed;

  PlayerProgress({
    this.level = 1,
    this.xp = 0,
    this.totalXp = 0,
    this.coins = 0,
    this.gamesPlayed = 0,
    this.totalScore = 0,
    required this.lastPlayed,
  });

  int get xpToNextLevel => level * 1000;
  double get progress => xp / xpToNextLevel;

  void addXp(int earnedXp) {
    xp += earnedXp;
    totalXp += earnedXp;

    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      // مكافأة مستوى جديد
      coins += level * 50;
    }
  }

  void addCoins(int earnedCoins) {
    coins += earnedCoins;
  }
}