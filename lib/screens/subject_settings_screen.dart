import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await FCMService.instance.getNotificationSoundEnabled();
    if (mounted) {
      setState(() {
        _notificationSoundEnabled = enabled;
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '계정과 모든 데이터가 영구적으로 삭제됩니다.\n\n'
          '• 사용자 정보 삭제\n'
          '• 보호대상자/보호자 연결 해제\n'
          '• 기록 데이터 삭제\n\n'
          '이 작업은 취소할 수 없습니다. 계속하시겠습니까?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade800,
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 8),
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
    );
    if (confirmed != true || !context.mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
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
                    subtitle: const Text('계정 및 모든 데이터가 영구적으로 삭제됩니다'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ),
              ],
            ),
    );
  }
}
