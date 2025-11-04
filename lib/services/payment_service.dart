import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_data_service.dart';
import 'ads_removal_service.dart';

class PaymentService with ChangeNotifier {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  Set<String> _productIds = {};
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ✅ منتجات العملات بالدولار - معرفات Google Play
  static const Map<String, Map<String, dynamic>> coinProducts = {
    'coins_100': {
      'price': 0.99,
      'coins': 100,
      'description_ar': '100 عملة لشراء الشخصيات والتحسينات',
      'description_en': '100 coins for characters and upgrades',
    },
    'coins_500': {
      'price': 3.99,
      'coins': 500,
      'description_ar': '500 عملة لحزمة كبيرة من المحتويات',
      'description_en': '500 coins for a large content pack',
    },
    'coins_1000': {
      'price': 6.99,
      'coins': 1000,
      'description_ar': '1000 عملة لباقة مميزة من المزايا',
      'description_en': '1000 coins for premium features',
    },
    'coins_5000': {
      'price': 19.99,
      'coins': 5000,
      'description_ar': '5000 عملة للحزمة المثالية للمحترفين',
      'description_en': '5000 coins for the ultimate pro pack',
    },
  };

  // ✅ منتجات إزالة الإعلانات بالدولار
  static const Map<String, Map<String, dynamic>> adsRemovalProducts = {
    'remove_ads_1day': {
      'price': 0.49,
      'duration': '1day',
      'description_ar': 'إزالة الإعلانات لمدة 24 ساعة',
      'description_en': 'Remove ads for 24 hours',
    },
    'remove_ads_1week': {
      'price': 2.99,
      'duration': '1week',
      'description_ar': 'إزالة الإعلانات لمدة أسبوع',
      'description_en': 'Remove ads for 1 week',
    },
    'remove_ads_1month': {
      'price': 4.99,
      'duration': '1month',
      'description_ar': 'إزالة الإعلانات لمدة شهر',
      'description_en': 'Remove ads for 1 month',
    },
    'remove_ads_1year': {
      'price': 9.99,
      'duration': '1year',
      'description_ar': 'إزالة الإعلانات لمدة سنة',
      'description_en': 'Remove ads for 1 year',
    },
    'remove_ads_lifetime': {
      'price': 14.99,
      'duration': 'lifetime',
      'description_ar': 'إزالة الإعلانات مدى الحياة',
      'description_en': 'Remove ads for lifetime',
    },
  };

  // ✅ الخصائص العامة
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;
  String? get errorMessage => _errorMessage;

  // ✅ تهيئة نظام الدفع
  Future<void> initialize() async {
    try {
      print('🔄 Starting payment system initialization...');
      print('🔄 بدء تهيئة نظام الدفع...');

      // التحقق من توفر نظام الدفع
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        _errorMessage = 'Payment system not available on this device';
        print('⚠️ $_errorMessage');
        print('⚠️ نظام الدفع غير متاح على هذا الجهاز');
        return;
      }

      // ✅ تهيئة Google Play Billing للأندرويد فقط
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _initializeGooglePlayBilling();
      }

      // تحديد جميع معرفات المنتجات
      _productIds = {...coinProducts.keys, ...adsRemovalProducts.keys};
      print('🛒 معرفات المنتجات: $_productIds');

      // تحميل المنتجات
      await _loadProducts();

      // تهيئة مستمع المشتريات
      await _initializePurchaseListener();

      // استعادة المشتريات السابقة
      await _checkPastPurchases();

