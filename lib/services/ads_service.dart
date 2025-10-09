import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdsService {
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

  static Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ Unity Ads already initialized');
      return;
    }

    if (_initializationCompleter != null) {
      await _initializationCompleter!.future;
      return;
    }

    _initializationCompleter = Completer<void>();

    print('🎮 Starting Unity_ads_plugin initialization...');

    try {
      // التهيئة الصحيحة حسب التوثيق
      UnityAds.init(
        gameId: _androidGameId,
        testMode: _testMode,
        onComplete: () {
          _isInitialized = true;
          print('✅ Unity_ads_plugin initialization SUCCESS');
          _loadAds();
          _initializationCompleter?.complete();
        },
        onFailed: (error, message) {
          _isInitialized = false;
          print('❌ Unity_ads_plugin initialization FAILED: $error - $message');
          _initializationCompleter?.completeError('$error: $message');
        },
      );

    } catch (e) {
      print('❌ Exception during Unity_ads_plugin initialization: $e');
      _isInitialized = false;
      _initializationCompleter?.completeError(e);
      _initializationCompleter = null;
    }
  }

  static void _loadAds() {
    print('📦 Loading ads...');

    // تحميل الإعلانات
    UnityAds.load(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        _isRewardedAdReady = true;
        print('✅ Rewarded ad loaded: $placementId');
      },
      onFailed: (placementId, error, message) {
        _isRewardedAdReady = false;
        print('❌ Rewarded ad load failed: $placementId - $error - $message');
      },
    );

    UnityAds.load(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) {
        _isInterstitialAdReady = true;
        print('✅ Interstitial ad loaded: $placementId');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialAdReady = false;
        print('❌ Interstitial ad load failed: $placementId - $error - $message');
      },
    );
  }

  static bool isRewardedAdReady() {
    final isReady = _isInitialized && _isRewardedAdReady;
    print('🔍 Rewarded ad status: $isReady');
    return isReady;
  }

  static bool isInterstitialAdReady() {
    final isReady = _isInitialized && _isInterstitialAdReady;
    print('🔍 Interstitial ad status: $isReady');
    return isReady;
  }

  static Future<bool> showRewardedAd({
    required Function() onAdStarted,
    required Function() onAdCompleted,
    required Function(String error) onAdFailed,
  }) async {
    print('🎬 Attempting to show Rewarded ad...');

    // التأكد من التهيئة أولاً
    if (!_isInitialized) {
      print('🔄 Unity Ads not initialized, attempting initialization...');
      try {
        await initialize();
      } catch (e) {
        final error = 'Failed to initialize Unity Ads: $e';
        print('❌ $error');
        onAdFailed(error);
        return false;
      }
    }

    if (!_isRewardedAdReady) {
      final error = 'Rewarded ad not ready';
      print('❌ $error');
      onAdFailed(error);
      return false;
    }

    try {
      print('🎯 Showing Rewarded ad: $_rewardedPlacementId');

      final completer = Completer<bool>();

      // عرض الإعلان مع المستمعين المباشرين
      UnityAds.showVideoAd(
        placementId: _rewardedPlacementId,
        onStart: (placementId) {
          print('▶️ Rewarded ad started: $placementId');
          onAdStarted();
        },
        onComplete: (placementId) {
          print('✅ Rewarded ad completed: $placementId');
          onAdCompleted();
          completer.complete(true);

          // إعادة تحميل الإعلان
          _loadAds();
        },
        onFailed: (placementId, error, message) {
          print('❌ Rewarded ad failed: $placementId - $error - $message');
          onAdFailed('$error: $message');
          completer.complete(false);

          // إعادة تحميل الإعلان
          _loadAds();
        },
      );

      // انتظار اكتمال الإعلان
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏰ Rewarded ad timeout');
          onAdFailed('Ad timeout');
          return false;
        },
      );

      return result;

    } catch (e) {
      print('❌ Exception in showRewardedAd: $e');
      onAdFailed(e.toString());
      return false;
    }
  }

  static Future<bool> showInterstitialAd({
    required Function() onAdStarted,
    required Function() onAdCompleted,
    required Function(String error) onAdFailed,
  }) async {
    print('🎬 Attempting to show Interstitial ad...');

    // التأكد من التهيئة أولاً
    if (!_isInitialized) {
      print('🔄 Unity Ads not initialized, attempting initialization...');
      try {
        await initialize();
      } catch (e) {
        final error = 'Failed to initialize Unity Ads: $e';
        print('❌ $error');
        onAdFailed(error);
        return false;
      }
    }

    if (!_isInterstitialAdReady) {
      final error = 'Interstitial ad not ready';
      print('❌ $error');
      onAdFailed(error);
      return false;
    }

    try {
      print('🎯 Showing Interstitial ad: $_interstitialPlacementId');

      final completer = Completer<bool>();

      // عرض الإعلان مع المستمعين المباشرين
      UnityAds.showVideoAd(
        placementId: _interstitialPlacementId,
        onStart: (placementId) {
          print('▶️ Interstitial ad started: $placementId');
          onAdStarted();
        },
        onComplete: (placementId) {
          print('✅ Interstitial ad completed: $placementId');
          onAdCompleted();
          completer.complete(true);

          // إعادة تحميل الإعلان
          _loadAds();
        },
        onFailed: (placementId, error, message) {
          print('❌ Interstitial ad failed: $placementId - $error - $message');
          onAdFailed('$error: $message');
          completer.complete(false);

          // إعادة تحميل الإعلان
          _loadAds();
        },
      );

      // انتظار اكتمال الإعلان
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏰ Interstitial ad timeout');
          onAdFailed('Ad timeout');
          return false;
        },
      );

      return result;

    } catch (e) {
      print('❌ Exception in showInterstitialAd: $e');
      onAdFailed(e.toString());
      return false;
    }
  }

  static void dispose() {
    _isInitialized = false;
    _isRewardedAdReady = false;
    _isInterstitialAdReady = false;
    _initializationCompleter = null;
    print('🧹 AdsService disposed');
  }
}

class AdPlacement {
  static const String continueGame = 'continue_game';
  static const String levelComplete = 'level_complete';
  static const String mainMenu = 'main_menu';
  static const String levelsMenu = 'levels_menu';
  static const String extraCoins = 'extra_coins';
  static const String gameOver = 'game_over';

  static bool shouldShowInterstitialAd(String placement) {
    final random = DateTime.now().millisecond % 10;
    final shouldShow = random < 7; // 70%

    print('🎲 Interstitial decision for $placement: $shouldShow');

    return shouldShow && AdsService.isInterstitialAdReady();
  }

  static bool shouldShowRewardedAd(String placement) {
    final isReady = AdsService.isRewardedAdReady();
    print('🎲 Rewarded ad ready for $placement: $isReady');
    return isReady;
  }

  static AdType getAdType(String placement) {
    switch (placement) {
      case continueGame:
        return AdType.video;
      case levelComplete:
        return AdType.interstitial;
      case mainMenu:
        return AdType.interstitial;
      case levelsMenu:
        return AdType.interstitial;
      case gameOver:
        return AdType.interstitial;
      case extraCoins:
        return AdType.video;
      default:
        return AdType.interstitial;
    }
  }
}

enum AdType {
  interstitial,
  video
}