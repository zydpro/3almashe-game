# دليل إعداد وتشغيل لعبة عالماشي

## المتطلبات الأساسية

### 1. تثبيت Flutter
```bash
# تحميل Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# التحقق من التثبيت
flutter doctor
```

### 2. إعداد بيئة التطوير

#### Android Studio
- تحميل وتثبيت Android Studio
- تثبيت Android SDK
- إنشاء Android Virtual Device (AVD)

#### VS Code (اختياري)
- تثبيت إضافة Flutter
- تثبيت إضافة Dart

## خطوات التشغيل

### 1. تحضير المشروع
```bash
# الانتقال لمجلد المشروع
cd 3almashe_game

# تثبيت التبعيات
flutter pub get

# التحقق من عدم وجود مشاكل
flutter doctor
```

### 2. تشغيل اللعبة

#### على المحاكي
```bash
# تشغيل المحاكي
flutter emulators --launch <emulator_id>

# تشغيل اللعبة
flutter run
```

#### على الجهاز الفعلي
```bash
# تفعيل وضع المطور على الجهاز
# تفعيل USB Debugging
# توصيل الجهاز بالكمبيوتر

# التحقق من اتصال الجهاز
flutter devices

# تشغيل اللعبة
flutter run
```

## إعداد الإعلانات (Unity Ads)

### 1. إنشاء حساب Unity
- اذهب إلى https://dashboard.unity3d.com/
- أنشئ حساب جديد أو سجل دخول
- أنشئ مشروع جديد

### 2. إعداد Unity Ads
```bash
# في Unity Dashboard:
# 1. اذهب إلى Monetization > Ad Units
# 2. أنشئ Rewarded Video Ad Unit
# 3. أنشئ Interstitial Ad Unit
# 4. احصل على Game ID
```

### 3. تحديث الكود
في ملف `lib/services/ads_service.dart`:
```dart
// استبدل هذه القيم بقيمك الحقيقية
static const String _gameId = 'YOUR_UNITY_GAME_ID';
static const String _rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';
static const String _interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
```

### 4. إعداد المنصات

#### Android
في `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 33
    minSdkVersion 21
    targetSdkVersion 33
}

dependencies {
    implementation 'com.unity3d.ads:unity-ads:4.4.1'
}
```

#### iOS
في `ios/Runner/Info.plist`:
```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4fzdc2evr5.skadnetwork</string>
    </dict>
</array>
```

## بناء اللعبة للإنتاج

### Android

#### APK للاختبار
```bash
flutter build apk --debug
```

#### APK للإنتاج
```bash
flutter build apk --release
```

#### App Bundle للنشر على Google Play
```bash
flutter build appbundle --release
```

### iOS

#### للاختبار على الجهاز
```bash
flutter build ios --debug
```

#### للإنتاج
```bash
flutter build ios --release
```

## حل المشاكل الشائعة

### 1. مشكلة Gradle Build
```bash
# تنظيف المشروع
flutter clean
flutter pub get

# إعادة بناء المشروع
flutter build apk
```

### 2. مشكلة SDK Versions
في `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

### 3. مشكلة الخطوط العربية
تأكد من وجود ملفات الخطوط في:
```
assets/fonts/
├── NotoSansArabic-Regular.ttf
└── NotoSansArabic-Bold.ttf
```

### 4. مشكلة الإعلانات
```dart
// تأكد من تهيئة الإعلانات في main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService.initialize();
  runApp(const AlmasheGame());
}
```

## اختبار اللعبة

### 1. اختبار الوظائف الأساسية
- [ ] تشغيل اللعبة بدون أخطاء
- [ ] حركة الشخصية (يسار/يمين)
- [ ] ظهور العقبات والتصادم
- [ ] نظام النقاط
- [ ] القوى الخاصة

### 2. اختبار المراحل
- [ ] الانتقال بين المراحل
- [ ] حفظ التقدم
- [ ] فتح المراحل الجديدة
- [ ] اختلاف الصعوبة

### 3. اختبار الإعلانات
- [ ] ظهور إعلان الاستمرار
- [ ] إعلانات بين المراحل
- [ ] مكافآت الإعلانات

### 4. اختبار الواجهة
- [ ] دعم اللغة العربية
- [ ] الأنيميشن والتأثيرات
- [ ] استجابة الأزرار
- [ ] التنقل بين الشاشات

## نشر اللعبة

### Google Play Store

#### 1. إعداد الحساب
- إنشاء حساب Google Play Developer
- دفع رسوم التسجيل ($25)

#### 2. تحضير الملفات
```bash
# بناء App Bundle
flutter build appbundle --release

# الملف سيكون في:
# build/app/outputs/bundle/release/app-release.aab
```

#### 3. معلومات التطبيق
- اسم التطبيق: عالماشي - 3almashe
- الوصف: لعبة جري لا نهائية ممتعة
- الفئة: الألعاب > الأركيد
- التقييم: للجميع

### Apple App Store

#### 1. إعداد الحساب
- إنشاء حساب Apple Developer
- دفع الاشتراك السنوي ($99)

#### 2. تحضير الملفات
```bash
# بناء للإنتاج
flutter build ios --release

# رفع عبر Xcode أو Application Loader
```

## الصيانة والتحديثات

### 1. تحديث Flutter
```bash
flutter upgrade
flutter pub upgrade
```

### 2. إضافة ميزات جديدة
- مراحل إضافية
- شخصيات جديدة
- قوى خاصة جديدة
- تحسينات الأداء

### 3. إصلاح الأخطاء
- مراقبة تقارير الأخطاء
- تحديث التبعيات
- اختبار شامل قبل النشر

## الدعم الفني

للحصول على المساعدة:
1. راجع الوثائق الرسمية لـ Flutter
2. تحقق من مجتمع Flutter على GitHub
3. اتصل بفريق الدعم

---

**نتمنى لك تجربة تطوير ممتعة! 🚀**

