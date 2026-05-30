import 'dart:ui';
import '../models/online_character_system.dart';
import 'advanced_animation_system.dart';
import 'animation_loader.dart';
import 'animation_state_machine.dart';

class AnimationManager {
  static final AnimationManager _instance = AnimationManager._internal();
  factory AnimationManager() => _instance;
  AnimationManager._internal();

  final Map<String, Map<AnimationState, AnimationClip>> _characterAnimations = {};
  final Map<String, AdvancedAnimationController> _activeControllers = {};
  final Map<String, AnimationStateMachine> _stateMachines = {};
  final AnimationLoader _loader = AnimationLoader();

  final Map<String, bool> _isCharacterLoaded = {};
  final Map<String, bool> _isCharacterLoading = {};

  // ✅ الدالة المفقودة - تحميل جميع الشخصيات مسبقاً
  Future<void> loadCharacterOnDemand(String characterId, String jsonPath) async {
    // ✅ منع التحميل المزدوج
    if (_isCharacterLoaded[characterId] == true) return;
    if (_isCharacterLoading[characterId] == true) return;

    _isCharacterLoading[characterId] = true;

    try {
      // ✅ استخدام الدالة المصححة بدلاً من القديمة
      await loadCharacterAnimationsWithFix(characterId, jsonPath);
    } finally {
      _isCharacterLoading[characterId] = false;
    }
  }

  // دالة لتفريغ الشخصيات غير المستخدمة
  void unloadUnusedCharacter(String characterId) {
    if (_isCharacterLoaded[characterId] == true) {
      _characterAnimations.remove(characterId);
      _isCharacterLoaded[characterId] = false;
      print('🧹 تم تفريغ الشخصية: $characterId');
    }
  }

  String _getCharacterId(int characterId) {
    switch (characterId) {
      case 1: return 'almashe';
      case 2: return 'rainbow';
      case 3: return 'arabic';
      case 4: return 'medieval';
      case 5: return 'greek';
      case 6: return 'snowy';
      case 7: return 'fiery';
      case 8: return 'techno';
      case 9: return 'viking';
      case 10: return 'comics';
      case 11: return 'zombie';
      case 12: return 'warrior';
      default: return 'almashe';
    }
  }

  void registerCharacterAnimations(
      String characterId,
      Map<AnimationState, AnimationClip> animations,
      ) {
    _characterAnimations[characterId] = animations;
    print('✅ تم تسجيل أنيميشنات $characterId (${animations.length} حالة)');
  }

  Future<void> loadCharacterAnimationsFromJson(
      String characterId,
      String jsonPath,
      ) async {
    try {
      final animations = await _loader.loadCharacterAnimations(characterId, jsonPath);
      if (animations != null) {
        registerCharacterAnimations(characterId, animations);
      } else {
        print('❌ فشل تحميل أنيميشنات $characterId');
      }
    } catch (e) {
      print('❌ استثناء أثناء تحميل أنيميشنات $characterId: $e');
    }
  }

  // ✅ إنشاء متحكم جديد مع التعامل مع الأخطاء
  AdvancedAnimationController createController(String characterId, String instanceId) {
    try {
      print('🎮 إنشاء متحكم: $instanceId | الشخصية: $characterId');

      // ✅ الحصول على الأنيميشنات (أو الطوارئ)
      final animations = _getOrCreateAnimations(characterId);

      // ✅ إنشاء المتحكم
      final controller = AdvancedAnimationController(clips: animations);
      _activeControllers[instanceId] = controller;

      // ✅ بدء التشغيل
      controller.resetState(AnimationState.idle, resetFrame: true);

      return controller;

    } catch (e) {
      print('❌ فشل إنشاء متحكم: $e');
      final emergencyAnimations = _createEmergencyAnimations();
      final controller = AdvancedAnimationController(clips: emergencyAnimations);
      _activeControllers[instanceId] = controller;
      return controller;
    }
  }

