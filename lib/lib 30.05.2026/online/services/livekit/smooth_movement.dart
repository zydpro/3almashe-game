// lib/online/services/livekit/smooth_movement.dart
import 'dart:ui';

class SmoothMovementController {
  // ✅ تخزين المواقع السابقة
  final List<_TimedPosition> _positionBuffer = [];
  final int _maxBufferSize = 8;

  // ✅ الموقع الحالي المعروض
  Offset _currentPosition = Offset.zero;

  // ✅ آخر موقع معروف
  Offset _lastKnownPosition = Offset.zero;
  int _lastKnownTimestamp = 0;

  // ✅ السرعة المقدرة
  Offset _estimatedVelocity = Offset.zero;

  // ✅ التأخير المقدر
  int _estimatedLatency = 0;

  // ✅ عامل التنعيم
  double _smoothFactor = 0.25;

  // ✅ إحصائيات
  int _updatesReceived = 0;
  int _framesRendered = 0;

  // ============================================================
  // ✅ تحديث موقع الخصم عند استلام بيانات جديدة
  // ============================================================
  void updateRemotePosition(double x, double y, int timestamp) {
    _updatesReceived++;
    final newPosition = Offset(x, y);

    _positionBuffer.add(_TimedPosition(
      position: newPosition,
      timestamp: timestamp,
    ));

    while (_positionBuffer.length > _maxBufferSize) {
      _positionBuffer.removeAt(0);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _estimatedLatency = now - timestamp;

    // تقدير السرعة
    if (_positionBuffer.length >= 2) {
      final newest = _positionBuffer.last;
      final oldest = _positionBuffer.first;
      final deltaTime = (newest.timestamp - oldest.timestamp) / 1000.0;

      if (deltaTime > 0 && deltaTime < 0.5) {
        _estimatedVelocity = Offset(
          (newest.position.dx - oldest.position.dx) / deltaTime,
          (newest.position.dy - oldest.position.dy) / deltaTime,
        );
        // منع السرعات الخيالية
        _estimatedVelocity = Offset(
          _estimatedVelocity.dx.clamp(-5.0, 5.0),
          _estimatedVelocity.dy.clamp(-5.0, 5.0),
        );
      }
    }

    _lastKnownPosition = newPosition;
    _lastKnownTimestamp = timestamp;

    _updateDynamicSmoothFactor();
  }

  // ============================================================
  // ✅ الحصول على الموقع المعروض (مع تنعيم)
  // ⚠️ استدعِ هذه الدالة مرة واحدة فقط في كل فريم!
  // ============================================================
  Offset getSmoothedPosition(double deltaTimeSeconds) {
    _framesRendered++;

    if (_positionBuffer.isEmpty) {
      return _currentPosition;
    }

    // إذا كان التأخير كبيراً → انتقل فوراً
    if (_estimatedLatency > 300) {
      _currentPosition = _lastKnownPosition;
      return _currentPosition;
    }

    // تعويض التأخير
    final compensatedPosition = _compensateLag();

    // تنعيم سلس
    _currentPosition = Offset(
      _currentPosition.dx + (compensatedPosition.dx - _currentPosition.dx) * _smoothFactor,
      _currentPosition.dy + (compensatedPosition.dy - _currentPosition.dy) * _smoothFactor,
    );

    return _currentPosition;
  }

  // ============================================================
  // ✅ تعويض التأخير
  // ============================================================
  Offset _compensateLag() {
    if (_estimatedLatency <= 0 || _estimatedLatency > 200) {
      return _lastKnownPosition;
    }

    final latencySeconds = _estimatedLatency / 1000.0;

    return Offset(
      _lastKnownPosition.dx + (_estimatedVelocity.dx * latencySeconds),
      _lastKnownPosition.dy + (_estimatedVelocity.dy * latencySeconds),
    );
  }

  // ============================================================
  // ✅ تحديث عامل التنعيم ديناميكياً
  // ============================================================
  void _updateDynamicSmoothFactor() {
    if (_estimatedLatency < 50) {
      _smoothFactor = 0.35;  // اتصال ممتاز → استجابة أسرع
    } else if (_estimatedLatency < 150) {
      _smoothFactor = 0.25;  // اتصال جيد → تنعيم متوسط
    } else {
      _smoothFactor = 0.15;  // اتصال سيء → تنعيم أكثر
    }
  }

  // ============================================================
  // ✅ إعادة تعيين
  // ============================================================
  void reset() {
    _positionBuffer.clear();
    _currentPosition = Offset.zero;
    _lastKnownPosition = Offset.zero;
    _estimatedVelocity = Offset.zero;
    _estimatedLatency = 0;
    _updatesReceived = 0;
    _framesRendered = 0;
  }
}

class _TimedPosition {
  final Offset position;
  final int timestamp;
  _TimedPosition({required this.position, required this.timestamp});
}