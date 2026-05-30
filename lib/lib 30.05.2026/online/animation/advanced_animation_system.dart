import 'dart:math';
import 'dart:convert';
import 'dart:ui';

// ✅ تعريفات البيانات الأساسية
enum AnimationState {
  idle,
  running,
  jumping,
  falling,
  attacking_light,
  attacking_heavy,
  dodge,
  hurt,
  death,
  damaged,  // ✅ تأكد من وجودها
  attacking_aerial,
}

const _anyState = 'any';

enum AnimationLayer {
  fullBody,
  lowerBody,
  upperBody,
}

class AnimationFrame {
  final String framePath;
  final int durationMs;
  final Map<String, dynamic> events;
  final Offset rootMotion;

  const AnimationFrame({
    required this.framePath,
    required this.durationMs,
    this.events = const {},
    this.rootMotion = Offset.zero,
  });

  Map<String, dynamic> toJson() => {
    'framePath': framePath,
    'durationMs': durationMs,
    'events': events,
    'rootMotion': {'x': rootMotion.dx, 'y': rootMotion.dy},
  };

  factory AnimationFrame.fromJson(Map<String, dynamic> json) {
    final rootMotion = json['rootMotion'] ?? {};
    return AnimationFrame(
      framePath: json['framePath'],
      durationMs: json['durationMs'],
      events: Map<String, dynamic>.from(json['events'] ?? {}),
      rootMotion: Offset(
        (rootMotion['x'] ?? 0).toDouble(),
        (rootMotion['y'] ?? 0).toDouble(),
      ),
    );
  }
}

class AnimationClip {
  final String name;
  final List<AnimationFrame> frames;
  final bool loop;
  final Map<String, dynamic> metadata;
  final Map<String, String> transitions;
  final VoidCallback? onComplete;

  const AnimationClip({
    required this.name,
    required this.frames,
    this.loop = true,
    this.metadata = const {},
    this.transitions = const {},
    this.onComplete,
  });

  int get totalDuration => frames.fold(0, (sum, frame) => sum + frame.durationMs);

  Map<String, dynamic> toJson() => {
    'name': name,
    'frames': frames.map((frame) => frame.toJson()).toList(),
    'loop': loop,
    'metadata': metadata,
    'transitions': transitions,
  };

  factory AnimationClip.fromJson(Map<String, dynamic> json) {
    return AnimationClip(
      name: json['name'],
      frames: (json['frames'] as List)
          .map((frame) => AnimationFrame.fromJson(Map<String, dynamic>.from(frame)))
          .toList(),
      loop: json['loop'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      transitions: Map<String, String>.from(json['transitions'] ?? {}),
    );
  }
}

// ✅ نظام التحكم في الأنيميشن المتقدم
class AdvancedAnimationController {
  final Map<AnimationState, AnimationClip> _clips;
  final Map<AnimationLayer, AnimationState> _layerStates;
  final Map<AnimationLayer, double> _layerWeights;

  // ✅ إضافة نظام تحميل الفريمات عند الطلب
  final Map<String, Image> _loadedFrames = {};
  final Set<String> _loadingFrames = {};

  // ✅ إضافة متغيرات التثبيت
  AnimationState _lastStableState = AnimationState.idle;
  int _stateChangeTime = 0;
  static const int MIN_STATE_CHANGE_INTERVAL = 100; // 100ms بين التغييرات

  AnimationState _currentBaseState;
  int _currentFrameIndex = 0;
  double _currentTime = 0.0;
  double _blendTime = 0.0;
  double _blendDuration = 0.0;
  AnimationState? _blendTargetState;

  double _accumulatedMs = 0.0;
  bool _isPlaying = true;

  // ✅ إضافة المتغير المفقود
  String _lastFramePath = '';

  // ✅ إضافة getter لـ currentState
  AnimationState get currentState => _currentBaseState;
  AnimationClip? get currentClip => _clips[_currentBaseState];

  // ✅ إضافة getter للإطار الحالي
  int get currentFrameIndex => _currentFrameIndex;

  // ✅ إضافة متغير لتتبع حالة الأرض
  bool _isGrounded = true;

  // التتبع الزمني
  double _lastUpdateTime = 0.0;
  // ✅ إضافة متغير لتتبع حالة الموت
  bool _isFinalDeath = false;
  bool _isDying = false;

  // ✅ Getter لمعرفة ما إذا كان الموت نهائياً
  bool get isFinalDeath => _isFinalDeath;
  bool get isDying => _isDying;

  // الأحداث
  final List<AnimationEvent> _pendingEvents = [];

  // Root Motion
  Offset _accumulatedRootMotion = Offset.zero;
  Offset _lastRootMotion = Offset.zero;

