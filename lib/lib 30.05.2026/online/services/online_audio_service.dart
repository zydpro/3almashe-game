import 'package:audioplayers/audioplayers.dart';

class OnlineAudioService {
  static final OnlineAudioService _instance = OnlineAudioService._internal();
  factory OnlineAudioService() => _instance;

  // ✅ استخدام لاعبين منفصلين للموسيقى والتأثيرات
  late AudioPlayer _musicPlayer;
  Map<String, AudioPlayer> _soundPlayers = {};
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;
  bool _isInitialized = false;
  bool _isDisposed = false;

  OnlineAudioService._internal() {
    _initializePlayers();
  }

  // ⭐ أضف هذه الخاصية الجديدة
  bool get isDisposed => _isDisposed;

  // ⭐ أضف هذه الدالة الجديدة
  bool get isInitialized => _isInitialized && !_isDisposed;
  // ✅ تهيئة اللاعبين بشكل آمن
  void _initializePlayers() {
    try {
      if (_isDisposed) return;
      _musicPlayer = AudioPlayer();
      print('✅ Audio players initialized');
    } catch (e) {
      print('⚠️ خطأ في تهيئة مشغلات الصوت: $e');
    }
  }

  // ✅ تهيئة الخدمة (إصدار مبسط)
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      // ✅ استخدام الإعدادات الأساسية فقط
      // ملاحظة: تم إزالة setGlobalAudioContext في الإصدارات الجديدة
      _isInitialized = true;
      print('✅ خدمة الصوت مهيأة بنجاح');
    } catch (e) {
      print('⚠️ خطأ في تهيئة الصوت: $e');
      // الاستمرار حتى مع وجود خطأ
    }
  }

  // ✅ الحصول على لاعب صوت جديد للتأثيرات
  AudioPlayer _getSoundPlayer(String soundId) {
    if (_isDisposed) { // ⭐ تحقق من isDisposed
      throw StateError("Audio service has been disposed");
    }
    // ✅ تنظيف اللاعبين القديمين أولاً
    _cleanupOldPlayers();

    // ✅ استخدام لاعب موجود أو إنشاء جديد
    if (_soundPlayers.containsKey(soundId) &&
        _soundPlayers[soundId]!.state != PlayerState.disposed) {
      return _soundPlayers[soundId]!;
    }

    final player = AudioPlayer();
    _soundPlayers[soundId] = player;
    return player;
  }

  // ✅ تنظيف اللاعبين غير المستخدمين
  void _cleanupOldPlayers() {
    final List<String> toRemove = [];

    _soundPlayers.forEach((soundId, player) {
      if (player.state == PlayerState.disposed ||
          player.state == PlayerState.completed) {
        try {
          player.dispose();
          toRemove.add(soundId);
        } catch (e) {
          // تجاهل الأخطاء أثناء التنظيف
        }
      }
    });

    for (var id in toRemove) {
      _soundPlayers.remove(id);
    }

    // ✅ الحفاظ على عدد معقول من اللاعبين
    if (_soundPlayers.length > 10) {
      final keys = _soundPlayers.keys.toList();
      for (int i = 0; i < keys.length - 5; i++) {
        try {
          _soundPlayers[keys[i]]?.dispose();
          _soundPlayers.remove(keys[i]);
        } catch (e) {
          // تجاهل
        }
      }
    }
  }