      print('✅ تم تهيئة نظام الدفع بنجاح - ${_products.length} منتج متاح');
      _errorMessage = null;

    } catch (e) {
      _errorMessage = 'فشل في تهيئة نظام الدفع: $e';
      print('❌ $_errorMessage');
    }

    notifyListeners();
  }

  // ✅ تهيئة Google Play Billing - الإصدار الحديث
  Future<void> _initializeGooglePlayBilling() async {
    try {
      // ✅ الطريقة الصحيحة لتهيئة Google Play Billing
      // في الإصدارات الحديثة، enablePendingPurchases يتم تلقائياً

      final billingStatus = await _inAppPurchase.isAvailable();
      if (!billingStatus) {
        throw Exception('Google Play Billing غير مدعوم');
      }

      print('✅ Google Play Billing جاهز للاستخدام');

    } catch (e) {
      throw Exception('فشل في تهيئة Google Play Billing: $e');
    }
  }

  // ✅ تحميل المنتجات من المتجر
  Future<void> _loadProducts() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      print('📦 جار تحميل تفاصيل المنتجات...');

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);

      // معالجة المنتجات غير الموجودة
      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ المنتجات غير موجودة: ${response.notFoundIDs}');
      }

      // معالجة الأخطاء
      if (response.error != null) {
        _errorMessage = 'خطأ في تحميل المنتجات: ${response.error}';
        print('❌ $_errorMessage');
      }

      _products = response.productDetails;

      // ✅ التحقق من الأسعار
      for (var product in _products) {
        print('💰 المنتج: ${product.id} - السعر: ${product.price} ${product.currencyCode}');
      }

      print('✅ تم تحميل ${_products.length} منتج بنجاح');
      _setLoading(false);

    } catch (e) {
      _errorMessage = 'فشل في تحميل المنتجات: $e';
      print('❌ $_errorMessage');
      _setLoading(false);
    }

    notifyListeners();
  }

  // ✅ تهيئة مستمع المشتريات
  Future<void> _initializePurchaseListener() async {
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        print('✅ تم إغلاق دفق المشتريات');
        _subscription.cancel();
      },
      onError: (error) {
        _errorMessage = 'خطأ في الاستماع للشراء: $error';
        print('❌ $_errorMessage');
        notifyListeners();
      },
    );

    print('✅ تم تهيئة مستمع المشتريات');
  }

  // ✅ معالجة تحديثات الشراء
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    print('🔄 معالجة ${purchaseDetailsList.length} تحديث شراء');

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  // ✅ معالجة عملية الشراء
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    final String productId = purchaseDetails.productID;
    print('🛒 حالة الشراء: ${purchaseDetails.status} للمنتج: $productId');

    try {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _setLoading(true);
          print('⏳ جاري معالجة الدفع للمنتج: $productId');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          print('✅ تم الشراء بنجاح: $productId');
          await _processSuccessfulPurchase(purchaseDetails);
          await _completePurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          _handlePurchaseError(purchaseDetails.error!);
          break;

        case PurchaseStatus.canceled:
          print('❌ تم إلغاء الشراء: $productId');
          _setLoading(false);
          break;
      }
    } catch (e) {
      _errorMessage = 'خطأ في معالجة الشراء: $e';
      print('❌ $_errorMessage');
      _setLoading(false);
    }

    notifyListeners();
  }

  // ✅ معالجة الشراء الناجح
  Future<void> _processSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    final String productId = purchaseDetails.productID;

    try {
      if (coinProducts.containsKey(productId)) {
        // ✅ شراء عملات
        final int coins = coinProducts[productId]!['coins'] as int;
        final double price = coinProducts[productId]!['price'] as double;

        await GameDataService.addCharacterCoins(coins);
        print('💰 تم شراء $coins عملة مقابل \$$price');

        // ✅ تحديث إحصائيات اللعبة
        await _updatePurchaseStatistics(productId, price);

      } else if (adsRemovalProducts.containsKey(productId)) {
        // ✅ شراء إزالة الإعلانات
        final String duration = adsRemovalProducts[productId]!['duration'] as String;
        final double price = adsRemovalProducts[productId]!['price'] as double;

        await _processAdsRemovalPurchase(duration);
        print('🚫 تم شراء إزالة الإعلانات لمدة: $duration مقابل \$$price');

        // ✅ تحديث إحصائيات اللعبة
        await _updatePurchaseStatistics(productId, price);
      }

      _setLoading(false);
      print('✅ تمت معالجة الشراء بنجاح للمنتج: $productId');

    } catch (e) {
      _errorMessage = 'خطأ في معالجة الشراء الناجح: $e';
      print('❌ $_errorMessage');
      _setLoading(false);
      throw e;
    }
  }

  // ✅ تحديث إحصائيات المشتريات
  Future<void> _updatePurchaseStatistics(String productId, double price) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // زيادة عدد المشتريات
      final totalPurchases = prefs.getInt('total_purchases') ?? 0;
      await prefs.setInt('total_purchases', totalPurchases + 1);

      // زيادة إجمالي المبيعات
      final totalRevenue = prefs.getDouble('total_revenue') ?? 0.0;
      await prefs.setDouble('total_revenue', totalRevenue + price);

      // تسجيل المنتج المباع
      final productSales = prefs.getInt('${productId}_sales') ?? 0;
      await prefs.setInt('${productId}_sales', productSales + 1);

      print('📊 تم تحديث الإحصائيات للمنتج: $productId');
    } catch (e) {
      print('⚠️ تحذير: فشل في تحديث الإحصائيات: $e');
    }
  }

  // ✅ معالجة شراء إزالة الإعلانات
  Future<void> _processAdsRemovalPurchase(String duration) async {
    final DateTime now = DateTime.now();
    DateTime? expiryDate;

    switch (duration) {
      case '1day':
        expiryDate = now.add(const Duration(days: 1));
        break;
      case '1week':
        expiryDate = now.add(const Duration(days: 7));
        break;
      case '1month':
        expiryDate = now.add(const Duration(days: 30));
        break;
      case '1year':
        expiryDate = now.add(const Duration(days: 365));
        break;
      case 'lifetime':
        expiryDate = null; // مدى الحياة
        break;
    }

    await AdsRemovalService().purchaseAdsRemoval(expiryDate);
    print('📅 تم تعيين إزالة الإعلانات حتى: $expiryDate');
  }

  // ✅ إكمال عملية الشراء
  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      await _inAppPurchase.completePurchase(purchaseDetails);
      print('✅ تم إكمال عملية الشراء بنجاح');
    } catch (e) {
      _errorMessage = 'خطأ في إكمال الشراء: $e';
      print('❌ $_errorMessage');
      throw e;
    }
  }

  // ✅ معالجة أخطاء الشراء
  void _handlePurchaseError(IAPError error) {
    _errorMessage = 'خطأ في الشراء: ${error.message} (${error.code})';
    print('❌ $_errorMessage');
    _setLoading(false);
  }

  // ✅ بدء عملية شراء منتج
  Future<void> purchaseProduct(String productId) async {
    try {
      // البحث عن المنتج
      final product = _products.firstWhere(
            (p) => p.id == productId,
        orElse: () => throw Exception('المنتج غير موجود: $productId'),
      );

      // إعداد معاملات الشراء
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );

      _setLoading(true);
      _errorMessage = null;

      print('🛒 بدء عملية شراء: $productId - ${product.price} ${product.currencyCode}');

      // ✅ تحديد نوع المنتج واستخدام دالة الشراء المناسبة
      if (coinProducts.containsKey(productId)) {
        // منتج مستهلك (عملات)
        print('--> شراء كمنتج مستهلك (Consumable)');
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } else {
        // منتج غير مستهلك (إزالة إعلانات)
        print('--> شراء كمنتج غير مستهلك (Non-Consumable)');
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

    } catch (e) {
      _errorMessage = 'خطأ في بدء عملية الشراء: $e';
      print('❌ $_errorMessage');
      _setLoading(false);
      notifyListeners();
    }
  }

  // ✅ استعادة المشتريات السابقة
  Future<void> _checkPastPurchases() async {
    try {
      print('🔍 جاري استعادة المشتريات السابقة...');

      // ✅ استخدام الطريقة الحديثة لاستعادة المشتريات
      await _inAppPurchase.restorePurchases();

      print('✅ تم إرسال طلب استعادة المشتريات');

    } catch (e) {
      _errorMessage = 'خطأ أثناء استعادة المشتريات السابقة: $e';
      print('❌ $_errorMessage');
    }
  }

  // ✅ الحصول على منتج بواسطة المعرف
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // ✅ الحصول على اسم المنتج مع السعر
  String getProductName(String productId, String languageCode) {
    final product = getProductById(productId);
    final price = product?.price ?? '\$0.00';

    if (coinProducts.containsKey(productId)) {
      final int coins = coinProducts[productId]!['coins'] as int;
      if (languageCode == 'ar') {
        return '$coins عملة - $price';
      } else {
        return '$coins Coins - $price';
      }
    } else if (adsRemovalProducts.containsKey(productId)) {
      final duration = adsRemovalProducts[productId]!['duration'] as String;
      final durationName = _getAdsRemovalDurationName(duration, languageCode);
      if (languageCode == 'ar') {
        return '$durationName - $price';
      } else {
        return '$durationName - $price';
      }
    }

    return productId;
  }

  // ✅ الحصول على وصف المنتج
  String getProductDescription(String productId, String languageCode) {
    if (coinProducts.containsKey(productId)) {
      final int coins = coinProducts[productId]!['coins'] as int;
      final double price = coinProducts[productId]!['price'] as double;

      if (languageCode == 'ar') {
        return 'احصل على $coins عملة مقابل \$$price - ${coinProducts[productId]!['description_ar']}';
      } else {
        return 'Get $coins coins for \$$price - ${coinProducts[productId]!['description_en']}';
      }
    } else if (adsRemovalProducts.containsKey(productId)) {
      final double price = adsRemovalProducts[productId]!['price'] as double;

      if (languageCode == 'ar') {
        return '${adsRemovalProducts[productId]!['description_ar']} مقابل \$$price';
      } else {
        return '${adsRemovalProducts[productId]!['description_en']} for \$$price';
      }
    }

    return '';
  }

  // ✅ الحصول على اسم مدة إزالة الإعلانات
  String _getAdsRemovalDurationName(String duration, String languageCode) {
    if (languageCode == 'ar') {
      switch (duration) {
        case '1day': return 'إزالة الإعلانات لمدة 24 ساعة';
        case '1week': return 'إزالة الإعلانات لمدة أسبوع';
        case '1month': return 'إزالة الإعلانات لمدة شهر';
        case '1year': return 'إزالة الإعلانات لمدة سنة';
        case 'lifetime': return 'إزالة الإعلانات مدى الحياة';
        default: return 'إزالة الإعلانات';
      }
    } else {
      switch (duration) {
        case '1day': return 'Remove Ads for 24 Hours';
        case '1week': return 'Remove Ads for 1 Week';
        case '1month': return 'Remove Ads for 1 Month';
        case '1year': return 'Remove Ads for 1 Year';
        case 'lifetime': return 'Remove Ads Lifetime';
        default: return 'Remove Ads';
      }
    }
  }

  // ✅ الحصول على معلومات المنتج الكاملة
  Map<String, dynamic>? getProductInfo(String productId) {
    if (coinProducts.containsKey(productId)) {
      return {
        'type': 'coins',
        ...coinProducts[productId]!,
      };
    } else if (adsRemovalProducts.containsKey(productId)) {
      return {
        'type': 'ads_removal',
        ...adsRemovalProducts[productId]!,
      };
    }
    return null;
  }

  // ✅ إعادة تحميل المنتجات
  Future<void> reloadProducts() async {
    await _loadProducts();
  }

  // ✅ التحقق من حالة التهيئة
  bool get isInitialized => _isAvailable && _products.isNotEmpty;

  // ✅ تعيين حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ✅ تنظيف الموارد
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}