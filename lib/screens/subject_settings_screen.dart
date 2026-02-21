import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../utils/constants.dart';
import '../utils/legal_dialog.dart';
import 'auth_screen.dart';
import 'inquiry_screen.dart';

/// 보호대상자 설정 화면 (알림 소리, 회원 탈퇴 등)
class SubjectSettingsScreen extends StatefulWidget {
  const SubjectSettingsScreen({super.key});

  @override
  State<SubjectSettingsScreen> createState() => _SubjectSettingsScreenState();
}

class _SubjectSettingsScreenState extends State<SubjectSettingsScreen> {
  bool _notificationSoundEnabled = true;
  bool _isLoading = true;
  String _appVersion = '-';
  ({String phone, DateTime? createdAt, String subscriptionStatus, DateTime? subscriptionExpiry})? _accountInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final enabled = await FCMService.instance.getNotificationSoundEnabled();
    final accountInfo = await authService.getAccountInfo();
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _notificationSoundEnabled = enabled;
        _accountInfo = accountInfo;
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotificationSound(bool value) async {
    setState(() {
      _notificationSoundEnabled = value;
    });
    await FCMService.instance.setNotificationSoundEnabled(value);
  }

  Widget _buildAccountInfoCard() {
    final info = _accountInfo;
    if (info == null) return const Card(child: ListTile(title: Text('계정 정보를 불러오는 중...')));
    final dateFormat = DateFormat('yyyy.MM.dd');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountInfoRow(Icons.phone_outlined, '휴대폰 번호', AuthService.formatPhoneForDisplay(info.phone)),
            const Divider(height: 24),
            _buildAccountInfoRow(
              Icons.calendar_today_outlined,
              '가입일',
              info.createdAt != null ? dateFormat.format(info.createdAt!) : '-',
            ),
            const Divider(height: 24),
            _buildAccountInfoRow(Icons.credit_card_outlined, '결제 상태', '무료'),
            const Divider(height: 24),
            _buildAccountInfoRow(Icons.event_outlined, '다음 결제일', '해당 없음'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  Future<void> _openSubscriptionManagement() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '구독 관리로 이동',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.apple),
                title: const Text('App Store'),
                subtitle: const Text('iOS 구독 관리'),
                onTap: () => Navigator.of(ctx).pop('apple'),
              ),
              ListTile(
                leading: const Icon(Icons.android),
                title: const Text('Google Play'),
                subtitle: const Text('Android 구독 관리'),
                onTap: () => Navigator.of(ctx).pop('play'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final url = choice == 'apple'
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    await _launchUrl(url);
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    // 1단계: 탈퇴 안내
    final firstChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '탈퇴하면 데이터는 삭제됩니다.\n\n'
              '• 사용자 정보 삭제\n'
              '• 보호대상자/보호자 연결 해제\n'
              '• 기록 데이터 삭제\n\n'
              '연 결제(12,000원)는 스토어에서 자동 갱신됩니다. '
              '탈퇴만 하면 결제는 멈추지 않습니다. 과금 멈추려면 스토어에서 직접 취소하세요.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop('store'),
                    child: const Text('과금 멈추기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop('continue'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('탈퇴'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
    if (firstChoice == null || firstChoice == 'cancel' || !context.mounted) return;

    if (firstChoice == 'store') {
      await _openSubscriptionManagement();
      return;
    }

    // 2단계: 유료 결제 중이면 한 번 더 확인
    final authService = Provider.of<AuthService>(context, listen: false);
    final accountInfo = await authService.getAccountInfo();
    final isSubscriptionActive = accountInfo.subscriptionStatus == '활성' ||
        accountInfo.subscriptionStatus == '만료 예정';

    if (isSubscriptionActive && context.mounted) {
      final secondChoice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('연 결제가 진행 중입니다'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('탈퇴해도 결제는 멈추지 않습니다. 계속하시겠습니까?'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop('store'),
                      child: const Text('과금 멈추기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop('delete'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('탈퇴'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade700)),
            ),
          ],
        ),
      );
      if (secondChoice == null || secondChoice == 'cancel' || !context.mounted) return;
      if (secondChoice == 'store') {
        await _openSubscriptionManagement();
        return;
      }
    }

    if (!context.mounted) return;

    // 최종 확인: 정말 탈퇴하시겠습니까?
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('최종 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '정말 탈퇴하시겠습니까?\n계정과 데이터가 영구적으로 삭제되며 되돌릴 수 없습니다.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('탈퇴'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmDelete != true || !context.mounted) return;

    var error = await authService.deleteAccount();
    if (!context.mounted) return;

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    if (error == 'REQUIRES_REAUTH') {
      // 본인 인증 필요: OTP 전송 후 입력받기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호를 전송 중입니다...')),
      );
      final verificationId = await authService.sendReauthOTP();
      if (!context.mounted) return;
      if (verificationId == null || verificationId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호 전송에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호를 전송했습니다. 6자리를 입력해 주세요.')),
      );

      final smsCode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('본인 인증'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '인증번호 6자리',
                counterText: '',
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      if (smsCode == null || smsCode.length != 6 || !context.mounted) return;

      error = await authService.reauthenticateAndDeleteAccount(verificationId, smsCode);
      if (!context.mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, size: 18),
                SizedBox(width: 4),
                Text('뒤로', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // [ 계정 정보 ] (보호대상자는 무료)
                _buildSectionHeader('계정 정보'),
                _buildAccountInfoCard(),
                const SizedBox(height: 24),
                // [ 알림 설정 ]
                _buildSectionHeader('알림 설정'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: const Text('알림 소리'),
                    subtitle: const Text('안부 전달 알림 소리 재생'),
                    trailing: Switch(
                      value: _notificationSoundEnabled,
                      onChanged: _toggleNotificationSound,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // [ 고객지원 ]
                _buildSectionHeader('고객지원'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.contact_support_outlined),
                        title: const Text('1:1 문의'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final uid = Provider.of<AuthService>(context, listen: false).user?.uid;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InquiryScreen(userId: uid),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('이용약관'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => LegalDialog.showTerms(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('개인정보처리방침'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => LegalDialog.showPrivacy(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code_outlined),
                        title: const Text('오픈소스 라이선스'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: '지금 어때',
                          applicationVersion: _appVersion,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('버전 정보'),
                        trailing: Text(_appVersion, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // [ 계정 관리 ]
                _buildSectionHeader('계정 관리'),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                    title: Text(
                      '회원 탈퇴',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('계정과 데이터가 영구적으로 삭제됩니다.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ),
              ],
            ),
    );
  }
}
