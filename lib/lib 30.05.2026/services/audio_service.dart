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
  bool _isBackgroundPlaying = false;

  // Cache للأصوات المستخدمة بكثرة
  final Map<String, bool> _loadedSounds = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // إعداد وضع التشغيل للاعب المؤثرات
      await _effectsPlayer.setReleaseMode(ReleaseMode.release);

      // إعداد وضع التشغيل للاعب الموسيقى
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);

      // إعداد حجم الصوت
      await _backgroundPlayer.setVolume(0.7);
      await _effectsPlayer.setVolume(0.8);

      _isInitialized = true;
      debugPrint('✅ AudioService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AudioService: $e');
    }
  }

  Future<void> playBrickBreakSound() async {
    await _playSoundEffect('sounds/effects/brick_break.wav');
  }

  Future<void> playBackgroundMusic() async {
    if (!_musicEnabled || !_isInitialized) return;

    try {
      // إذا الموسيقى شغالة مسبقاً، ما نعيد تشغيلها
      if (_isBackgroundPlaying) return;

      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(AssetSource('sounds/music/background_music.mp3'));
      _isBackgroundPlaying = true;
      debugPrint('🎵 Background music started');
    } catch (e) {
      debugPrint('❌ Error playing background music: $e');
      _isBackgroundPlaying = false;
    }
  }

  Future<void> playBossMusic() async {
    if (!_musicEnabled || !_isInitialized) return;

    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(AssetSource('sounds/music/boss_music.mp3'));
      _isBackgroundPlaying = true;
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
      await _backgroundPlayer.pause();
      _isBackgroundPlaying = false;
      debugPrint('⏹️ Background music paused');
    } catch (e) {
      debugPrint('❌ Error stopping background music: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_musicEnabled || !_isInitialized || _isBackgroundPlaying) return;

    try {
      await _backgroundPlayer.resume();
      _isBackgroundPlaying = true;
      debugPrint('▶️ Background music resumed');
    } catch (e) {
      debugPrint('❌ Error resuming background music: $e');
    }
  }

  Future<void> playWarriorShotSound() async {
    await _playSoundEffect('sounds/attacks/warrior_shot.wav');
  }

  Future<void> playSnowballSound() async {
    await _playSoundEffect('sounds/attacks/snowball_throw.wav');
  }

  Future<void> playFireballSound() async {
    await _playSoundEffect('sounds/attacks/fireball_throw.wav');
  }

  Future<void> playLightningSound() async {
    await _playSoundEffect('sounds/attacks/lightning_strike.wav');
  }

  Future<void> playFalconSound() async {
    await _playSoundEffect('sounds/attacks/falcon_call.wav');
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

  Future<void> playPowerUpSound() async {
    await _playSoundEffect('sounds/effects/power_up.wav');
  }

  Future<void> playShieldActivateSound() async {
    await _playSoundEffect('sounds/effects/shield_activate.wav');
  }

  Future<void> playShieldDeactivateSound() async {
    await _playSoundEffect('sounds/effects/shield_deactivate.wav');
  }

  Future<void> playComboSound() async {
    await _playSoundEffect('sounds/effects/combo.wav');
  }

  Future<void> playHealthPickupSound() async {
    await _playSoundEffect('sounds/effects/health_pickup.wav');
  }

  Future<void> playSlowMotionSound() async {
    await _playSoundEffect('sounds/effects/slow_motion.wav');
  }

  Future<void> playDoublePointsSound() async {
    await _playSoundEffect('sounds/effects/double_points.wav');
  }

  Future<void> playHammerSound() async {
    await _playSoundEffect('sounds/attacks/hammer_throw.wav');
  }

  Future<void> playPowSound() async {
    await _playSoundEffect('sounds/attacks/pow_sound.wav');
  }

  Future<void> playZombieSpitSound() async {
    await _playSoundEffect('sounds/attacks/zombie_spit.wav');
  }

  Future<void> playHackSound() async {
    await _playSoundEffect('sounds/attacks/hack_wave.wav');
  }

  Future<void> playRainbowSound() async {
    await _playSoundEffect('sounds/attacks/rainbow_beam.wav');
  }

  Future<void> playMudSound() async {
    await _playSoundEffect('sounds/attacks/mud_throw.wav');
  }

  Future<void> _preloadSound(String path) async {
    if (_loadedSounds.containsKey(path)) return;

    try {
      await _effectsPlayer.setSource(AssetSource(path));
      _loadedSounds[path] = true;
      debugPrint('🔊 Preloaded sound: $path');
    } catch (e) {
      debugPrint('❌ Error preloading sound $path: $e');
    }
  }

  Future<void> _playSoundEffect(String soundPath) async {
    if (!_soundEnabled || !_isInitialized) return;

    try {
      // Preload الصوت أولاً إذا لم يكن محمل
      await _preloadSound(soundPath);

      // تشغيل الصوت
      await _effectsPlayer.play(AssetSource(soundPath));
      debugPrint('🔊 Playing sound: $soundPath');
    } catch (e) {
      debugPrint('❌ Error playing sound effect $soundPath: $e');
    }
  }

  Future<void> preloadAllSounds() async {
    if (!_isInitialized) return;

    try {
      final soundsToPreload = [
        // الأصوات الأساسية
        'sounds/effects/jump.wav',
        'sounds/effects/coin.wav',
        'sounds/effects/game_over.wav',
        'sounds/effects/level_complete.wav',
        'sounds/effects/enemy_die.wav',
        'sounds/effects/boss_hit.wav',
        'sounds/effects/package_throw.wav',
        'sounds/effects/boss_defeat.wav',
        'sounds/effects/enemy_hit.wav',
        'sounds/effects/power_up.wav',
        'sounds/effects/shield_activate.wav',
        'sounds/effects/shield_deactivate.wav',
        'sounds/effects/combo.wav',
        'sounds/effects/health_pickup.wav',
        'sounds/effects/slow_motion.wav',
        'sounds/effects/double_points.wav',
        'sounds/effects/brick_break.wav',

        // ✅ إضافة أصوات الهجمات الجديدة
        'sounds/attacks/warrior_shot.wav',
        'sounds/attacks/snowball_throw.wav',
        'sounds/attacks/fireball_throw.wav',
        'sounds/attacks/lightning_strike.wav',
        'sounds/attacks/falcon_call.wav',
        'sounds/attacks/hammer_throw.wav',
        'sounds/attacks/pow_sound.wav',
        'sounds/attacks/zombie_spit.wav',
        'sounds/attacks/hack_wave.wav',
        'sounds/attacks/rainbow_beam.wav',
        'sounds/attacks/mud_throw.wav',
      ];

      for (final sound in soundsToPreload) {
        await _preloadSound(sound);
      }

      debugPrint('✅ All sounds preloaded successfully');
    } catch (e) {
      debugPrint('❌ Error preloading all sounds: $e');
    }
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _effectsPlayer.stop();
    }
    debugPrint('🔊 Sound enabled: $enabled');
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
    } else if (_isInitialized && !_isBackgroundPlaying) {
      playBackgroundMusic();
    }
    debugPrint('🎵 Music enabled: $enabled');
  }

  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;
  bool get isBackgroundPlaying => _isBackgroundPlaying;

  Future<void> setEffectsVolume(double volume) async {
    if (!_isInitialized) return;

    try {
      await _effectsPlayer.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('🔊 Effects volume set to: $volume');
    } catch (e) {
      debugPrint('❌ Error setting effects volume: $e');
    }
  }

  Future<void> setMusicVolume(double volume) async {
    if (!_isInitialized) return;

    try {
      await _backgroundPlayer.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('🎵 Music volume set to: $volume');
    } catch (e) {
      debugPrint('❌ Error setting music volume: $e');
    }
  }

  Future<void> pauseAllSounds() async {
    if (!_isInitialized) return;

    try {
      await _effectsPlayer.pause();
      await _backgroundPlayer.pause();
      // debugPrint('⏸️ All sounds paused');
    } catch (e) {
      // debugPrint('❌ Error pausing all sounds: $e');
    }
  }

  Future<void> resumeAllSounds() async {
    if (!_isInitialized) return;

    try {
      if (_musicEnabled && _isBackgroundPlaying) {
        await _backgroundPlayer.resume();
      }
      await _effectsPlayer.resume();
      // debugPrint('▶️ All sounds resumed');
    } catch (e) {
      // debugPrint('❌ Error resuming all sounds: $e');
    }
  }

  Future<void> stopAllSounds() async {
    if (!_isInitialized) return;

    try {
      await _effectsPlayer.stop();
      await _backgroundPlayer.stop();
      _isBackgroundPlaying = false;
      // debugPrint('⏹️ All sounds stopped');
    } catch (e) {
      // debugPrint('❌ Error stopping all sounds: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _effectsPlayer.dispose();
      await _backgroundPlayer.dispose();
      _isInitialized = false;
      _isBackgroundPlaying = false;
      _loadedSounds.clear();
      debugPrint('🗑️ AudioService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing AudioService: $e');
    }
  }

  // دوال للحصول على حالة الصوت
  Map<String, dynamic> getAudioStatus() {
    return {
      'soundEnabled': _soundEnabled,
      'musicEnabled': _musicEnabled,
      'isInitialized': _isInitialized,
      'isBackgroundPlaying': _isBackgroundPlaying,
      'loadedSoundsCount': _loadedSounds.length,
    };
  }

  // دالة لإعادة تعيين خدمة الصوت
  Future<void> reset() async {
    await dispose();
    await initialize();
    debugPrint('🔄 AudioService reset');
  }
}