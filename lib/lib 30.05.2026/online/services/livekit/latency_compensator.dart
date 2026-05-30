// lib/online/services/livekit/latency_compensator.dart
class LatencyCompensator {
  final List<int> _latencySamples = [];
  int _averageLatency = 0;
  int _minLatency = 999999;
  int _maxLatency = 0;
  double _correctionFactor = 1.0;
  int _packetLossCount = 0;
  int _totalPackets = 0;

  void addLatencySample(int latencyMs) {
    _latencySamples.add(latencyMs);
    while (_latencySamples.length > 10) {
      _latencySamples.removeAt(0);
    }
    if (_latencySamples.isNotEmpty) {
      _averageLatency = _latencySamples.reduce((a, b) => a + b) ~/ _latencySamples.length;
      _minLatency = _latencySamples.reduce((a, b) => a < b ? a : b);
      _maxLatency = _latencySamples.reduce((a, b) => a > b ? a : b);
    }
    _updateCorrectionFactor();
  }

  void recordPacketLoss() { _packetLossCount++; _totalPackets++; }
  void recordSuccessfulPacket() { _totalPackets++; }

  void _updateCorrectionFactor() {
    if (_averageLatency < 50) _correctionFactor = 1.0;
    else if (_averageLatency < 100) _correctionFactor = 1.05;
    else if (_averageLatency < 200) _correctionFactor = 1.1;
    else _correctionFactor = 1.2;
  }

  double getCorrectionFactor() => _correctionFactor;
  int getAverageLatency() => _averageLatency;
  double getPacketLossRate() => _totalPackets == 0 ? 0 : _packetLossCount / _totalPackets;
  bool isConnectionGood() => _averageLatency < 100 && getPacketLossRate() < 0.05;
  bool isConnectionBad() => _averageLatency > 200 || getPacketLossRate() > 0.15;

  int getQualityScore() {
    int score = 100;
    if (_averageLatency > 50) score -= ((_averageLatency - 50) ~/ 10);
    score -= (getPacketLossRate() * 100).toInt();
    return score.clamp(0, 100);
  }

  Map<String, dynamic> getSummary() => {
    'averageLatency': _averageLatency,
    'minLatency': _minLatency == 999999 ? 0 : _minLatency,
    'maxLatency': _maxLatency,
    'correctionFactor': _correctionFactor.toStringAsFixed(2),
    'packetLossRate': '${(getPacketLossRate() * 100).toStringAsFixed(1)}%',
    'qualityScore': getQualityScore(),
    'status': isConnectionGood() ? 'good' : (isConnectionBad() ? 'bad' : 'medium'),
  };

  void reset() {
    _latencySamples.clear();
    _averageLatency = 0;
    _minLatency = 999999;
    _maxLatency = 0;
    _correctionFactor = 1.0;
    _packetLossCount = 0;
    _totalPackets = 0;
  }
}