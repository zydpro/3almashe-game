import 'package:flutter/material.dart';
import '../models/level_data.dart';
import '../services/game_data_service.dart';
import 'game_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  List<LevelData> levels = [];
  bool isLoading = true;
  int unlockedLevelsCount = 0;
  int highScore = 0;
  int totalCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // ✅ تحميل جميع البيانات بشكل متوازي
    final results = await Future.wait([
      LevelData.getAllLevels(),
      GameDataService.getUnlockedLevels(),
      GameDataService.getHighScore(),
      GameDataService.getTotalCoins(),
    ]);

    setState(() {
      levels = results[0] as List<LevelData>;
      unlockedLevelsCount = (results[1] as List<int>).length;
      highScore = results[2] as int;
      totalCoins = results[3] as int;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E4057),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'جاري تحميل المراحل...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E4057), // Dark blue-grey
              Color(0xFF048A81), // Teal
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'اختر المرحلة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 50), // Balance the back button
                  ],
                ),
              ),

              // Player stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'أعلى نقاط',
                      highScore.toString(),
                      Icons.star,
                      Colors.yellow,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem(
                      'العملات',
                      totalCoins.toString(),
                      Icons.monetization_on,
                      Colors.amber,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem(
                      'المراحل المفتوحة',
                      '$unlockedLevelsCount/100', // ✅ تم التصحيح
                      Icons.lock_open,
                      Colors.green,
                    ),
                  ],
                ),
              ),

              // Levels grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      return _buildLevelCard(levels[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(LevelData level) {
    return GestureDetector(
      onTap: level.isUnlocked ? () => _startLevel(level) : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: level.isUnlocked
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              level.backgroundColor,
              level.backgroundColor.withOpacity(0.7),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Level number
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: level.isUnlocked ? Colors.white : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: level.isUnlocked
                      ? Text(
                    level.levelNumber.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: level.backgroundColor,
                    ),
                  )
                      : const Icon(
                    Icons.lock,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Level name
              Text(
                level.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),

              // Level description
              Text(
                level.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Target score
              if (level.isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'الهدف: ${level.targetScore}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startLevel(LevelData level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelData: level),
      ),
    );
  }
}