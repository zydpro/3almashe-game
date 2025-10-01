class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  final int reward;
  int progress;
  bool isCompleted;
  final ChallengeType type;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    required this.type,
    this.progress = 0,
    this.isCompleted = false,
  });
}

enum ChallengeType {
  score,
  jumps,
  ducks,
  coins,
  obstacles,
  powerUps,
}

class ChallengeManager {
  static List<DailyChallenge> getTodaysChallenges() {
    return [
      DailyChallenge(
        id: '1',
        title: 'قفز 50 مرة',
        description: 'اقفز 50 مرة خلال جلسة واحدة',
        target: 50,
        reward: 100,
        type: ChallengeType.jumps,
      ),
      DailyChallenge(
        id: '2',
        title: 'اجمع 20 عملة',
        description: 'اجمع 20 عملة ذهبية',
        target: 20,
        reward: 150,
        type: ChallengeType.coins,
      ),
      DailyChallenge(
        id: '3',
        title: 'تجنب 30 عقبة',
        description: 'تجنب 30 عقبة بدون اصطدام',
        target: 30,
        reward: 200,
        type: ChallengeType.obstacles,
      ),
      DailyChallenge(
        id: '4',
        title: 'احصل على 5 باور أب',
        description: 'اجمع 5 باور أب مختلفة',
        target: 5,
        reward: 120,
        type: ChallengeType.powerUps,
      ),
    ];
  }
}