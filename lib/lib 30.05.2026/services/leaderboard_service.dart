import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardService {
  static const String _leaderboardKey = 'leaderboard';

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final leaderboardData = prefs.getStringList(_leaderboardKey) ?? [];

    return leaderboardData.map((entry) {
      final parts = entry.split('|');
      return LeaderboardEntry(
        playerName: parts[0],
        score: int.parse(parts[1]),
        date: DateTime.parse(parts[2]),
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  static Future<void> addScore(String playerName, int score) async {
    final leaderboard = await getLeaderboard();
    final newEntry = LeaderboardEntry(
      playerName: playerName,
      score: score,
      date: DateTime.now(),
    );

    leaderboard.add(newEntry);
    leaderboard.sort((a, b) => b.score.compareTo(a.score));

    // حفظ أفضل 50 نتيجة فقط
    final topScores = leaderboard.take(50).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _leaderboardKey,
      topScores.map((entry) =>
      '${entry.playerName}|${entry.score}|${entry.date.toIso8601String()}'
      ).toList(),
    );
  }
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime date;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.date,
  });
}