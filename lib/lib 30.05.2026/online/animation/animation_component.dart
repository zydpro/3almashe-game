import 'dart:ui';

import 'advanced_animation_system.dart';
import 'animation_manager.dart';
import 'animation_state_machine.dart';

class AnimationComponent {
  final String characterId;
  final String instanceId;
  late final AdvancedAnimationController _controller;
  late final AnimationStateMachine _stateMachine;

  // ✅ إضافة تعريف transitions
  // List<AnimationTransitionRule> transitions = [];

  final Map<AnimationLayer, String> _currentFramePaths = {};
  bool _isInitialized = false;

  AnimationComponent({
    required this.characterId,
    required this.instanceId,
  }) {
    _initialize();
  }

  void _initialize() {
    final manager = AnimationManager();
    _controller = manager.createController(characterId, instanceId);

    // إنشاء State Machine أساسية
    _stateMachine = manager.createStateMachine(
      instanceId,
      _getDefaultStateConfigs(),
      AnimationState.idle,
    );

    _setupDefaultTransitions();
    _isInitialized = true;
  }

  Map<AnimationState, AnimationStateConfig> _getDefaultStateConfigs() {
    return {
      AnimationState.idle: AnimationStateConfig(
        state: AnimationState.idle,
        canBeInterrupted: true,
        interruptibleBy: AnimationState.values.where((state) => state != AnimationState.idle).toList(),
      ),
      AnimationState.running: AnimationStateConfig(
        state: AnimationState.running,
        canBeInterrupted: true,
      ),
      AnimationState.attacking_light: AnimationStateConfig(
        state: AnimationState.attacking_light,
        canBeInterrupted: false,
        properties: {'cancelWindow': 0.3},
      ),
      // إضافة باقي الحالات...
    };
  }

  // قراءة من الـ context مع دعم عدة صيغ للمفتاح
  bool _ctxBool(Map<String, dynamic> ctx, String snakeKey) {
    if (ctx == null || ctx.isEmpty) return false;

    // 1) مباشرة snake_case
    if (ctx.containsKey(snakeKey)) {
      final value = ctx[snakeKey];
      return _convertToBool(value);
    }

    // 2) camelCase (is_moving -> isMoving)
    final camel = snakeKey.replaceAllMapped(RegExp(r'_([a-z])'),
            (m) => m[1]!.toUpperCase());
    if (ctx.containsKey(camel)) {
      final value = ctx[camel];
      return _convertToBool(value);
    }

    // 3) compact (is_moving -> ismoving)
    final compact = snakeKey.replaceAll('_', '');
    if (ctx.containsKey(compact)) {
      final value = ctx[compact];
      return _convertToBool(value);
    }

    return false;
  }

  void _setupDefaultTransitions() {
    // ✅ نظام انتقالات مبسط جداً - إزالة التعقيد
    final simpleRules = [
      AnimationTransitionRule(
        id: 'any_to_attack_light',
        fromState: AnimationState.values.first, // أي حالة
        toState: AnimationState.attacking_light,
        condition: (context) => _ctxBool(context, 'is_attacking_light'),
        priority: 100.0,
      ),
      AnimationTransitionRule(
        id: 'any_to_attack_heavy',
        fromState: AnimationState.values.first,
        toState: AnimationState.attacking_heavy,
        condition: (context) => _ctxBool(context, 'is_attacking_heavy'),
        priority: 100.0,
      ),
      AnimationTransitionRule(
        id: 'any_to_hit',
        fromState: AnimationState.values.first,
        toState: AnimationState.hurt,
        condition: (context) => _ctxBool(context, 'is_hit'),
        priority: 110.0,
      ),
      AnimationTransitionRule(
        id: 'any_to_dead',
        fromState: AnimationState.values.first,
        toState: AnimationState.death,
        condition: (context) => _ctxBool(context, 'is_dead'),
        priority: 120.0,
      ),
    ];

    for (final rule in simpleRules) {
      _stateMachine.addTransitionRule(rule);
    }

    print('✅ تم إعداد نظام انتقالات مبسط');
  }

  bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value.abs() > 0.0001;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  // ✅ التحديث الرئيسي
  void update(double deltaTime, Map<String, dynamic> context) {
    if (!_isInitialized) return;

    try {
      // ✅ تحديث State Machine (للحالات الخاصة فقط)
      _stateMachine.update(context);

      // ✅ استخدام الحالة من State Machine فقط للحالات الخاصة
      final specialState = _stateMachine.currentState;
      final currentState = _controller.currentState;

      // ✅ الانتقال فقط للحالات الخاصة (هجوم، ضرر، موت)
      if (_isSpecialState(specialState) && currentState != specialState) {
        _controller.transitionToState(specialState, blendDuration: 100.0);
      }

      // ✅ تحديث المتحكم
      _controller.update(deltaTime);
      _updateCurrentFrames();

    } catch (e) {
      print('❌ خطأ في update: $e');
    }
  }

  bool _isSpecialState(AnimationState state) {
    return state == AnimationState.attacking_light ||
        state == AnimationState.attacking_heavy ||
        state == AnimationState.hurt ||
        state == AnimationState.death;
  }

  void _updateCurrentFrames() {
    for (final layer in AnimationLayer.values) {
      _currentFramePaths[layer] = _controller.getCurrentFramePath(layer);
    }
  }

  // void _processAnimationEvents() {
  //   final events = _controller.getPendingEvents();
  //   for (final event in events) {
  //     _handleAnimationEvent(event);
  //   }
  // }

  // void _handleAnimationEvent(AnimationEvent event) {
  //   switch (event.type) {
  //     case 'hitbox':
  //       _spawnHitbox(event.data);
  //       break;
  //     case 'sfx':
  //       _playSoundEffect(event.data);
  //       break;
  //     case 'footstep':
  //       _playFootstepSound();
  //       break;
  //     case 'cancel_window_start':
  //       _enableCanceling();
  //       break;
  //     case 'cancel_window_end':
  //       _disableCanceling();
  //       break;
  //   }
  // }

  // void _spawnHitbox(dynamic data) {
  //   // تنفيذ إنشاء Hitbox
  // }
  //
  // void _playSoundEffect(dynamic data) {
  //   // تنفيذ تشغيل الصوت
  // }
  //
  // void _playFootstepSound() {
  //   // تنفيذ صوت الخطوات
  // }
  //
  // void _enableCanceling() {
  //   // تمكين إلغاء الحركة
  // }
  //
  // void _disableCanceling() {
  //   // تعطيل إلغاء الحركة
  // }

  // ✅ Getters
  String getCurrentFrame(AnimationLayer layer) =>
      _currentFramePaths[layer] ?? '';

  double getLayerWeight(AnimationLayer layer) =>
      _controller.getLayerWeight(layer);

  Offset consumeRootMotion() => _controller.consumeRootMotion();

  void dispose() {
    AnimationManager().disposeController(instanceId);
  }
}