  // ✅ دالة لتحميل الأنيميشنات مع التحقق
  Future<void> _loadAnimationsWithValidation(String characterId, String jsonPath) async {
    try {
      print('📁 جاري تحميل أنيميشنات لـ: $characterId');

      final animations = await _loader.loadCharacterAnimations(characterId, jsonPath);
      if (animations == null || animations.isEmpty) {
        print('❌ فشل تحميل أنيميشنات $characterId');
        return;
      }

      // ✅ تسجيل الأنيميشنات
      _characterAnimations[characterId] = animations;
      _isCharacterLoaded[characterId] = true;

      print('✅ تم تحميل أنيميشنات $characterId بنجاح');

      // ✅ التحقق من صحة الأنيميشنات المحملة
      _validateLoadedAnimations(characterId, animations);

    } catch (e) {
      print('❌ خطأ في تحميل أنيميشنات $characterId: $e');
    }
  }

  // ✅ التحقق من الأنيميشنات المحملة
  void _validateLoadedAnimations(String characterId, Map<AnimationState, AnimationClip> animations) {
    print('🔍 التحقق من أنيميشنات $characterId...');

    for (final entry in animations.entries) {
      final state = entry.key;
      final clip = entry.value;

      if (clip.frames.isNotEmpty) {
        final firstFrame = clip.frames.first.framePath;
        final fileName = firstFrame.split('/').last;

        // ✅ التحقق من أن الإطار ينتمي للشخصية الصحيحة
        if (!fileName.contains(characterId)) {
          print('   ❌ إطار خاطئ في $state: $fileName');
          print('   🎯 المتوقع أن يحتوي على: $characterId');
        }
      }
    }
  }

// ✅ دالة مساعدة جديدة
  Map<AnimationState, AnimationClip> _getOrCreateAnimations(String characterId) {
    // ✅ التحقق من الذاكرة المؤقتة
    final cached = _characterAnimations[characterId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // ✅ محاولة تحميل من JSON
    try {
      final jsonPath = _getCharacterConfigPath(characterId);
      print('📂 محاولة تحميل من: $jsonPath');

      // ⚠️ هنا تحتاج لتحميل متزامن أو استخدام Future
      // للبساطة، نستخدم الطوارئ الآن
    } catch (e) {
      print('⚠️ لا يمكن تحميل JSON: $e');
    }

    // ✅ استخدام الطوارئ
    print('🆘 استخدام أنيميشنات طوارئ لـ $characterId');
    final emergency = _createEmergencyAnimations();
    _characterAnimations[characterId] = emergency;
    return emergency;
  }
  
  String _getCharacterConfigPath(String characterId) {
    switch (characterId) {
      case 'almashe': return 'assets/animations/almashe_animations.json';
      case 'rainbow': return 'assets/animations/rainbow_animations.json';
      case 'arabic': return 'assets/animations/arabic_animations.json';
      case 'medieval': return 'assets/animations/medieval_animations.json';
      case 'greek': return 'assets/animations/greek_animations.json';
      case 'snowy': return 'assets/animations/snowy_animations.json';
      case 'fiery': return 'assets/animations/fiery_animations.json';
      case 'techno': return 'assets/animations/techno_animations.json';
      case 'viking': return 'assets/animations/viking_animations.json';
      case 'comics': return 'assets/animations/comics_animations.json';
      case 'zombie': return 'assets/animations/zombie_animations.json';
      case 'warrior': return 'assets/animations/warrior_animations.json';
      default: return 'assets/animations/default_animations.json';
    }
  }

  // ✅ التحقق من جودة الأنيميشنات المحملة
  void _validateAnimationsQuality(String characterId, Map<AnimationState, AnimationClip> animations) {
    print('🔍 التحقق من جودة أنيميشنات $characterId...');

    final essentialStates = [
      AnimationState.idle,
      AnimationState.running,
      AnimationState.jumping,
      AnimationState.falling,
    ];

    int missingStates = 0;
    int emptyClips = 0;

    for (final state in essentialStates) {
      final clip = animations[state];
      if (clip == null) {
        print('   ❌ الحالة الأساسية مفقودة: $state');
        missingStates++;
      } else if (clip.frames.isEmpty) {
        print('   ⚠️ الحالة $state لا تحتوي على إطارات');
        emptyClips++;
      }
    }

    if (missingStates > 0 || emptyClips > 0) {
      print('⚠️ مشاكل في أنيميشنات $characterId:');
      print('   - الحالات المفقودة: $missingStates');
      print('   - الكليبات الفارغة: $emptyClips');
    } else {
      print('✅ أنيميشنات $characterId بصحة جيدة');
    }
  }

// ✅ إنشاء أنيميشنات طوارئ محسنة
  Map<AnimationState, AnimationClip> _createEmergencyAnimations() {
    print('🛠️ إنشاء أنيميشنات احتياطية شاملة...');

    // ✅ استخدام خريطة موحدة للمفاتيح
    final emergencyFrames = {
      AnimationState.idle: {
        'path': 'assets/images/characters/almashe/almashe_idle_1.png',
        'loop': true,
        'durationMs': 200,
      },
      AnimationState.running: {
        'path': 'assets/images/characters/almashe/almashe_run_1.png',
        'loop': true,
        'durationMs': 150,
      },
      AnimationState.jumping: {
        'path': 'assets/images/characters/almashe/almashe_jump_1.png',
        'loop': false,
        'durationMs': 150,
      },
      AnimationState.falling: {
        'path': 'assets/images/characters/almashe/almashe_fall_1.png',
        'loop': true,
        'durationMs': 150,
      },
      AnimationState.attacking_light: {
        'path': 'assets/images/characters/almashe/almashe_light_attack_1.png',
        'loop': false,
        'durationMs': 100,
      },
      AnimationState.attacking_heavy: {
        'path': 'assets/images/characters/almashe/almashe_heavy_attack_1.png',
        'loop': false,
        'durationMs': 120,
      },
      AnimationState.damaged: {
        'path': 'assets/images/characters/almashe/almashe_hurt_1.png',
        'loop': false,
        'durationMs': 100,
      },
      AnimationState.death: {
        'path': 'assets/images/characters/almashe/almashe_death_1.png',
        'loop': false,
        'durationMs': 200,
      },
      AnimationState.dodge: {
        'path': 'assets/images/characters/almashe/almashe_dodge_1.png',
        'loop': false,
        'durationMs': 100,
      },
    };

    final Map<AnimationState, AnimationClip> clips = {};

    for (final entry in emergencyFrames.entries) {
      final state = entry.key;
      final data = entry.value;

      clips[state] = AnimationClip(
        name: 'emergency_${_getAnimationStateKey(state)}',
        loop: data['loop'] as bool,
        frames: [
          AnimationFrame(
            framePath: data['path'] as String,
            durationMs: data['durationMs'] as int,
            events: {},
            rootMotion: Offset.zero,
          ),
        ],
        transitions: _getDefaultTransitionsForState(state),
      );

      print('   ✅ تم إنشاء أنيميشن طوارئ لـ: ${_getAnimationStateKey(state)}');
    }

    print('✅ تم إنشاء ${clips.length} أنيميشن طوارئ');
    return clips;
  }

  // ✅ دالة مساعدة للحصول على انتقالات افتراضية لكل حالة
  Map<String, String> _getDefaultTransitionsForState(AnimationState state) {
    switch (state) {
      case AnimationState.idle:
        return {
          'running': 'always',
          'jumping': 'on_grounded',
          'attacking_light': 'always',
          'attacking_heavy': 'always',
          'damaged': 'always',
        };
      case AnimationState.running:
        return {
          'idle': 'always',
          'jumping': 'on_grounded',
          'attacking_light': 'always',
          'attacking_heavy': 'always',
          'damaged': 'always',
        };
      case AnimationState.jumping:
        return {
          'falling': 'always',
          'idle': 'on_grounded',
          'damaged': 'always',
        };
      case AnimationState.falling:
        return {
          'idle': 'on_grounded',
          'damaged': 'always',
        };
      case AnimationState.attacking_light:
      case AnimationState.attacking_heavy:
        return {
          'idle': 'on_attack_finished',
          'damaged': 'always',
        };
      case AnimationState.damaged:
        return {
          'idle': 'always',
          'death': 'on_health_zero',
        };
      case AnimationState.death:
        return {};
      case AnimationState.dodge:
        return {
          'idle': 'always',
        };
      default:
        return {'idle': 'always'};
    }
  }

  AnimationState _getStateFromKey(String key) {
    switch (key) {
      case 'idle': return AnimationState.idle;
      case 'run': return AnimationState.running;
      case 'jump': return AnimationState.jumping;
      case 'fall': return AnimationState.falling;
      case 'light_attack': return AnimationState.attacking_light;
      case 'heavy_attack': return AnimationState.attacking_heavy;
      case 'damaged': return AnimationState.damaged; // ⭐ تغيير من hurt إلى damaged
      case 'death': return AnimationState.death;
      default: return AnimationState.idle;
    }
  }

  // ✅ تصحيح الحالات أثناء التحميل
  Future<void> loadCharacterAnimationsWithFix(
      String characterId,
      String jsonPath,
      ) async {
    try {
      final animations = await _loader.loadCharacterAnimations(characterId, jsonPath);

      if (animations != null) {
        // ✅ التأكد من وجود جميع الحالات المهمة
        final Map<AnimationState, AnimationClip> fixedAnimations = Map.from(animations);

        // ✅ قائمة الحالات المطلوبة
        final requiredStates = [
          AnimationState.idle,
          AnimationState.running,
          AnimationState.jumping,
          AnimationState.falling,
          AnimationState.attacking_light,
          AnimationState.attacking_heavy,
          AnimationState.damaged,  // ⭐ مهم جداً
          AnimationState.death,
        ];

        // ✅ التحقق من وجود كل حالة
        for (final state in requiredStates) {
          if (!fixedAnimations.containsKey(state)) {
            print('⚠️ الحالة $state غير موجودة، إنشاء حالة افتراضية');

            // إنشاء إطار افتراضي لهذه الحالة
            final String stateKey = _getAnimationStateKey(state);
            final String framePath = 'assets/images/characters/$characterId/${characterId}_${stateKey}_1.png';

            fixedAnimations[state] = AnimationClip(
              name: 'default_${stateKey}',
              loop: state != AnimationState.death,
              frames: [
                AnimationFrame(
                  framePath: framePath,
                  durationMs: 100,
                  events: {},
                  rootMotion: Offset.zero,
                ),
              ],
              transitions: {'all': 'always'},
            );
          }
        }

        // ✅ تسجيل الأنيميشنات المصححة
        registerCharacterAnimations(characterId, fixedAnimations);
      } else {
        print('❌ فشل تحميل أنيميشنات $characterId');
      }
    } catch (e) {
      print('❌ استثناء أثناء تحميل أنيميشنات $characterId: $e');
    }
  }

// ✅ دالة محسنة لتحويل AnimationState إلى مفتاح نصي
  String _getAnimationStateKey(AnimationState state) {
    switch (state) {
      case AnimationState.idle: return 'idle';
      case AnimationState.running: return 'run';
      case AnimationState.jumping: return 'jump';
      case AnimationState.falling: return 'fall';
      case AnimationState.attacking_light: return 'light_attack';
      case AnimationState.attacking_heavy: return 'heavy_attack';
      case AnimationState.damaged: return 'hurt'; // ⭐ المفتاح المستخدم في ملفات الصور
      case AnimationState.death: return 'death';
      case AnimationState.dodge: return 'dodge';
      default: return state.toString().split('.').last;
    }
  }

  // ✅ أضف هذه الدالة في AnimationManager
  void debugLoadedAnimations() {
    print('🔍 === الأنيميشنات المحملة ===');

    _characterAnimations.forEach((characterId, animations) {
      print('👤 $characterId: ${animations.length} حركة');
    });
  }

  void updateAll(double deltaTime) {
    for (final entry in _activeControllers.entries) {
      try {
        entry.value.update(deltaTime);
      } catch (e) {
        print('❌ خطأ في تحديث متحكم ${entry.key}: $e');
      }
    }
  }

  // ✅ دالة لفحص شخصية محددة
  void debugCharacterAnimations(String characterId) {
    print('🔍 === فحص أنيميشنات $characterId ===');

    final animations = _characterAnimations[characterId];
    if (animations == null) {
      print('❌ لا توجد أنيميشنات محملة');
      return;
    }

    for (final state in AnimationState.values) {
      final clip = animations[state];
      if (clip != null) {
        print('🎯 $state: ${clip.frames.length} إطار');
        if (clip.frames.isNotEmpty) {
          final firstFrame = clip.frames.first.framePath.split('/').last;
          print('   📁 أول إطار: $firstFrame');
        }
      } else {
        print('❌ $state: غير محمل');
      }
    }

    print('===============================');
  }

  AnimationStateMachine createStateMachine(
      String instanceId,
      Map<AnimationState, AnimationStateConfig> states,
      AnimationState initialState,
      ) {
    final stateMachine = AnimationStateMachine(
      states: states,
      initialState: initialState,
    );
    _stateMachines[instanceId] = stateMachine;
    return stateMachine;
  }

  void disposeController(String instanceId) {
    _activeControllers.remove(instanceId);
    _stateMachines.remove(instanceId);
    print('🗑️ تم التخلص من متحكم $instanceId');
  }

  Map<AnimationState, AnimationClip>? getCharacterAnimations(String characterId) {
    return _characterAnimations[characterId];
  }

  // ✅ الحصول على متحكم نشط
  AdvancedAnimationController? getController(String instanceId) {
    return _activeControllers[instanceId];
  }

  // ✅ الحصول على State Machine
  AnimationStateMachine? getStateMachine(String instanceId) {
    return _stateMachines[instanceId];
  }

  void clearCharacterAnimations(String characterId) {
    _characterAnimations.remove(characterId);
    _isCharacterLoaded.remove(characterId);
    print('🧹 تم مسح أنيميشنات $characterId');
  }

  void forceReloadCharacter(String characterId, String jsonPath) async {
    try {
      print('🔄 إعادة تحميل قسري للشخصية: $characterId');

      // ✅ مسح الأنيميشنات القديمة
      clearCharacterAnimations(characterId);

      // ✅ إعادة التحميل
      await _loadAnimationsWithValidation(characterId, jsonPath);

      print('✅ تم إعادة تحميل $characterId بنجاح');
    } catch (e) {
      print('❌ فشل إعادة التحميل: $e');
    }
  }

// ✅ دالة للتحقق مما إذا كانت الشخصية محملة
  bool isCharacterLoaded(String characterId) {
    return _isCharacterLoaded[characterId] ?? false;
  }

// ✅ دالة للحصول على عدد الأنيميشنات المحملة
  int getLoadedAnimationCount(String characterId) {
    final animations = _characterAnimations[characterId];
    return animations?.length ?? 0;
  }

// ✅ دالة طوارئ لإعادة تعيين شخصية
  void emergencyResetCharacter(String characterId, String instanceId) {
    try {
      print('🆘 إعادة تعيين طارئ للشخصية: $characterId');

      // ✅ التخلص من المتحكم القديم
      disposeController(instanceId);

      // ✅ مسح الأنيميشنات
      clearCharacterAnimations(characterId);

      print('✅ تم إعادة تعيين $characterId للطوارئ');
    } catch (e) {
      print('❌ فشل إعادة التعيين الطارئ: $e');
    }
  }
}