  AdvancedAnimationController({
    required Map<AnimationState, AnimationClip> clips,
    AnimationState initialState = AnimationState.idle,
  })  : _clips = clips,
        _currentBaseState = initialState,
        _layerStates = {
          AnimationLayer.fullBody: initialState,
          AnimationLayer.lowerBody: AnimationState.idle,
          AnimationLayer.upperBody: AnimationState.idle,
        },
        _layerWeights = {
          AnimationLayer.fullBody: 1.0,
          AnimationLayer.lowerBody: 1.0,
          AnimationLayer.upperBody: 1.0,
        };

  // ✅ التحديث باستخدام Delta Time فقط
  void update(double deltaTimeMs) {
    try {
      if (!_isPlaying) return;

      final currentClip = _clips[_currentBaseState];
      if (currentClip == null || currentClip.frames.isEmpty) {
        print('❌ لا يوجد كليب للحالة: $_currentBaseState');
        return;
      }

      // ✅ التأكد من أن الفهرس صالح
      if (_currentFrameIndex < 0 || _currentFrameIndex >= currentClip.frames.length) {
        print('⚠️ إطار خارج النطاق: $_currentFrameIndex, إعادة التعيين');
        _currentFrameIndex = 0;
      }

      _currentTime += deltaTimeMs;
      _accumulatedMs += deltaTimeMs;

      final currentFrame = currentClip.frames[_currentFrameIndex];

      // ✅ التحقق من نهاية أنيميشن الموت
      if (_currentBaseState == AnimationState.death && _isDying) {
        final isLastFrame = _currentFrameIndex >= currentClip.frames.length - 1;

        if (isLastFrame && _accumulatedMs >= currentFrame.durationMs) {
          print('💀 [DEATH] انتهى أنيميشن الموت - الإطار الأخير');

          if (!_isFinalDeath) {
            // ✅ موت مؤقت: ننتقل إلى idle بعد الانتهاء
            print('🔄 [DEATH] موت مؤقت - التحضير للإحياء');
            _isDying = false;
            _isPlaying = true;
            _accumulatedMs = 0;

            // ✅ الانتقال إلى idle بعد انتهاء الموت
            transitionToState(AnimationState.idle, reason: "death_completed_respawn");
          } else {
            // ✅ موت نهائي: نبقى على آخر فريم
            print('💀 [FINAL DEATH] موت نهائي - البقاء على الإطار الأخير');
            _isPlaying = false;
            _isDying = false;
          }
          return;
        }
      }

      // ✅ التقدم في الإطارات
      if (_accumulatedMs >= currentFrame.durationMs) {
        _accumulatedMs = 0;
        _currentFrameIndex++;

        // ✅ إذا وصلنا للنهاية
        if (_currentFrameIndex >= currentClip.frames.length) {
          if (currentClip.loop) {
            _currentFrameIndex = 0;
          } else {
            _currentFrameIndex = currentClip.frames.length - 1;
            _isPlaying = false;
            currentClip.onComplete?.call();

            // ✅ إذا كان الموت وانتهى وغير نهائي، ننتقل إلى idle
            if (_currentBaseState == AnimationState.death && !_isFinalDeath && !_isDying) {
              print('🔄 [DEATH] انتهى أنيميشن الموت (غير نهائي) - الانتقال إلى idle');
              transitionToState(AnimationState.idle, reason: "death_auto_respawn");
            }
          }
        }

        // ✅ طباعة التغيير (فقط للتتبع)
        final newFrame = currentClip.frames[_currentFrameIndex];
        print('🔄 تغيير الإطار: ${_currentFrameIndex-1} → $_currentFrameIndex');
        print('   📁 ${newFrame.framePath.split('/').last}');
      }

    } catch (e) {
      print('❌ خطأ في update: $e');
      _resetToSafeState();
    }
  }

  // ✅ دالة لبدء أنيميشن الموت
  void startDeathAnimation({bool isFinal = false}) {
    _isFinalDeath = isFinal;
    _isDying = true;
    transitionToState(AnimationState.death, reason: "death_animation");
  }

  // ✅ دالة لإنهاء أنيميشن الموت
  void endDeathAnimation() {
    _isDying = false;
    if (!_isFinalDeath) {
      // إذا لم يكن موتاً نهائياً، ننتقل إلى idle
      transitionToState(AnimationState.idle, reason: "death_animation_ended");
    }
  }

  void updateGroundState(bool isGrounded) {
    _isGrounded = isGrounded;
  }

// ✅ إعادة التعيين الآمن
  void _resetToSafeState() {
    _currentBaseState = AnimationState.idle;
    _currentFrameIndex = 0;
    _currentTime = 0.0;

    // ✅ استخدام إطار طوارئ
    _lastFramePath = 'assets/images/characters/almashe/almashe_idle_1.png';
  }

