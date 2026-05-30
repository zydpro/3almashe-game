// lib/services/animation_loader.dart
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'advanced_animation_system.dart';

class AnimationLoader {
  static final AnimationLoader _instance = AnimationLoader._internal();
  factory AnimationLoader() => _instance;
  AnimationLoader._internal();

  final Map<String, Map<AnimationState, AnimationClip>> _loadedAnimations = {};
  final Set<String> _loadingCharacters = {};

  // ✅ تحميل أنيميشنات شخصية مع التعامل مع الأخطاء
  Future<Map<AnimationState, AnimationClip>> loadCharacterAnimations(
      String characterId,
      String jsonPath,
      ) async {
    // منع التحميل المزدوج
    if (_loadingCharacters.contains(characterId)) {
      return _loadedAnimations[characterId] ?? _createFallbackAnimations();
    }

    if (_loadedAnimations.containsKey(characterId)) {
      return _loadedAnimations[characterId]!;
    }

    _loadingCharacters.add(characterId);

    try {
      print('🔄 جاري تحميل أنيميشنات: $characterId من $jsonPath');

      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      final animations = <AnimationState, AnimationClip>{};

      for (final entry in jsonData.entries) {
        try {
          final state = _parseAnimationState(entry.key);
          if (state != null) {
            final originalClip = AnimationClip.fromJson(entry.value);

            // ✅ تصحيح مسارات الإطارات
            final correctedFrames = originalClip.frames.map((frame) {
              final originalPath = frame.framePath;
              final fileName = originalPath.split('/').last;

              // ✅ إذا كان الإطار خاطئاً (يحتوي على zombie بدلاً من الشخصية الصحيحة)
              if (fileName.contains('zombie') && !fileName.contains(characterId)) {
                // ✅ استبدال zombie بالشخصية الصحيحة
                final correctedFileName = fileName.replaceFirst('zombie', characterId);
                final correctedPath = 'assets/images/characters/$characterId/$correctedFileName';

                print('   🔄 تصحيح إطار: $fileName → $correctedFileName');
                return AnimationFrame(
                  framePath: correctedPath,
                  durationMs: frame.durationMs,
                  events: frame.events,
                  rootMotion: frame.rootMotion,
                );
              }
              // ✅ إذا كان المسار لا يحتوي على الشخصية الصحيحة، أصلحه
              else if (!fileName.contains(characterId)) {
                // ✅ بناء المسار الصحيح بناءً على الحالة
                final stateKey = _getAnimationStateKey(state);
                final parts = fileName.split('_');
                final frameNumber = parts.last;
                final correctedFileName = '${characterId}_${stateKey}_$frameNumber';
                final correctedPath = 'assets/images/characters/$characterId/$correctedFileName';

                print('   🔄 إصلاح إطار خاطئ: $fileName → $correctedFileName');
                return AnimationFrame(
                  framePath: correctedPath,
                  durationMs: frame.durationMs,
                  events: frame.events,
                  rootMotion: frame.rootMotion,
                );
              }

              return frame;
            }).toList();

            // ✅ إنشاء الكليب المصحح
            final correctedClip = AnimationClip(
              name: '${characterId}_${_getAnimationStateKey(state)}',
              frames: correctedFrames,
              loop: originalClip.loop,
              metadata: originalClip.metadata,
              transitions: originalClip.transitions,
              onComplete: originalClip.onComplete,
            );

            animations[state] = correctedClip;
            print('✅ تم تحميل: $state - ${correctedFrames.length} إطار');
          }
        } catch (e) {
          print('⚠️ خطأ في تحميل حالة ${entry.key}: $e');
        }
      }

      _loadedAnimations[characterId] = animations;
      print('🎉 تم تحميل أنيميشنات $characterId بنجاح (${animations.length} حالة)');

      // ✅ طباعة تفاصيل الأنيميشنات المحملة
      _debugLoadedAnimations(characterId, animations);

      return animations;

    } catch (e) {
      print('❌ فشل تحميل أنيميشنات $characterId: $e');
      final fallback = _createFallbackAnimations();
      _loadedAnimations[characterId] = fallback;
      return fallback;
    } finally {
      _loadingCharacters.remove(characterId);
    }
  }

