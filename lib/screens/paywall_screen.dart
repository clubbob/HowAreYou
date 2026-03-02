import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/guardian_service.dart';
import '../services/purchase_service.dart';
import '../services/subscription_service.dart';

/// 프리미엄 구독 Paywall 화면
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final PurchaseService _purchaseService = PurchaseService.instance;
  final GuardianService _guardianService = GuardianService();

  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  SubscriptionState? _subscriptionState;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSubscriptionState();
    _purchaseService.addPurchaseListener(_onPurchaseUpdate);
  }

  @override
  void dispose() {
    _purchaseService.removePurchaseListener();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await _purchaseService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '상품 정보를 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSubscriptionState() async {
    final uid = Provider.of<AuthService>(context, listen: false).user?.uid;
    if (uid == null) return;
    final state = await _guardianService.getSubscriptionState(uid);
    if (mounted) {
      setState(() => _subscriptionState = state);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        setState(() => _isPurchasing = true);
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        setState(() {
          _isPurchasing = false;
          _errorMessage = purchase.error?.message ?? '구매에 실패했습니다.';
        });
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        setState(() => _isPurchasing = false);
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _deliverPurchase(purchase);
      }
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    final uid = Provider.of<AuthService>(context, listen: false).user?.uid;
    if (uid == null) {
      setState(() => _isPurchasing = false);
      return;
    }

    final productId = purchase.productID;
    final purchaseToken = purchase.verificationData.serverVerificationData;

    if (purchaseToken.isEmpty) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = '구매 정보를 확인할 수 없습니다.';
      });
      return;
    }

    final success = await _purchaseService.verifyAndActivate(
      productId: productId,
      purchaseToken: purchaseToken,
      uid: uid,
    );

    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        await _loadSubscriptionState();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프리미엄이 활성화되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _errorMessage = '서버 검증에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      }
    }
  }

  Future<void> _purchase(String productId) async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });
    final started = await _purchaseService.buy(productId);
    if (!started && mounted) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = '구매를 시작할 수 없습니다.';
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });
    await _purchaseService.restorePurchases();
    if (mounted) {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 복원을 요청했습니다. 완료되면 알림이 표시됩니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _subscriptionState?.isRestricted == false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPremium) ...[
              Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
              const SizedBox(height: 16),
              Text(
                '프리미엄 활성화됨',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _subscriptionState?.message ?? '프리미엄 이용 중',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeatureList(),
            ] else ...[
              Icon(Icons.workspace_premium, size: 64, color: Colors.amber[700]),
              const SizedBox(height: 16),
              Text(
                '프리미엄으로 더 많은 보호',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '보호대상자 무제한 등록 · 6/9/12시간 무이동 알림',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildFeatureList(),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ..._products.map((p) => _buildProductCard(p)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isPurchasing ? null : _restore,
                child: const Text('구매 복원'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureRow(Icons.people_outline, '보호대상자 무제한 등록'),
            const Divider(height: 24),
            _buildFeatureRow(Icons.notifications_active, '6/9/12시간 무이동 알림'),
            const Divider(height: 24),
            _buildFeatureRow(Icons.shield_outlined, '안전 확인 알림'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  Widget _buildProductCard(ProductDetails product) {
    final id = product.id;
    final title = id == 'premium_monthly' ? '월간 구독' : '연간 구독';
    final priceString = product.price;
    final isYearly = id == 'premium_yearly';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: isYearly ? const Text('1년 구독 (월 평균 저렴)') : null,
          trailing: SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: _isPurchasing
                  ? null
                  : () => _purchase(id),
              child: Text(priceString),
            ),
          ),
        ),
      ),
    );
  }
}
