// services/Payment_UI_Service.dart
import 'package:flutter/material.dart';
import 'payment_service.dart';
import '../Languages/localization.dart';

class PaymentUIService {
  static PaymentUIService? _instance;
  static PaymentUIService get instance {
    _instance ??= PaymentUIService._internal();
    return _instance!;
  }
  factory PaymentUIService() => instance;
  PaymentUIService._internal();

  final PaymentService _paymentService = PaymentService();

  // ✅ نصوص متعددة اللغات
  Map<String, Map<String, String>> _localizedTexts = {
    'ar': {
      'loading_products': 'جاري تحميل المنتجات...',
      'no_products_available': 'لا توجد منتجات متاحة',
      'initializing_payment': 'جاري تهيئة نظام الدفع...',
      'products_count': 'منتج متاح',
      'product_not_available': 'غير متوفر',
      'loading': 'جاري التحميل...',
      'retry': 'إعادة المحاولة',
    },
    'en': {
      'loading_products': 'Loading products...',
      'no_products_available': 'No products available',
      'initializing_payment': 'Initializing payment system...',
      'products_count': 'products available',
      'product_not_available': 'Not available',
      'loading': 'Loading...',
      'retry': 'Retry',
    },
  };

  String _getText(String key, String languageCode) {
    return _localizedTexts[languageCode]?[key] ?? key;
  }

  // ✅ حالة نظام الدفع مع دعم اللغات
  Widget buildPaymentStatus(AppLocalizations l10n, {VoidCallback? onRetry}) {
    final String languageCode = l10n.locale.languageCode;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_paymentService.isLoading) {
      statusText = _getText('loading_products', languageCode);
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_bottom;
    } else if (_paymentService.errorMessage != null) {
      statusText = _paymentService.errorMessage!;
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (!_paymentService.isAvailable && !_paymentService.isInitialized) {
      statusText = l10n.paymentNotAvailable;
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (!_paymentService.isInitialized) {
      statusText = _getText('initializing_payment', languageCode);
      statusColor = Colors.orange;
      statusIcon = Icons.settings;
    } else if (_paymentService.products.isEmpty) {
      statusText = _getText('no_products_available', languageCode);
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusText = '${l10n.paymentReady} - ${_paymentService.products.length} ${_getText('products_count', languageCode)}';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (_paymentService.errorMessage != null || _paymentService.products.isEmpty)
            IconButton(
              icon: Icon(Icons.refresh, size: 18),
              color: statusColor,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }

  // ✅ بناء خيار شراء العملات مع دعم اللغات
  Widget buildCoinsPurchaseOption(String productId, AppLocalizations l10n, VoidCallback onPurchase) {
    final String languageCode = l10n.locale.languageCode;

    if (!_paymentService.isInitialized) {
      return _buildLoadingProduct(l10n, languageCode);
    }

    final product = _paymentService.getProductById(productId);
    if (product == null) {
      return _buildProductNotAvailable(productId, l10n, languageCode);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPurchase,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentService.getProductName(productId, languageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _paymentService.getProductDescription(productId, languageCode),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.price,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ بناء خيار إزالة الإعلانات مع دعم اللغات
  Widget buildAdsRemovalOption(String productId, AppLocalizations l10n, VoidCallback onPurchase) {
    final String languageCode = l10n.locale.languageCode;

    if (!_paymentService.isInitialized) {
      return _buildLoadingProduct(l10n, languageCode);
    }

    final product = _paymentService.getProductById(productId);
    if (product == null) {
      return _buildProductNotAvailable(productId, l10n, languageCode);
    }

    Color color;
    switch (productId) {
      case 'remove_ads_1day': color = Colors.blue;
      case 'remove_ads_1week': color = Colors.green;
      case 'remove_ads_1month': color = Colors.orange;
      case 'remove_ads_1year': color = Colors.red;
      case 'remove_ads_lifetime': color = Colors.purple;
      default: color = Colors.grey;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPurchase,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.block,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentService.getProductName(productId, languageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _paymentService.getProductDescription(productId, languageCode),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.price,
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ منتج قيد التحميل
  Widget _buildLoadingProduct(AppLocalizations l10n, String languageCode) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              color: Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getText('loading', languageCode),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ منتج غير متوفر
  Widget _buildProductNotAvailable(String productId, AppLocalizations l10n, String languageCode) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_getText('product_not_available', languageCode)}: $productId',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ الحصول على جميع منتجات العملات
  List<Widget> buildAllCoinsOptions(AppLocalizations l10n, Function(String) onPurchase) {
    return [
      buildCoinsPurchaseOption('com.almashe.game.run.almashe_run.coins_100', l10n, () => onPurchase('com.almashe.game.run.almashe_run.coins_100')),
      const SizedBox(height: 8),
      buildCoinsPurchaseOption('com.almashe.game.run.almashe_run.coins_500', l10n, () => onPurchase('com.almashe.game.run.almashe_run.coins_500')),
      const SizedBox(height: 8),
      buildCoinsPurchaseOption('com.almashe.game.run.almashe_run.coins_1000', l10n, () => onPurchase('com.almashe.game.run.almashe_run.coins_1000')),
      const SizedBox(height: 8),
      buildCoinsPurchaseOption('com.almashe.game.run.almashe_run.coins_5000', l10n, () => onPurchase('com.almashe.game.run.almashe_run.coins_5000')),
    ];
  }

// ✅ تحديث دوال بناء خيارات إزالة الإعلانات
  List<Widget> buildAllAdsRemovalOptions(AppLocalizations l10n, Function(String) onPurchase) {
    return [
      buildAdsRemovalOption('com.almashe.game.run.almashe_run.remove_ads_1day', l10n, () => onPurchase('com.almashe.game.run.almashe_run.remove_ads_1day')),
      const SizedBox(height: 8),
      buildAdsRemovalOption('com.almashe.game.run.almashe_run.remove_ads_1week', l10n, () => onPurchase('com.almashe.game.run.almashe_run.remove_ads_1week')),
      const SizedBox(height: 8),
      buildAdsRemovalOption('com.almashe.game.run.almashe_run.remove_ads_1month', l10n, () => onPurchase('com.almashe.game.run.almashe_run.remove_ads_1month')),
      const SizedBox(height: 8),
      buildAdsRemovalOption('com.almashe.game.run.almashe_run.remove_ads_1year', l10n, () => onPurchase('com.almashe.game.run.almashe_run.remove_ads_1year')),
      const SizedBox(height: 8),
      buildAdsRemovalOption('com.almashe.game.run.almashe_run.remove_ads_lifetime', l10n, () => onPurchase('com.almashe.game.run.almashe_run.remove_ads_lifetime')),
    ];
  }
  // ✅ إعادة تحميل المنتجات
  Future<void> reloadProducts() async {
    await _paymentService.reloadProducts();
  }

  // ✅ الحصول على حالة النظام
  bool get isPaymentInitialized => _paymentService.isInitialized;
  bool get isPaymentLoading => _paymentService.isLoading;
  String? get paymentError => _paymentService.errorMessage;
}