  // ✅ دالة مساعدة للحصول على مفتاح الحالة
  String _getAnimationStateKey(AnimationState state) {
    switch (state) {
      case AnimationState.idle: return 'idle';
      case AnimationState.running: return 'run';
      case AnimationState.jumping: return 'jump';
      case AnimationState.falling: return 'fall';
      case AnimationState.attacking_light: return 'light_attack';
      case AnimationState.attacking_heavy: return 'heavy_attack';
      case AnimationState.hurt: return 'hurt';
      case AnimationState.death: return 'death';
      case AnimationState.dodge: return 'dodge';
      case AnimationState.attacking_aerial: return 'aerial_attack';
      case AnimationState.damaged: return 'hurt';
      default: return state.toString().split('.').last;
    }
  }

// ✅ دالة لطباعة تفاصيل الأنيميشنات المحملة
  void _debugLoadedAnimations(String characterId, Map<AnimationState, AnimationClip> animations) {
    print('🔍 === تفاصيل أنيميشنات $characterId ===');
    for (final entry in animations.entries) {
      final state = entry.key;
      final clip = entry.value;
      print('🎬 $state: ${clip.frames.length} إطار');
      if (clip.frames.isNotEmpty) {
        final firstFrame = clip.frames.first.framePath.split('/').last;
        print('   📁 أول إطار: $firstFrame');
        // ✅ التحقق من أن الإطار ينتمي للشخصية الصحيحة
        if (!firstFrame.contains(characterId)) {
          print('   ⚠️ تحذير: الإطار لا ينتمي للشخصية الصحيحة!');
        }
      }
    }
    print('==================================');
  }

  AnimationState? _parseAnimationState(String stateName) {
    // إزالة البادئة إذا وجدت
    final cleanName = stateName.replaceAll('AnimationState.', '');

    // خريطة موسعة للتسميات
    final Map<String, AnimationState> stateMap = {
      // الصيغ الأساسية
      'idle': AnimationState.idle,
      'running': AnimationState.running,
      'jumping': AnimationState.jumping,
      'falling': AnimationState.falling,
      'attacking_light': AnimationState.attacking_light,
      'attacking_heavy': AnimationState.attacking_heavy,
      'death': AnimationState.death,

      // أسماء بديلة
      'run': AnimationState.running,
      'jump': AnimationState.jumping,
      'fall': AnimationState.falling,

      // حالتان لنفس الشيء
      'damaged': AnimationState.damaged,
      'hurt': AnimationState.damaged,
    };

    // البحث بـ cleanName فقط (أكثر كفاءة)
    final state = stateMap[cleanName];

    if (state == null) {
      print('⚠️ حالة غير معروفة: "$stateName" (clean: "$cleanName")');
    }

    return state;
  }

  // ✅ تحميل الأنيميشنات الافتراضية
  Future<Map<AnimationState, AnimationClip>> _loadDefaultAnimations() async {
    if (_loadedAnimations.containsKey('default')) {
      return _loadedAnimations['default']!; // ⬅️ ! لأننا نعلم أنها موجودة
    }

    try {
      final defaultAnimations = await loadCharacterAnimations(
          'default',
          'assets/animations/default_animations.json'
      );

      // ✅ defaultAnimations ليست nullable الآن
      _loadedAnimations['default'] = defaultAnimations;
      return defaultAnimations;

    } catch (e) {
      print('❌ فشل تحميل الأنيميشنات الافتراضية: $e');
      return _createFallbackAnimations();
    }
  }

