import 'package:almashe_game/screens/splash_screens.dart';
import 'package:almashe_game/services/ads_removal_service.dart';
import 'package:almashe_game/services/game_data_service.dart';
import 'package:almashe_game/services/payment_service.dart';
import 'package:almashe_game/services/settings_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'Languages/LanguageProvider.dart';
import 'online/firebase/firebase_options.dart';
import 'online/screens/online_lobby_screen.dart';
import 'online/screens/online_main_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/image_service.dart';
import 'package:almashe_game/Languages/localization.dart';
import 'package:almashe_game/Languages/language_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // ✅ للتأكد من وضع التطوير

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeServices();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => GameDataService()),
          ChangeNotifierProvider(create: (_) => AdsRemovalService()),
          ChangeNotifierProvider(create: (_) => PaymentService()),
        ],
        child: const AlmasheGame(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('خطأ في التطبيق: $e'),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeServices() async {
  // ✅ تهيئة Firebase أولاً
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');



    // ✅ إذا كنا في وضع التطوير، استخدم المحاكي المحلي
    // if (kDebugMode) {
    //   try {
    //     // استخدم المحاكي المحلي (افتح Firebase Emulator أولاً)
    //     FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    //     FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    //     print('✅ Using Firebase Emulator (localhost:8080, 9099)');
    //   } catch (e) {
    //     print('⚠️ Failed to connect to Firebase Emulator: $e');
    //     print('⚠️ استمرار باستخدام Firebase السحابي...');
    //   }
    // }

  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // ثم تهيئة الخدمات الأخرى
  await AdsRemovalService().initialize();
  await SettingsService().initialize();
  await AdsService.initialize();
  await AudioService().initialize();
  await LanguageService.initialize();
  await PaymentService().initialize();

  await _fixCoinSystemIfNeeded();
}

Future<void> _fixCoinSystemIfNeeded() async {
  try {
    final currentCoins = await GameDataService.getCoins();

    if (currentCoins <= 0) {
      await GameDataService.setCoins(1);
    }
  } catch (e) {
    await GameDataService.setCoins(1);
  }
}

class AlmasheGame extends StatelessWidget {
  const AlmasheGame({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ImageService.preloadImages(context);
    });

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'عالماشي - 3almashe',
          debugShowCheckedModeBanner: false,

          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('ar'),
            const Locale('en'),
          ],
          locale: languageProvider.locale,

          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Cairo',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Cairo'),
              bodyMedium: TextStyle(fontFamily: 'Cairo'),
              displayLarge: TextStyle(fontFamily: 'Cairo'),
              displayMedium: TextStyle(fontFamily: 'Cairo'),
              displaySmall: TextStyle(fontFamily: 'Cairo'),
              headlineLarge: TextStyle(fontFamily: 'Cairo'),
              headlineMedium: TextStyle(fontFamily: 'Cairo'),
              headlineSmall: TextStyle(fontFamily: 'Cairo'),
              titleLarge: TextStyle(fontFamily: 'Cairo'),
              titleMedium: TextStyle(fontFamily: 'Cairo'),
              titleSmall: TextStyle(fontFamily: 'Cairo'),
              labelLarge: TextStyle(fontFamily: 'Cairo'),
              labelMedium: TextStyle(fontFamily: 'Cairo'),
              labelSmall: TextStyle(fontFamily: 'Cairo'),
              bodySmall: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          home: const OnlineMainScreen(),
        );
      },
    );
  }
}