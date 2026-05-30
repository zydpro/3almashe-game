// services/payment_service.dart
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_data_service.dart';
import 'ads_removal_service.dart';

class PaymentService with ChangeNotifier {
  static PaymentService? _instance;
  static PaymentService get instance {
    _instance ??= PaymentService._internal();
    return _instance!;
  }
  factory PaymentService() => instance;
  PaymentService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  Set<String> _productIds = {};
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ✅ الخصائص العامة
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _products.isNotEmpty;

  // ✅ تهيئة نظام الدفع
  Future<void> initialize() async {
    try {
      print('🔄 Starting payment system initialization...');
      _setLoading(true);
      _errorMessage = null;

      // ✅ التحقق من توفر نظام الدفع
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        print('⚠️ Payment system not available on this device');
        _errorMessage = 'Payment system not available';
        _setLoading(false);
        return;
      }

      // ✅ تحميل المنتجات
      _productIds = {...coinProducts.keys, ...adsRemovalProducts.keys};
      print('🛒 Product IDs: $_productIds');

      // ✅ عرض معلومات التصحيح
      debugProducts();

      await _loadProducts();

      // ✅ تهيئة مستمع المشتريات
      await _initializePurchaseListener();

      print('✅ Payment system initialized - ${_products.length} products');
      _errorMessage = null;

    } catch (e) {
      _errorMessage = 'Failed to initialize payment system: $e';
      print('❌ $_errorMessage');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ✅ تحميل المنتجات من المتجر
  Future<void> _loadProducts() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      print('📦 Loading product details...');

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        _errorMessage = 'Error loading products: ${response.error}';
        print('❌ $_errorMessage');
      }

      _products = response.productDetails;

      for (var product in _products) {
        print('💰 Product: ${product.id} - Price: ${product.price} ${product.currencyCode}');
      }

