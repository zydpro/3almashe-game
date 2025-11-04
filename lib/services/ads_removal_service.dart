// services/ads_removal_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_data_service.dart';

class AdsRemovalService with ChangeNotifier {
  static final AdsRemovalService _instance = AdsRemovalService._internal();
  factory AdsRemovalService() => _instance;
  AdsRemovalService._internal();

  bool _adsRemoved = false;
  DateTime? _expiryDate;
  bool _temporaryRemoval = false;

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      try {
        listener();
      } catch (e) {
        // تم إزالة الطباعة
      }
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    await _loadAdsStatus();
  }

  Future<void> _loadAdsStatus() async {
    try {
      final adsData = await GameDataService.getAdsRemovalData();

      _adsRemoved = adsData['adsRemoved'] as bool;
      _temporaryRemoval = adsData['temporaryRemoval'] as bool;

      final expiryTimestamp = adsData['expiryDate'] as int?;

      if (expiryTimestamp != null) {
        _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

        if (_expiryDate!.isBefore(DateTime.now())) {
          await _resetExpiredAdsRemoval();
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل حالة الإعلانات: $e');
    }
  }

  Future<void> _saveToGameData() async {
    try {
      await GameDataService.setAdsRemovalData(_adsRemoved, _temporaryRemoval, _expiryDate);
    } catch (e) {
      print('❌ خطأ في حفظ حالة الإعلانات: $e');
    }
  }

  // ✅ الدالة الرئيسية - تأخذ DateTime?
  Future<bool> purchaseAdsRemoval(DateTime? expiryDate) async {
    try {
      _adsRemoved = true;
      _temporaryRemoval = false;
      _expiryDate = expiryDate;

      await _saveToGameData();
      _notifyListeners();
      return true;
    } catch (e) {
      print('❌ خطأ في شراء إزالة الإعلانات: $e');
      return false;
    }
  }

  // ✅ دالة مساعدة للتوافق مع الكود القديم - تأخذ Duration
  Future<bool> purchaseAdsRemovalWithDuration(Duration duration) async {
    final expiryDate = DateTime.now().add(duration);
    return await purchaseAdsRemoval(expiryDate);
  }

  Future<bool> removeAdsTemporarily(Duration duration) async {
    try {
      _temporaryRemoval = true;
      _expiryDate = DateTime.now().add(duration);

      await _saveToGameData();
      _notifyListeners();
      return true;
    } catch (e) {
      print('❌ خطأ في الإزالة المؤقتة للإعلانات: $e');
      return false;
    }
  }

  bool get shouldShowAds => !isActive;

  bool get isActive {
    if (_temporaryRemoval && _expiryDate != null && _expiryDate!.isAfter(DateTime.now())) {
      return true;
    }
    if (_adsRemoved) {
      if (_expiryDate == null) return true;
      return _expiryDate!.isAfter(DateTime.now());
    }
    return false;
  }

  bool get adsRemoved => _adsRemoved || _temporaryRemoval;
  DateTime? get expiryDate => _expiryDate;
  bool get isTemporary => _temporaryRemoval;

  String getRemainingTime({bool isArabic = true}) {
    if (!isActive || _expiryDate == null) return '';

    final now = DateTime.now();
    if (_expiryDate!.isBefore(now)) return isArabic ? 'منتهية' : 'Expired';

    final remaining = _expiryDate!.difference(now);

    if (remaining.inDays > 0) {
      return isArabic ? '${remaining.inDays} يوم' : '${remaining.inDays} days';
    } else if (remaining.inHours > 0) {
      return isArabic ? '${remaining.inHours} ساعة' : '${remaining.inHours} hours';
    } else {
      return isArabic ? '${remaining.inMinutes} دقيقة' : '${remaining.inMinutes} minutes';
    }
  }

  Map<String, dynamic> getAdsStatusInfo({bool isArabic = true}) {
    return {
      'isActive': isActive,
      'isTemporary': isTemporary,
      'isLifetime': _expiryDate == null && _adsRemoved,
      'statusText': getStatusText(isArabic: isArabic),
      'remainingTime': getRemainingTime(isArabic: isArabic),
      'expiryDate': _expiryDate,
      'shouldShowAds': shouldShowAds,
    };
  }

  String getStatusText({bool isArabic = true}) {
    if (!isActive) return isArabic ? 'الإعلانات مفعلة' : 'Ads Enabled';
    if (isTemporary) return isArabic ? 'إزالة مؤقتة' : 'Temporary Removal';
    if (_expiryDate == null) return isArabic ? 'مدى الحياة' : 'Lifetime';
    return isArabic ? 'نشط' : 'Active';
  }

  Future<void> _resetExpiredAdsRemoval() async {
    _adsRemoved = false;
    _temporaryRemoval = false;
    _expiryDate = null;
    await _saveToGameData();
    _notifyListeners();
  }

  Future<void> resetAdsRemoval() async {
    _adsRemoved = false;
    _temporaryRemoval = false;
    _expiryDate = null;
    await _saveToGameData();
    _notifyListeners();
  }

  static Future<bool> checkAdsStatus() async {
    return await GameDataService.shouldShowAds();
  }
}