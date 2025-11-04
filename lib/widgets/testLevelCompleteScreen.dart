import 'package:almashe_game/models/level_data.dart';
import 'package:flutter/material.dart';

import '../screens/level_complete_screen.dart';

class TestLevelCompleteScreen extends StatelessWidget {
  const TestLevelCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ استخدام نظام المفاتيز كما في الكود الأصلي
    final testLevelData = LevelData(
      levelNumber: 1,
      nameKey: 'levelName1',
      descriptionKey: 'levelDesc1',
      targetScore: 1000,
      obstacleSpeed: 0.02,
      obstacleFrequency: 1000,
      backgroundColor: Colors.blue,
      isUnlocked: true,
      bossHealth: 100,
      bossAttackSpeed: 2.0,
      backgroundImage: 'assets/images/backgrounds/city_background.png',
    );

    return LevelCompleteScreen(
      score: 1500,
      levelData: testLevelData,
      nextLevel: null,
      timeSpent: 65,
    );
  }
}