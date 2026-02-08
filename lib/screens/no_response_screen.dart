import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/mood_response_model.dart';

/// 회신이 없을 때 보호자가 보는 화면
class NoResponseScreen extends StatelessWidget {
  final String subjectName;
  final String subjectId;
  final TimeSlot slot;

  const NoResponseScreen({
    super.key,
    required this.subjectName,
    required this.subjectId,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회신 없음'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 18),
                const SizedBox(width: 4),
                const Text('뒤로', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.schedule_outlined,
                size: 64,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 24),
              Text(
                '$subjectName님과 연락이 닿지 않고 있어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${slot.label} 회신이 없습니다. 연락해 보시거나, 나중에 다시 확인해 보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () => _sendReminder(context),
                icon: const Icon(Icons.notifications_outlined, size: 22),
                label: const Text('알림 보내기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showCallHint(context),
                icon: const Icon(Icons.phone_outlined, size: 22),
                label: const Text('전화하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReminder(BuildContext context) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendReminderToSubject');
      final result = await callable.call<Map<String, dynamic>>({'subjectId': subjectId});
      final data = result.data;
      final success = data['success'] == true;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '알림을 보냈습니다.'
                : '알림을 보내지 못했습니다. 대상자 기기에 앱이 설치되어 있는지 확인해 주세요.',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      String msg = '알림 전송에 실패했습니다.';
      switch (e.code) {
        case 'unauthenticated':
          msg = '로그인이 필요합니다.';
          break;
        case 'permission-denied':
          msg = '해당 대상자의 보호자가 아닙니다.';
          break;
        case 'not-found':
          msg = '대상자를 찾을 수 없습니다.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 전송에 실패했습니다. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  void _showCallHint(BuildContext context) {
    // 전화는 앱에서 직접 걸지 않고, 보호자 관리에 등록된 번호가 있으면 url_launcher로 tel: 링크 안내 가능
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$subjectName님에게 전화해 보세요. (전화번호는 보호자 관리에서 확인)',
        ),
      ),
    );
  }
}