  // ✅ إنشاء أنيميشنات احتياطية
  Map<AnimationState, AnimationClip> _createFallbackAnimations() {
    // print('🛠️ إنشاء أنيميشنات احتياطية...');

    return {
      AnimationState.idle: AnimationClip(
        name: 'idle',
        loop: true,
        frames: [
          AnimationFrame(
            framePath: 'assets/images/characters/almashe/almashe_idle_1.png',
            durationMs: 200,
            events: {},
            rootMotion: ui.Offset.zero,
          ),
        ],
        transitions: {
          'running': 'always',
          'jumping': 'always',
        },
      ),
      AnimationState.running: AnimationClip(
        name: 'running',
        loop: true,
        frames: [
          AnimationFrame(
            framePath: 'assets/images/characters/almashe/almashe_run_1.png',
            durationMs: 100,
            events: {},
            rootMotion: ui.Offset(0.01, 0),
          ),
        ],
        transitions: {
          'idle': 'always',
        },
      ),
      AnimationState.jumping: AnimationClip(
        name: 'jumping',
        loop: false,
        frames: [
          AnimationFrame(
            framePath: 'assets/images/characters/almashe/almashe_jump_1.png',
            durationMs: 150,
            events: {},
            rootMotion: ui.Offset(0, -0.01),
          ),
        ],
        transitions: {
          'falling': 'always',
        },
      ),
      AnimationState.falling: AnimationClip(
        name: 'falling',
        loop: true,
        frames: [
          AnimationFrame(
            framePath: 'assets/images/characters/almashe/almashe_fall_1.png',
            durationMs: 150,
            events: {},
            rootMotion: ui.Offset(0, 0.01),
          ),
        ],
        transitions: {
          'idle': 'always',
        },
      ),
      AnimationState.attacking_light: AnimationClip(
        name: 'attacking_light',
        loop: false,
        frames: [
          AnimationFrame(
            framePath: 'assets/images/characters/almashe/almashe_light_attack_1.png',
            durationMs: 100,
            events: {'hitbox': {'damage': 10}},
            rootMotion: ui.Offset(0.005, 0),
          ),
        ],
        transitions: {
          'idle': 'always',
        },
      ),
      AnimationState.hurt: AnimationClip(
        name: 'damaged',
        loop: false,
        frames: [
          AnimationFrame(
            framePath: 'assets/images/characters/almashe/almashe_hurt_1.png',
            durationMs: 100,
            events: {},
            rootMotion: ui.Offset(-0.005, 0),
          ),
        ],
        transitions: {
          'idle': 'always',
        },
      ),
      AnimationState.death: AnimationClip(
        name: 'death',
        loop: false,
        frames: [
          AnimationFrame(
            framePath: 'assets/images/characters/almashe/almashe_death_1.png',
            durationMs: 200,
            events: {},
            rootMotion: ui.Offset.zero,
          ),
        ],
        transitions: {},
      ),
    };
  }

  // ✅ الحصول على الأنيميشنات المحملة
  Map<AnimationState, AnimationClip> getAnimations(String characterId) {
    return _loadedAnimations[characterId] ?? _createFallbackAnimations();
  }

  // ✅ التحقق مما إذا كانت الأنيميشنات محملة
  bool areAnimationsLoaded(String characterId) {
    return _loadedAnimations.containsKey(characterId);
  }

  // ✅ مسح الذاكرة المؤقتة
  void clearCache() {
    _loadedAnimations.clear();
    // print('🧹 تم مسح ذاكرة الأنيميشنات المؤقتة');
  }

  // ✅ إعادة تحميل أنيميشنات شخصية
  Future<void> reloadCharacterAnimations(String characterId, String jsonPath) async {
    _loadedAnimations.remove(characterId);
    await loadCharacterAnimations(characterId, jsonPath);
  }

  void testParseFunction() {
    print('🧪 اختبار دالة _parseAnimationState:');

    final tests = [
      'running',
      'AnimationState.running',
      'run',
      'jump',
      'damaged',
      'hurt',
      'unknown_state'
    ];

    for (final test in tests) {
      final result = _parseAnimationState(test);
      print('   "$test" → $result');
    }
  }

  // ✅ فحص مفصل للأنيميشنات المحملة
  void debugLoadedAnimations(String characterId) {
    final animations = _loadedAnimations[characterId];
    if (animations == null) {
      print('❌ لا توجد أنيميشنات محملة لـ $characterId');
      return;
    }
    print('🔍 === فحص أنيميشنات $characterId ===');
    for (final entry in animations.entries) {
      final state = entry.key;
      final clip = entry.value;
      print('🎬 $state: ${clip.frames.length} إطار (loop: ${clip.loop})');
      for (int i = 0; i < clip.frames.length; i++) {
        final frame = clip.frames[i];
        print('   ${i + 1}. ${frame.framePath} - ${frame.durationMs}ms');
      }
      print('   🔀 الانتقالات: ${clip.transitions}');
      print('   ---');
    }
    print('================================');
  }


// ✅ فحص شامل للأنيميشنات المحملة
  void debugAnimationFrames(String characterId, AnimationState state) {
    final animations = _loadedAnimations[characterId];
    if (animations == null) {
      print('❌ لا توجد أنيميشنات محملة لـ $characterId');
      return;
    }

    final clip = animations[state];
    if (clip == null) {
      print('❌ لا توجد أنيميشن لـ $state');
      return;
    }

    //
    print('🔍 === فحص إطارات $state ===');
    print('📁 عدد الإطارات: ${clip.frames.length}');
    print('🔄 loop: ${clip.loop}');

    for (int i = 0; i < clip.frames.length; i++) {
      final frame = clip.frames[i];
      print('   ${i + 1}. ${frame.framePath} - ${frame.durationMs}ms');

      // ✅ التحقق من وجود الملف (افتراضياً)
      if (!frame.framePath.contains('assets/')) {
        print('   ⚠️ تحذير: مسار غير قياسي');
      }
    }
    print('============================');
  }

}