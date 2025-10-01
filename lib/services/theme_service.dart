import 'package:flutter/material.dart';

class ThemeService {
  static final List<GameTheme> themes = [
    GameTheme(
      name: 'النهار',
      key: 'day',
      backgroundColor: const Color(0xFF87CEEB),
      groundColor: const Color(0xFF8B4513),
      obstacleColor: Colors.green,
      music: 'sounds/background_music.mp3', // استخدام الملف المتاح
    ),
    GameTheme(
      name: 'الليل',
      key: 'night',
      backgroundColor: const Color(0xFF191970),
      groundColor: const Color(0xFF2F4F4F),
      obstacleColor: Colors.blue,
      music: 'sounds/night_music.mp3',
    ),
    GameTheme(
      name: 'الغروب',
      key: 'sunset',
      backgroundColor: const Color(0xFFFFA500),
      groundColor: const Color(0xFF8B0000),
      obstacleColor: Colors.orange,
      music: 'sounds/sunset_music.mp3',
    ),
  ];

  static GameTheme getThemeForLevel(int level) {
    return themes[level % themes.length];
  }

  // دالة مساعدة للحصول على المظهر بالمفتاح
  static GameTheme getThemeByKey(String key) {
    return themes.firstWhere(
          (theme) => theme.key == key,
      orElse: () => themes.first,
    );
  }
}

class GameTheme {
  final String name;
  final String key; // مفتاح للمظهر لتسهيل التعرف عليه
  final Color backgroundColor;
  final Color groundColor;
  final Color obstacleColor;
  final String music;

  const GameTheme({
    required this.name,
    required this.key,
    required this.backgroundColor,
    required this.groundColor,
    required this.obstacleColor,
    required this.music,
  });
}