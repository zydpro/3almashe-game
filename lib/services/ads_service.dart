// services/ads_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'ads_removal_service.dart';

class AdsService {
  static bool _adsEnabled = true;
  static bool _isInitialized = false;
  static bool _isRewardedAdReady = false;
  static bool _isInterstitialAdReady = false;
  static bool _useFallbackMode = false; // ✅ وضع Fallback

  static const String _androidGameId = '5851831';
  static const String _iosGameId = '5851830';
  static const bool _testMode = true;

  static const String _rewardedPlacementId = 'Rewarded_Android';
  static const String _interstitialPlacementId = 'Interstitial_Android';

  static Completer<void>? _initializationCompleter;

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

    print('🔄 Starting Unity Ads initialization...');

    try {
      // ✅ محاولة التهيئة مع timeout
      UnityAds.init(
        gameId: defaultTargetPlatform == TargetPlatform.iOS ? _iosGameId : _androidGameId,
        testMode: _testMode,
        onComplete: () {
          print('✅ Unity Ads initialized successfully');
          _isInitialized = true;
          _loadAds();
          _initializationCompleter?.complete();
        },
        onFailed: (error, message) {
          print('❌ Unity Ads initialization failed: $error - $message');
          _isInitialized = false;
          _useFallbackMode = true; // ✅ تفعيل وضع Fallback
          _initializationCompleter?.complete();
        },
      );

      // ✅ انتظر بحد أقصى 8 ثواني
      await _initializationCompleter!.future.timeout(
        Duration(seconds: 8),
        onTimeout: () {
          print('⏰ Unity Ads initialization timeout');
          _isInitialized = false;
          _useFallbackMode = true; // ✅ تفعيل وضع Fallback
          if (!_initializationCompleter!.isCompleted) {
            _initializationCompleter!.complete();
          }
        },
      );

    } catch (e) {
      print('❌ Unity Ads initialization error: $e');
      _isInitialized = false;
      _useFallbackMode = true; // ✅ تفعيل وضع Fallback
      if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.complete();
      }
    }
  }

  static bool shouldShowAds() {
    return _adsEnabled && !AdsRemovalService().isActive;
  }

  static void updateAdsStatus() {
    final shouldEnableAds = !AdsRemovalService().isActive;
    setAdsEnabled(shouldEnableAds);
  }

  static void _loadAds() {
    if (!_adsEnabled || _useFallbackMode) return;

    UnityAds.load(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        _isRewardedAdReady = true;
        print('✅ Rewarded ad loaded');
      },
      onFailed: (placementId, error, message) {
        _isRewardedAdReady = false;
        print('❌ Rewarded ad load failed: $error');
      },
    );

    UnityAds.load(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) {
        _isInterstitialAdReady = true;
        print('✅ Interstitial ad loaded');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialAdReady = false;
        print('❌ Interstitial ad load failed: $error');
      },
    );
  }

  static bool isRewardedAdReady() {
    if (_useFallbackMode) return true; // ✅ في وضع Fallback، الإعلانات دائماً "جاهزة"
    return _adsEnabled && _isInitialized && _isRewardedAdReady;
  }

  static bool isInterstitialAdReady() {
    if (_useFallbackMode) return true; // ✅ في وضع Fallback، الإعلانات دائماً "جاهزة"
    return _adsEnabled && _isInitialized && _isInterstitialAdReady;
  }

  static Future<bool> showRewardedAd({
    required Function() onAdStarted,
    required Function() onAdCompleted,
    required Function(String error) onAdFailed,
  }) async {
    print('🎯 showRewardedAd called - Fallback mode: $_useFallbackMode');

    // ✅ إذا كان في وضع Fallback، انتقل مباشرة
    if (_useFallbackMode || !_adsEnabled) {
      print('🔄 Fallback mode - completing without ad');
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
          print('✅ Rewarded ad started');
          onAdStarted();
        },
        onComplete: (placementId) {
          print('✅ Rewarded ad completed');
          onAdCompleted();
          completer.complete(true);
          _loadAds();
        },
        onFailed: (placementId, error, message) {
          print('❌ Rewarded ad failed: $error');
          onAdFailed('$error: $message');
          completer.complete(false);
          _loadAds();
        },
      );

      final result = await completer.future.timeout(
        Duration(seconds: 30),
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
    print('🎯 showInterstitialAd called - Fallback mode: $_useFallbackMode');

    // ✅ إذا كان في وضع Fallback، انتقل مباشرة
    if (_useFallbackMode || !_adsEnabled) {
      print('🔄 Fallback mode - completing without ad');
      onAdCompleted();
      return true;
    }

    if (!_isInitialized) {
      print('🔄 Ads not initialized, initializing...');
      try {
        await initialize();
      } catch (e) {
        print('❌ Initialization failed: $e');
        onAdFailed('Failed to initialize Unity Ads: $e');
        return false;
      }
    }

    if (!_isInterstitialAdReady) {
      print('⏳ Interstitial ad not ready');
      onAdFailed('Interstitial ad not ready');
      return false;
    }

    print('🎬 Showing interstitial ad...');

    try {
      final completer = Completer<bool>();

      UnityAds.showVideoAd(
        placementId: _interstitialPlacementId,
        onStart: (placementId) {
          print('✅ Interstitial ad started');
          onAdStarted();
        },
        onComplete: (placementId) {
          print('✅ Interstitial ad completed');
          onAdCompleted();
          completer.complete(true);
          _loadAds();
        },
        onFailed: (placementId, error, message) {
          print('❌ Interstitial ad failed: $error');
          onAdFailed('$error: $message');
          completer.complete(false);
          _loadAds();
        },
      );

      final result = await completer.future.timeout(
        Duration(seconds: 30),
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

  // ✅ دالة لفحص حالة الإعلانات
  static void printStatus() {
    print('=== ADS STATUS ===');
    print('Initialized: $_isInitialized');
    print('Ads Enabled: $_adsEnabled');
    print('Fallback Mode: $_useFallbackMode');
    print('Interstitial Ready: $_isInterstitialAdReady');
    print('Should Show Ads: ${shouldShowAds()}');
    print('==================');
  }

  static void dispose() {
    _isInitialized = false;
    _isRewardedAdReady = false;
    _isInterstitialAdReady = false;
    _initializationCompleter = null;
  }
}