  void _processFrameEvents() {
    final currentClip = _clips[_currentBaseState];
    if (currentClip == null) return;

    final currentFrame = currentClip.frames[_currentFrameIndex];
    for (final event in currentFrame.events.entries) {
      _pendingEvents.add(AnimationEvent(
        type: event.key,
        data: event.value,
        layer: AnimationLayer.fullBody,
        frameTime: _currentTime,
      ));
    }

    // تجميع Root Motion
    _lastRootMotion = currentFrame.rootMotion;
    _accumulatedRootMotion += currentFrame.rootMotion;
  }

  // ✅ الانتقال بين الحركات
  void transitionToState(AnimationState newState, {double blendDuration = 100.0, String reason = ''}) {
    if (_currentBaseState == newState) return;

    print('🔄 [ANIMATION] $reason: ${_currentBaseState} → $newState');

    _currentBaseState = newState;
    _currentFrameIndex = 0;
    _currentTime = 0.0;
    _accumulatedMs = 0.0;
    _isPlaying = true;
  }

// ✅ دالة مساعدة لتحويل AnimationState إلى مفتاح نصي
  String _getAnimationStateKey(AnimationState state) {
    switch (state) {
      case AnimationState.idle: return 'idle';
      case AnimationState.running: return 'run';
      case AnimationState.jumping: return 'jump';
      case AnimationState.falling: return 'fall';
      case AnimationState.attacking_light: return 'light_attack';
      case AnimationState.attacking_heavy: return 'heavy_attack';
      case AnimationState.damaged: return 'hurt'; // ✅ مهم: تعيد 'hurt'
      case AnimationState.death: return 'death';
      case AnimationState.dodge: return 'dodge';
      default: return state.toString().split('.').last;
    }
  }

  // ✅ إصلاح دالة تقييم القواعد
  bool _evaluateTransitionRule(String rule) {
    // print('   🔍 تقييم قاعدة الانتقال: "$rule" | على الأرض: $_isGrounded');

    switch (rule) {
      case 'on_grounded':
        final result = _isGrounded;
        // print('      🏞️ قاعدة on_grounded: $result');
        return result;

      case 'on_attack_finished':
        final currentClip = _clips[_currentBaseState];
        if (currentClip == null) {
          // print('      ⚠️ لا يوجد كليب حالي، اعتبار الهجوم منتهي');
          return true;
        }
        final isLastFrame = _currentFrameIndex >= currentClip.frames.length - 1;
        // print('      🎯 قاعدة on_attack_finished: الإطار $_currentFrameIndex من ${currentClip.frames.length} = $isLastFrame');
        return isLastFrame;

      case 'always':
        // print('      ✅ قاعدة always: true');
        return true;

      default:
        // print('      ⚠️ قاعدة غير معروفة: "$rule", استخدام always');
        return true;
    }
  }

// AdvancedAnimationController.dart
  String getCurrentFramePath(AnimationLayer layer) {
    try {
      final state = _currentBaseState;
      final clip = _clips[state];

      if (clip == null || clip.frames.isEmpty) {
        print('❌ لا يوجد كليب لـ $state، استخدام idle');
        final idleClip = _clips[AnimationState.idle];
        if (idleClip != null && idleClip.frames.isNotEmpty) {
          return idleClip.frames[0].framePath;
        }
        return _getEmergencyFrame();
      }

      final safeIndex = _currentFrameIndex.clamp(0, clip.frames.length - 1);
      final frame = clip.frames[safeIndex];
      final fileName = frame.framePath.split('/').last;
      final expectedKey = _getAnimationStateKey(state);

      // ✅ لا نطبع خطأ إذا كان الإطار يحتوي على 'hurt' والحالة damaged
      if (!fileName.contains(expectedKey)) {
        // فقط نطبع إذا كانت الحالة ليست damaged (لأن التبديل سريع)
        if (state != AnimationState.damaged) {
          print('⚠️ إطار غير متوقع! المتوقع: $expectedKey | الفعلي: $fileName');
          print('   📊 الحالة: $state | الفهرس: $safeIndex/${clip.frames.length}');
        }
      }

      return frame.framePath;

    } catch (e) {
      print('❌ خطأ في getCurrentFramePath: $e');
      return _getEmergencyFrame();
    }
  }

  Future<void> _loadFrameImage(String framePath) async {
    if (_loadingFrames.contains(framePath)) return;

    _loadingFrames.add(framePath);

    try {
      // TODO: تنفيذ تحميل الصورة
      // final image = await ImageLoader.loadImage(framePath);
      // _loadedFrames[framePath] = image;
    } catch (e) {
      print('❌ فشل تحميل الفريم: $framePath');
    } finally {
      _loadingFrames.remove(framePath);
    }
  }

