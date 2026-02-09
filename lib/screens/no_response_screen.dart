import 'package:flutter/material.dart';
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
