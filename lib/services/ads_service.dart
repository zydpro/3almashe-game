// services/ads_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdsService {
  static bool _adsEnabled = true; // ✅ تفعيل الإعلانات
  static bool _isInitialized = false;
  static bool _isRewardedAdReady = false;
  static bool _isInterstitialAdReady = false;

  // ⚠️ استبدل هذه بمعرفات حسابك الحقيقية
  static const String _androidGameId = '5851831';
  static const String _iosGameId = '5851830';
  static const bool _testMode = true;

  // ⚠️ استبدل هذه بمعرفات الـ Placements من حسابك
  static const String _rewardedPlacementId = 'Rewarded_Android';
  static const String _interstitialPlacementId = 'Interstitial_Android';

  static Completer<void>? _initializationCompleter;

  // ⭐ دالة التحكم في الإعلانات
  static void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
  }

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (_initializationCompleter != null) {
      await _initializationCompleter!.future;
      return;
    }

    _initializationCompleter = Completer<void>();

    try {
      UnityAds.init(
        gameId: defaultTargetPlatform == TargetPlatform.iOS ? _iosGameId : _androidGameId,
        testMode: _testMode,
        onComplete: () {
          _isInitialized = true;
          _loadAds();
          _initializationCompleter?.complete();
        },
        onFailed: (error, message) {
          _isInitialized = false;
          _initializationCompleter?.completeError('$error: $message');
        },
      );

    } catch (e) {
      _isInitialized = false;
      _initializationCompleter?.completeError(e);
      _initializationCompleter = null;
    }
  }

  static void _loadAds() {
    if (!_adsEnabled) return;

    UnityAds.load(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        _isRewardedAdReady = true;
      },
      onFailed: (placementId, error, message) {
        _isRewardedAdReady = false;
      },
    );

    UnityAds.load(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) {
        _isInterstitialAdReady = true;
      },
      onFailed: (placementId, error, message) {
        _isInterstitialAdReady = false;
      },
    );
  }

  static bool isRewardedAdReady() {
    return _adsEnabled && _isInitialized && _isRewardedAdReady;
  }

  static bool isInterstitialAdReady() {
    return _adsEnabled && _isInitialized && _isInterstitialAdReady;
  }

  static Future<bool> showRewardedAd({
    required Function() onAdStarted,
    required Function() onAdCompleted,
    required Function(String error) onAdFailed,
  }) async {
    if (!_adsEnabled) {
      // ✅ إعطاء 20 عملة بدلاً من 50 عند تعطيل الإعلانات
      onAdCompleted();
      return true;
    }

    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        onAdFailed('Failed to initialize Unity Ads: $e');
        return false;
      }
    }

    if (!_isRewardedAdReady) {
      onAdFailed('Rewarded ad not ready');
      return false;
    }

    try {
      final completer = Completer<bool>();

      UnityAds.showVideoAd(
        placementId: _rewardedPlacementId,
        onStart: (placementId) {
          onAdStarted();
        },
        onComplete: (placementId) {
          onAdCompleted();
          completer.complete(true);
          _loadAds();
        },
        onFailed: (placementId, error, message) {
          onAdFailed('$error: $message');
          completer.complete(false);
          _loadAds();
        },
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          onAdFailed('Ad timeout');
          return false;
        },
      );

      return result;

    } catch (e) {
      onAdFailed(e.toString());
      return false;
    }
  }

  static Future<bool> showInterstitialAd({
    required Function() onAdStarted,
    required Function() onAdCompleted,
    required Function(String error) onAdFailed,
  }) async {
    if (!_adsEnabled) {
      onAdCompleted();
      return true;
    }

    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        onAdFailed('Failed to initialize Unity Ads: $e');
        return false;
      }
    }

    if (!_isInterstitialAdReady) {
      onAdFailed('Interstitial ad not ready');
      return false;
    }

    try {
      final completer = Completer<bool>();

      UnityAds.showVideoAd(
        placementId: _interstitialPlacementId,
        onStart: (placementId) {
          onAdStarted();
        },
        onComplete: (placementId) {
          onAdCompleted();
          completer.complete(true);
          _loadAds();
        },
        onFailed: (placementId, error, message) {
          onAdFailed('$error: $message');
          completer.complete(false);
          _loadAds();
        },
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          onAdFailed('Ad timeout');
          return false;
        },
      );

      return result;

    } catch (e) {
      onAdFailed(e.toString());
      return false;
    }
  }

  static void dispose() {
    _isInitialized = false;
    _isRewardedAdReady = false;
    _isInterstitialAdReady = false;
    _initializationCompleter = null;
  }
}