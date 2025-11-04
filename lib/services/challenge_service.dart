import 'package:shared_preferences/shared_preferences.dart';

class ChallengeService {
  static const String _challengesKey = 'daily_challenges';
  static const String _lastUpdateKey = 'last_challenge_update';

  static Future<List<DailyChallenge>> getTodaysChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = DateTime.parse(prefs.getString(_lastUpdateKey) ?? DateTime(2000).toIso8601String());
    final now = DateTime.now();

    // إذا كان اليوم مختلف، تجديد التحديات
    if (lastUpdate.day != now.day || lastUpdate.month != now.month || lastUpdate.year != now.year) {
      await _resetChallenges();
      await prefs.setString(_lastUpdateKey, now.toIso8601String());
    }

    final challengesData = prefs.getStringList(_challengesKey) ?? [];
    return challengesData.map((data) => DailyChallenge.fromJson(data)).toList();
  }

  static Future<void> updateChallengeProgress(String challengeId, int progress) async {
    final challenges = await getTodaysChallenges();
    final updatedChallenges = challenges.map((challenge) {
      if (challenge.id == challengeId) {
        return challenge.copyWith(progress: challenge.progress + progress);
      }
      return challenge;
    }).toList();

    await _saveChallenges(updatedChallenges);
  }

  static Future<void> _resetChallenges() async {
    final challenges = [
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
    ];

    await _saveChallenges(challenges);
  }

  static Future<void> _saveChallenges(List<DailyChallenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _challengesKey,
      challenges.map((challenge) => challenge.toJson()).toList(),
    );
  }
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  final int reward;
  final int progress;
  final ChallengeType type;
  final bool isCompleted;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    required this.type,
    this.progress = 0,
    this.isCompleted = false,
  });

  DailyChallenge copyWith({
    int? progress,
    bool? isCompleted,
  }) {
    return DailyChallenge(
      id: id,
      title: title,
      description: description,
      target: target,
      reward: reward,
      type: type,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  String toJson() {
    return '$id|$title|$description|$target|$reward|$progress|${type.name}|$isCompleted';
  }

  factory DailyChallenge.fromJson(String data) {
    final parts = data.split('|');
    return DailyChallenge(
      id: parts[0],
      title: parts[1],
      description: parts[2],
      target: int.parse(parts[3]),
      reward: int.parse(parts[4]),
      progress: int.parse(parts[5]),
      type: ChallengeType.values.firstWhere((e) => e.name == parts[6]),
      isCompleted: parts[7] == 'true',
    );
  }
}

enum ChallengeType {
  score,
  jumps,
  ducks,
  coins,
  obstacles,
  powerUps,
}