      print('✅ Loaded ${_products.length} products successfully');
      _setLoading(false);

    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      print('❌ $_errorMessage');
      _setLoading(false);
    }
    notifyListeners();
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
    return product?.title ?? productId;
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
    return getProductById(productId)?.description ?? '';
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

  // ✅ بدء عملية شراء منتج
  Future<void> purchaseProduct(String productId) async {
    try {
      final product = _products.firstWhere(
            (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );

      _setLoading(true);
      _errorMessage = null;

      print('🛒 Starting purchase: $productId');

      if (coinProducts.containsKey(productId)) {
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

    } catch (e) {
      _errorMessage = 'Error starting purchase: $e';
      print('❌ $_errorMessage');
      _setLoading(false);
      notifyListeners();
    }
  }

  // ✅ إعادة تحميل المنتجات
  Future<void> reloadProducts() async {
    await _loadProducts();
  }

  // ✅ تعيين حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ✅ تنظيف الموارد
  @override
  void dispose() {
    // لا تفعل شيئاً - دع Singleton يبقى نشطاً
    print('ℹ️ PaymentService dispose ignored - Singleton must remain active');
  }

  // ✅ تعريفات المنتجات
  static const Map<String, Map<String, dynamic>> coinProducts = {
    'com.almashe.game.run.almashe_run.coins_100': {
      'price': 0.99,
      'coins': 100,
      'description_ar': '100 عملة لشراء الشخصيات والتحسينات',
      'description_en': '100 coins for characters and upgrades',
    },
    'com.almashe.game.run.almashe_run.coins_500': {
      'price': 3.99,
      'coins': 500,
      'description_ar': '500 عملة لحزمة كبيرة من المحتويات',
      'description_en': '500 coins for a large content pack',
    },
    'com.almashe.game.run.almashe_run.coins_1000': {
      'price': 6.99,
      'coins': 1000,
      'description_ar': '1000 عملة لباقة مميزة من المزايا',
      'description_en': '1000 coins for premium features',
    },
    'com.almashe.game.run.almashe_run.coins_5000': {
      'price': 19.99,
      'coins': 5000,
      'description_ar': '5000 عملة للحزمة المثالية للمحترفين',
      'description_en': '5000 coins for the ultimate pro pack',
    },
  };

// ✅ تحديث معرفات منتجات إزالة الإعلانات - استخدام المعرفات الكاملة
  static const Map<String, Map<String, dynamic>> adsRemovalProducts = {
    'com.almashe.game.run.almashe_run.remove_ads_1day': {
      'price': 0.49,
      'duration': '1day',
      'description_ar': 'إزالة الإعلانات لمدة 24 ساعة',
      'description_en': 'Remove ads for 24 hours',
    },
    'com.almashe.game.run.almashe_run.remove_ads_1week': {
      'price': 2.99,
      'duration': '1week',
      'description_ar': 'إزالة الإعلانات لمدة أسبوع',
      'description_en': 'Remove ads for 1 week',
    },
    'com.almashe.game.run.almashe_run.remove_ads_1month': {
      'price': 4.99,
      'duration': '1month',
      'description_ar': 'إزالة الإعلانات لمدة شهر',
      'description_en': 'Remove ads for 1 month',
    },
    'com.almashe.game.run.almashe_run.remove_ads_1year': {
      'price': 9.99,
      'duration': '1year',
      'description_ar': 'إزالة الإعلانات لمدة سنة',
      'description_en': 'Remove ads for 1 year',
    },
    'com.almashe.game.run.almashe_run.remove_ads_lifetime': {
      'price': 14.99,
      'duration': 'lifetime',
      'description_ar': 'إزالة الإعلانات مدى الحياة',
      'description_en': 'Remove ads for lifetime',
    },
  };

  // ✅ تهيئة مستمع المشتريات
  Future<void> _initializePurchaseListener() async {
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        print('✅ Purchase stream closed');
        _subscription.cancel();
      },
      onError: (error) {
        _errorMessage = 'Error listening to purchases: $error';
        print('❌ $_errorMessage');
        notifyListeners();
      },
    );
    print('✅ Purchase listener initialized');
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    print('🔄 Processing ${purchaseDetailsList.length} purchase updates');

    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      try {
        if (purchaseDetails.status == PurchaseStatus.purchased) {
          print('✅ Purchase successful: ${purchaseDetails.productID}');

          // ✅ معالجة شراء العملات
          if (coinProducts.containsKey(purchaseDetails.productID)) {
            final int coins = coinProducts[purchaseDetails.productID]!['coins'] as int;
            await GameDataService.addCharacterCoins(coins);
            print('💰 Added $coins coins to user');
          }

          // ✅ معالجة إزالة الإعلانات
          else if (adsRemovalProducts.containsKey(purchaseDetails.productID)) {
            final String duration = adsRemovalProducts[purchaseDetails.productID]!['duration'] as String;
            DateTime? expiryDate;

            switch (duration) {
              case '1day': expiryDate = DateTime.now().add(Duration(days: 1)); break;
              case '1week': expiryDate = DateTime.now().add(Duration(days: 7)); break;
              case '1month': expiryDate = DateTime.now().add(Duration(days: 30)); break;
              case '1year': expiryDate = DateTime.now().add(Duration(days: 365)); break;
              case 'lifetime': expiryDate = null; break;
            }

            await AdsRemovalService().purchaseAdsRemoval(expiryDate);
            print('🚫 Ads removed for: $duration');
          }

          // ✅ تأكيد الشراء للمتجر
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
        else if (purchaseDetails.status == PurchaseStatus.error) {
          print('❌ Purchase failed: ${purchaseDetails.error}');
        }

      } catch (e) {
        print('❌ Error processing purchase: $e');
      }
    }

    notifyListeners();
  }

  // ✅ دالة للتحقق من تطابق المنتجات
  void debugProducts() {
    print('=== 🔍 PRODUCTS DEBUG ===');
    print('📦 Available products in code:');

    print('🪙 Coin Products:');
    coinProducts.forEach((id, details) {
      print('   - $id: ${details['coins']} coins - \$${details['price']}');
    });

    print('🚫 Ads Removal Products:');
    adsRemovalProducts.forEach((id, details) {
      print('   - $id: ${details['duration']} - \$${details['price']}');
    });

    print('🔄 Loaded from store: ${_products.length} products');
    _products.forEach((product) {
      print('   - ${product.id}: ${product.title} - ${product.price}');
    });

    print('========================');
  }

}