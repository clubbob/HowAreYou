import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play 구독 상품 ID (Play Console에 등록된 값과 일치)
const String productIdMonthly = 'premium_monthly';
const String productIdYearly = 'premium_yearly';

/// 앱 패키지명 (Play Console 등록과 일치)
const String packageName = 'com.andy.howareyou';

/// 구독 결제 서비스 — in_app_purchase + 서버 검증
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  static PurchaseService get instance => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> isAvailable() => _iap.isAvailable();

  /// 구독 상품 ID 목록
  static const Set<String> _productIds = {productIdMonthly, productIdYearly};

  /// 상품 정보 조회 (가격 등)
  Future<List<ProductDetails>> getProducts() async {
    if (!Platform.isAndroid) return [];
    final available = await _iap.isAvailable();
    if (!available) return [];
    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[Purchase] 상품 없음: ${response.notFoundIDs}');
      }
      return response.productDetails;
    } catch (e) {
      debugPrint('[Purchase] 상품 조회 오류: $e');
      return [];
    }
  }

  /// 구매 업데이트 리스너 등록 (성공/실패/취소/대기)
  void addPurchaseListener(void Function(List<PurchaseDetails>) listener) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(listener);
  }

  void removePurchaseListener() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// 구매 시작
  Future<bool> buy(String productId) async {
    if (!Platform.isAndroid) return false;
    final products = await getProducts();
    final product = products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      debugPrint('[Purchase] 상품 없음: $productId');
      return false;
    }
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// 구매 복원 (재설치 후)
  Future<void> restorePurchases() async {
    if (!Platform.isAndroid) return;
    await _iap.restorePurchases();
  }

  /// 서버에 구매 토큰 전송 → Firestore 갱신 (uid는 서버에서 context.auth로 확인)
  /// 성공 시 true, 실패 시 false
  Future<bool> verifyAndActivate({
    required String productId,
    required String purchaseToken,
    required String uid,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyPlaySubscription');
      final result = await callable.call<Map<String, dynamic>>({
        'productId': productId,
        'purchaseToken': purchaseToken,
        'packageName': packageName,
      });
      final data = result.data;
      return data['success'] == true;
    } catch (e) {
      debugPrint('[Purchase] 서버 검증 오류: $e');
      return false;
    }
  }

  /// 미완료 구매 처리 (앱 재시작 시)
  Future<List<PurchaseDetails>> getPendingPurchases() async {
    if (!Platform.isAndroid) return [];
    try {
      await _iap.restorePurchases();
      return [];
    } catch (_) {}
    return [];
  }
}