  // ✅ دالة لتحميل الفريمات الضرورية فقط
  Future<void> preloadEssentialFrames() async {
    try {
      // تحميل أول فريم من كل حركة فقط
      final framesToPreload = <String>{};

      for (final entry in _clips.entries) {
        final clip = entry.value;
        if (clip.frames.isNotEmpty) {
          final firstFrame = clip.frames.first.framePath;
          framesToPreload.add(firstFrame);
        }
      }

      // TODO: تنفيذ تحميل الصور هنا إذا لزم الأمر
      print('📁 جاري تحميل ${framesToPreload.length} فريم أساسي');

    } catch (e) {
      print('❌ فشل تحميل الفريمات الأساسية: $e');
    }
  }

  // ✅ دالة طوارئ للحصول على إطار افتراضي
  String _getEmergencyFrame() {
    try {
      final charId = 'almashe'; // ⬅️ افتراضي مؤقت
      final state = _currentBaseState;
      final stateKey = _getAnimationStateKey(state);

      // ✅ محاولة البحث في الكليب أولاً
      final clip = _clips[state];
      if (clip != null && clip.frames.isNotEmpty) {
        return clip.frames[0].framePath; // أول إطار في الكليب
      }

      // ✅ بناء المسار يدوياً
      final emergencyPath = 'assets/images/characters/$charId/${charId}_${stateKey}_1.png';
      print('🆘 استخدام إطار طوارئ: ${emergencyPath.split('/').last}');
      return emergencyPath;

    } catch (e) {
      return 'assets/images/characters/almashe/almashe_idle_1.png';
    }
  }

  // ✅ الحصول على الوزن الحالي للطبقة
  double getLayerWeight(AnimationLayer layer) {
    if (_blendTargetState == null) return _layerWeights[layer] ?? 1.0;

    final blendFactor = _blendTime / _blendDuration;
    return _layerWeights[layer]! * (1.0 - blendFactor);
  }

  // ✅ التحكم في الطبقات
  void setLayerState(AnimationLayer layer, AnimationState state, {double weight = 1.0}) {
    _layerStates[layer] = state;
    _layerWeights[layer] = weight.clamp(0.0, 1.0);
  }

  // ✅ الحصول على Root Motion
  Offset consumeRootMotion() {
    final motion = _accumulatedRootMotion;
    _accumulatedRootMotion = Offset.zero;
    return motion;
  }

  // ✅ الحصول على الأحداث المعلقة
  List<AnimationEvent> getPendingEvents() {
    final events = List<AnimationEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    return events;
  }

  // في AdvancedAnimationController
  void debugClipsInfo() {
    print('📊 === معلومات الكليبات ===');
    for (final entry in _clips.entries) {
      final state = entry.key;
      final clip = entry.value;
      print('🎬 $state: ${clip.frames.length} إطار');

      if (clip.frames.isNotEmpty) {
        print('   أول إطار: ${clip.frames.first.framePath.split('/').last}');
        print('   آخر إطار: ${clip.frames.last.framePath.split('/').last}');
      }
    }
    print('==========================');
  }

  // في AdvancedAnimationController
  void debugCurrentFrame() {
    final currentClip = _clips[_currentBaseState];
    if (currentClip == null) {
      print('❌ لا يوجد كليب للحالة: $_currentBaseState');
      return;
    }

    print('''
🎯 === إطار حالي ===
الحالة: $_currentBaseState
الإطار: $_currentFrameIndex/${currentClip.frames.length}
المسار: ${currentClip.frames[_currentFrameIndex].framePath}
الوقت المتراكم: ${_accumulatedMs}ms
مدة الإطار الحالي: ${currentClip.frames[_currentFrameIndex].durationMs}ms
=== نهاية ===
''');
  }

  // ✅ إعادة تعيين الحالة
  void resetState(AnimationState state, {bool resetFrame = true}) {
    _currentBaseState = state;
    if (resetFrame) {
      _currentFrameIndex = 0;
      _currentTime = 0.0;
    }
    _blendTargetState = null;
    _blendTime = 0.0;
  }

  // ✅ تحديث debugInfo
  Map<String, dynamic> get debugInfo => {
    'currentState': _currentBaseState.toString(),
    'currentFrame': _currentFrameIndex,
    'totalFrames': currentClip?.frames.length ?? 0,
    'currentFramePath': currentClip?.frames[_currentFrameIndex].framePath ?? '',
  };
}

class AnimationEvent {
  final String type;
  final dynamic data;
  final AnimationLayer layer;
  final double frameTime;

  const AnimationEvent({
    required this.type,
    required this.data,
    required this.layer,
    required this.frameTime,
  });
}