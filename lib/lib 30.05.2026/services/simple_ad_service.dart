// import 'dart:async';
// import 'package:flutter/foundation.dart';
//
// class SimpleAdService {
//   static bool _isInitialized = true; // دائماً مهيء
//   static bool _isRewardedAdReady = true; // دائماً جاهز
//   static bool _isInterstitialAdReady = true; // دائماً جاهز
//
//   static Future<void> initialize() async {
//     print('✅ SimpleAdService initialized successfully');
//     _isInitialized = true;
//     _isRewardedAdReady = true;
//     _isInterstitialAdReady = true;
//   }
//
//   static bool isRewardedAdReady() {
//     return _isInitialized && _isRewardedAdReady;
//   }
//
//   static bool isInterstitialAdReady() {
//     return _isInitialized && _isInterstitialAdReady;
//   }
//
//   static Future<bool> showRewardedAd({
//     required Function() onAdStarted,
//     required Function() onAdCompleted,
//     required Function(String error) onAdFailed,
//   }) async {
//     print('🎬 Showing SIMULATED Rewarded Ad');
//
//     if (!_isInitialized) {
//       onAdFailed('Ad service not initialized');
//       return false;
//     }
//
//     try {
//       // محاكاة بدء الإعلان
//       onAdStarted();
//       print('▶️ Simulated Rewarded Ad Started');
//
//       // محاكاة فترة عرض الإعلان (5 ثواني)
//       await Future.delayed(const Duration(seconds: 5));
//
//       // محاكاة اكتمال الإعلان
//       onAdCompleted();
//       print('✅ Simulated Rewarded Ad Completed');
//
//       return true;
//     } catch (e) {
//       onAdFailed('Ad simulation failed: $e');
//       return false;
//     }
//   }
//
//   static Future<bool> showInterstitialAd({
//     required Function() onAdStarted,
//     required Function() onAdCompleted,
//     required Function(String error) onAdFailed,
//   }) async {
//     print('🎬 Showing SIMULATED Interstitial Ad');
//
//     if (!_isInitialized) {
//       onAdFailed('Ad service not initialized');
//       return false;
//     }
//
//     try {
//       // محاكاة بدء الإعلان
//       onAdStarted();
//       print('▶️ Simulated Interstitial Ad Started');
//
//       // محاكاة فترة عرض الإعلان (3 ثواني)
//       await Future.delayed(const Duration(seconds: 3));
//
//       // محاكاة اكتمال الإعلان
//       onAdCompleted();
//       print('✅ Simulated Interstitial Ad Completed');
//
//       return true;
//     } catch (e) {
//       onAdFailed('Ad simulation failed: $e');
//       return false;
//     }
//   }
//
//   static void dispose() {
//     print('🧹 SimpleAdService disposed');
//   }
// }