// ✅ تشغيل الصوت بشكل آمن
  Future<void> _playSoundSafe(String path) async {
    if (!_isSoundEnabled || path.isEmpty) return;

    try {
      await initialize();

      final soundId = '${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}';
      final player = _getSoundPlayer(soundId);

      await Future.delayed(Duration(milliseconds: 10));

      // ✅ تصحيح المسار بشكل نهائي
      String finalPath = path;

      // 1. إزالة أي 'assets/' زائدة في البداية
      while (finalPath.startsWith('assets/')) {
        finalPath = finalPath.substring(7); // إزالة 'assets/'
      }

      // 2. إزالة أي 'assets/assets/' في أي مكان
      finalPath = finalPath.replaceAll('assets/assets/', 'assets/');

      // 3. إضافة 'assets/' في البداية مرة واحدة فقط
      finalPath = 'assets/$finalPath';

      // 4. إزالة أي تكرار ناتج عن الخطوات السابقة
      finalPath = finalPath.replaceAll('//', '/');

      // 5. التأكد النهائي من عدم وجود 'assets/assets/'
      finalPath = finalPath.replaceAll('assets/assets/', 'assets/');

      print('🔊 تشغيل الصوت: $finalPath');

      if (player.state == PlayerState.disposed) {
        return;
      }

      await player.play(AssetSource(finalPath));

      // تنظيف اللاعب بعد انتهاء الصوت
      player.onPlayerComplete.listen((_) {
        Future.delayed(Duration(milliseconds: 100), () {
          try {
            player.dispose();
            _soundPlayers.removeWhere((key, value) => value == player);
          } catch (e) {
            // تجاهل
          }
        });
      });

    } catch (e) {
      print('❌ خطأ في تشغيل الصوت $path: $e');
    }
  }

  // ✅ تشغيل الموسيقى
  Future<void> _playMusicSafe(String path) async {
    if (!_isMusicEnabled || path.isEmpty) return;

    try {
      await initialize();

      // ✅ إيقاف الموسيقى السابقة فقط إذا كانت تعمل
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.stop();
      }

      // ✅ تأخير بسيط قبل التشغيل
      await Future.delayed(Duration(milliseconds: 50));

      // ✅ تشغيل الموسيقى
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource(path));

      print('🎵 تشغيل الموسيقى: $path');

    } catch (e) {
      print('⚠️ خطأ في تشغيل الموسيقى $path: $e');
    }
  }

  // ✅ أصوات الضربات
  Future<void> playLightAttackSound() async {
    await _playSoundSafe('sounds/online/light_attack.mp3');
  }

  Future<void> playHeavyAttackSound() async {
    await _playSoundSafe('sounds/online/heavy_attack.mp3');
  }

  Future<void> playAerialAttackSound() async {
    await _playSoundSafe('sounds/online/aerial_attack.mp3');
  }

  Future<void> playSpecialAttackSound() async {
    await _playSoundSafe('sounds/online/special_attack.mp3');
  }

  // ✅ أصوات الحركات
  Future<void> playJumpSound() async {
    await _playSoundSafe('sounds/online/jump.mp3');
  }

  Future<void> playLandingSound() async {
    await _playSoundSafe('sounds/online/landing.mp3');
  }

  Future<void> playDamageSound() async {
    await _playSoundSafe('sounds/online/damage.mp3');
  }

  Future<void> playDeathSound() async {
    await _playSoundSafe('sounds/online/death.mp3');
  }

  Future<void> playPunchSound() async {
    await _playSoundSafe('sounds/online/light_attack.mp3');
  }

  Future<void> playWeaponThrowSound() async {
    await _playSoundSafe('sounds/online/heavy_attack.mp3');
  }

  Future<void> playWeaponHitSound() async {
    await _playSoundSafe('sounds/online/heavy_attack.mp3');
  }

  Future<void> playFootstepSound() async {
    await _playSoundSafe('sounds/online/landing.mp3');
  }

  Future<void> playSwordSwingSound() async {
    await _playSoundSafe('sounds/online/light_attack.mp3');
  }

  Future<void> playWeaponPickupSound() async {
    await _playSoundSafe('sounds/online/weapon_pickup.mp3');
  }

  Future<void> playRespawnSound() async {
    await _playSoundSafe('sounds/online/respawn.mp3');
  }

  Future<void> playAttackSound() async {
    await _playSoundSafe('sounds/online/light_attack.mp3');
  }

  // ✅ موسيقى الخلفية
  Future<void> playBattleMusic() async {
    await _playMusicSafe('sounds/online/battle_music.mp3');
  }

  // ✅ التحكم في الموسيقى
  Future<void> stopMusic() async {
    try {
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.stop();
        print('⏹️ تم إيقاف الموسيقى');
      }
    } catch (e) {
      print('⚠️ خطأ في إيقاف الموسيقى: $e');
    }
  }

  // ✅ إيقاف جميع الأصوات بشكل آمن
  Future<void> stopAllSounds() async {
    try {
      // إيقاف الموسيقى
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.stop();
      }

      // إيقاف جميع اللاعبين
      _soundPlayers.forEach((_, player) async {
        try {
          if (player.state == PlayerState.playing) {
            await player.stop();
          }
        } catch (e) {
          // تجاهل
        }
      });

      print('🔇 تم إيقاف جميع الأصوات');

    } catch (e) {
      print('⚠️ خطأ في إيقاف جميع الأصوات: $e');
    }
  }

  // ✅ إعدادات الصوت
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
    if (!enabled) {
      stopAllSounds();
    }
  }

  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    } else {
      playBattleMusic();
    }
  }

  void toggleSound() {
    setSoundEnabled(!_isSoundEnabled);
  }

  void toggleMusic() {
    setMusicEnabled(!_isMusicEnabled);
  }

  // ✅ التنظيف الآمن
  void dispose() {
    try {
      if (_isDisposed) return; // ⭐ منع التكرار

      _isDisposed = true; // ⭐ عيّن هذا أولاً
      // إيقاف الموسيقى أولاً
      if (_musicPlayer.state == PlayerState.playing) {
        _musicPlayer.stop();
      }

      // تنظيف جميع اللاعبين
      _soundPlayers.forEach((_, player) {
        try {
          player.stop();
          player.dispose();
        } catch (e) {
          // تجاهل
        }
      });
      _soundPlayers.clear();

      // التخلص من مشغل الموسيقى
      _musicPlayer.dispose();

      _isInitialized = false;
      print('🗑️ تم تنظيف خدمة الصوت');
    } catch (e) {
      print('⚠️ خطأ في تنظيف خدمة الصوت: $e');
    }
  }
}