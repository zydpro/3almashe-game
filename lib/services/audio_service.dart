import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _effectsPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // إعداد وضع التشغيل للاعب المؤثرات
      await _effectsPlayer.setReleaseMode(ReleaseMode.release);

      // إعداد وضع التشغيل للاعب الموسيقى
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);

      _isInitialized = true;
      debugPrint('✅ AudioService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AudioService: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    if (!_musicEnabled || !_isInitialized) return;

    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(AssetSource('sounds/music/background_music.mp3'));
      debugPrint('🎵 Background music started');
    } catch (e) {
      debugPrint('❌ Error playing background music: $e');
    }
  }

  Future<void> playBossMusic() async {
    if (!_musicEnabled || !_isInitialized) return;

    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(AssetSource('sounds/music/boss_music.mp3'));
      debugPrint('🎵 Boss music started');
    } catch (e) {
      debugPrint('❌ Error playing boss music: $e');
      // استخدام الموسيقى الافتراضية كبديل
      await playBackgroundMusic();
    }
  }

  Future<void> stopBackgroundMusic() async {
    if (!_isInitialized) return;

    try {
      await _backgroundPlayer.stop();
      debugPrint('⏹️ Background music stopped');
    } catch (e) {
      debugPrint('❌ Error stopping background music: $e');
    }
  }

  Future<void> playJumpSound() async {
    await _playSoundEffect('sounds/effects/jump.wav');
  }

  Future<void> playCoinSound() async {
    await _playSoundEffect('sounds/effects/coin.wav');
  }

  Future<void> playGameOverSound() async {
    await _playSoundEffect('sounds/effects/game_over.wav');
  }

  Future<void> playLevelCompleteSound() async {
    await _playSoundEffect('sounds/effects/level_complete.wav');
  }

  Future<void> playEnemyDieSound() async {
    await _playSoundEffect('sounds/effects/enemy_die.wav');
  }

  Future<void> playBossHitSound() async {
    await _playSoundEffect('sounds/effects/boss_hit.wav');
  }

  Future<void> playPackageThrowSound() async {
    await _playSoundEffect('sounds/effects/package_throw.wav');
  }

  Future<void> playBossDefeatSound() async {
    await _playSoundEffect('sounds/effects/boss_defeat.wav');
  }

  Future<void> playEnemyHitSound() async {
    await _playSoundEffect('sounds/effects/enemy_hit.wav');
  }

  Future<void> _playSoundEffect(String soundPath) async {
    if (!_soundEnabled || !_isInitialized) return;

    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource(soundPath));
    } catch (e) {
      debugPrint('❌ Error playing sound effect $soundPath: $e');
    }
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _effectsPlayer.stop();
    }
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
    } else if (_isInitialized) {
      playBackgroundMusic();
    }
  }

  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;

  Future<void> dispose() async {
    try {
      await _effectsPlayer.dispose();
      await _backgroundPlayer.dispose();
      _isInitialized = false;
      debugPrint('🗑️ AudioService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing AudioService: $e');
    }
  }
}