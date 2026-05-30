import 'advanced_animation_system.dart';

class AnimationStateMachine {
  // ✅ إضافة نظام القفل
  bool _locked = false;
  String? _lockReason;

  bool get isLocked => _locked;
  String? get lockReason => _lockReason;

  final Map<AnimationState, AnimationStateConfig> _states;
  final Map<String, AnimationTransitionRule> _transitionRules;
  AnimationState _currentState;

  AnimationStateMachine({
    required Map<AnimationState, AnimationStateConfig> states,
    required AnimationState initialState,
  })  : _states = states,
        _currentState = initialState,
        _transitionRules = {};

  void addTransitionRule(AnimationTransitionRule rule) {
    _transitionRules[rule.id] = rule;
    print('✅ تم إضافة قاعدة: ${rule.id} (${rule.fromState} -> ${rule.toState})');
  }

  void lock({String reason = ''}) {
    _locked = true;
    _lockReason = reason;
    print('🔒 قفل State Machine - السبب: $reason');
  }

  void unlock() {
    _locked = false;
    print('🔓 فتح State Machine - كان مقفولاً بسبب: $_lockReason');
    _lockReason = null;
  }

  void evaluate(Map<String, dynamic> context) {
    // ✅ لا نسمح بالانتقالات إذا كان النظام مقفولاً
    if (_locked) {
      print('⏸️ انتقال مرفوض - State Machine مقفول | السبب: $_lockReason');
      return;
    }

    final nextState = evaluateNextState(_currentState, context);
    if (nextState != null && nextState != _currentState) {
      print('🎉 State Machine تتغير: $_currentState -> $nextState');
      _currentState = nextState;
    }
  }

  // ✅ إضافة دالة للتحقق من الانتقالات المباشرة
  bool canTransitionTo(AnimationState newState, Map<String, dynamic> context) {
    return true; // نظام مبسط
  }

  AnimationState? evaluateNextState(AnimationState currentState, Map<String, dynamic> context) {
    if (_transitionRules.isEmpty) return null;

    print('🔍 فحص ${_transitionRules.length} قاعدة انتقال من $currentState...');

    AnimationTransitionRule? matchedRule;
    double highestPriority = 0.0;

    for (final rule in _transitionRules.values) {
      // ✅ التحقق من الانتقال من الحالة الحالية أو من أي حالة
      final canTransitionFromCurrent = rule.fromState == currentState;
      final canTransitionFromAny = rule.fromState.toString() == 'any';

      if (canTransitionFromCurrent || canTransitionFromAny) {
        final canTransition = rule.condition(context);
        print('   📋 ${rule.id}: ${rule.fromState} -> ${rule.toState} = $canTransition (أولوية: ${rule.priority})');

        if (canTransition && rule.priority >= highestPriority) {
          matchedRule = rule;
          highestPriority = rule.priority;
        }
      }
    }

    if (matchedRule != null) {
      print('   ✅ انتقل: ${matchedRule.fromState} -> ${matchedRule.toState} (الأولوية: $highestPriority)');
      return matchedRule.toState;
    }

    print('   ❌ لا توجد انتقالات متاحة من $currentState');
    return null;
  }

  void update(Map<String, dynamic> context) {
    // ✅ لا نسمح بالانتقالات إذا كان النظام مقفولاً
    if (_locked) {
      return;
    }

    final nextState = evaluateNextState(_currentState, context);
    if (nextState != null && nextState != _currentState) {
      print('🎉 State Machine تتغير: $_currentState -> $nextState');
      _currentState = nextState;
    }
  }

  AnimationState get currentState => _currentState;
  AnimationStateConfig get currentConfig => _states[_currentState]!;

}

class AnimationStateConfig {
  final AnimationState state;
  final bool canBeInterrupted;
  final List<AnimationState> interruptibleBy;
  final Map<String, dynamic> properties;

  const AnimationStateConfig({
    required this.state,
    this.canBeInterrupted = true,
    this.interruptibleBy = const [],
    this.properties = const {},
  });
}

class AnimationTransitionRule {
  final String id;
  final AnimationState fromState;
  final AnimationState toState;
  final bool Function(Map<String, dynamic> context) condition;
  final double priority;

  const AnimationTransitionRule({
    required this.id,
    required this.fromState,
    required this.toState,
    required this.condition,
    this.priority = 1.0,
  });
}