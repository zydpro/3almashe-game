import 'dart:async';
import 'package:flutter/foundation.dart';

class AdsService {
  static bool _isInitialized = false;
  static bool _isRewardedAdReady = false;
  static bool _isInterstitialAdReady = false;
  static bool _isBannerAdReady = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Future.delayed(const Duration(seconds: 1));

      _isInitialized = true;
      _loadRewardedAd();
      _loadInterstitialAd();
      _loadBannerAd();

      if (kDebugMode) {
        print('Unity Ads initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Unity Ads: $e');
      }
    }
  }

  static Future<void> _loadRewardedAd() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      _isRewardedAdReady = true;

      if (kDebugMode) {
        print('Rewarded ad loaded');
      }
    } catch (e) {
      _isRewardedAdReady = false;
      if (kDebugMode) {
        print('Failed to load rewarded ad: $e');
      }
    }
  }

  static Future<void> _loadInterstitialAd() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      _isInterstitialAdReady = true;

      if (kDebugMode) {
        print('Interstitial ad loaded');
      }
    } catch (e) {
      _isInterstitialAdReady = false;
      if (kDebugMode) {
        print('Failed to load interstitial ad: $e');
      }
    }
  }

  static Future<void> _loadBannerAd() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      _isBannerAdReady = true;

      if (kDebugMode) {
        print('Banner ad loaded');
      }
    } catch (e) {
      _isBannerAdReady = false;
      if (kDebugMode) {
        print('Failed to load banner ad: $e');
      }
    }
  }

  static bool isRewardedAdReady() {
    return _isRewardedAdReady;
  }

  static bool isInterstitialAdReady() {
    return _isInterstitialAdReady;
  }

  static bool isBannerAdReady() {
    return _isBannerAdReady;
  }

  static Future<bool> showRewardedAd({
    required Function() onAdStarted,
    required Function() onAdCompleted,
    required Function(String error) onAdFailed,
  }) async {
    if (!_isInitialized || !_isRewardedAdReady) {
      onAdFailed('Rewarded ad not ready');
      return false;
    }

    try {
      onAdStarted();

      await Future.delayed(const Duration(seconds: 5));

      onAdCompleted();

      _isRewardedAdReady = false;
      _loadRewardedAd();

      return true;
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
    if (!_isInitialized || !_isInterstitialAdReady) {
      onAdFailed('Interstitial ad not ready');
      return false;
    }

    try {
      onAdStarted();

      await Future.delayed(const Duration(seconds: 3));

      onAdCompleted();

      _isInterstitialAdReady = false;
      _loadInterstitialAd();

      return true;
    } catch (e) {
      onAdFailed(e.toString());
      return false;
    }
  }

  static Future<bool> showBannerAd({
    required Function() onAdShown,
    required Function(String error) onAdFailed,
  }) async {
    if (!_isInitialized || !_isBannerAdReady) {
      onAdFailed('Banner ad not ready');
      return false;
    }

    try {
      onAdShown();
      return true;
    } catch (e) {
      onAdFailed(e.toString());
      return false;
    }
  }

  static void dispose() {
    _isInitialized = false;
    _isRewardedAdReady = false;
    _isInterstitialAdReady = false;
    _isBannerAdReady = false;
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
    switch (placement) {
      case levelComplete:
        return true;
      case mainMenu:
        return true;
      case levelsMenu:
        return true;
      case gameOver:
        return true;
      default:
        return false;
    }
  }

  static bool shouldShowRewardedAd(String placement) {
    switch (placement) {
      case continueGame:
        return AdsService.isRewardedAdReady();
      case extraCoins:
        return AdsService.isRewardedAdReady();
      default:
        return false;
    }
  }

  static bool shouldShowBannerAd(String placement) {
    switch (placement) {
      case mainMenu:
        return AdsService.isBannerAdReady();
      case levelsMenu:
        return AdsService.isBannerAdReady();
      case gameOver:
        return AdsService.isBannerAdReady();
      default:
        return false;
    }
  }

  static AdType getAdType(String placement) {
    switch (placement) {
      case continueGame:
        return AdType.video;
      case levelComplete:
        return AdType.image;
      case mainMenu:
        return AdType.image;
      case levelsMenu:
        return AdType.image;
      case gameOver:
        return AdType.image;
      case extraCoins:
        return AdType.video;
      default:
        return AdType.image;
    }
  }
}

enum AdType {
  image,
  video,
  banner
}