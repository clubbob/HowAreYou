import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/inquiry_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

/// 1:1 문의 화면
class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key, this.userId});

  final String? userId;

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final InquiryService _inquiryService = InquiryService();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  Future<List<InquiryModel>>? _inquiriesFuture;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _inquiriesFuture = _inquiryService.getMyInquiries(widget.userId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userId == null && _inquiriesFuture == null) {
      final userId = context.read<AuthService>().user?.uid;
      if (userId != null) {
        _inquiriesFuture = _inquiryService.getMyInquiries(userId);
      }
    }
  }

  void _refreshInquiries() {
    final userId = widget.userId ?? context.read<AuthService>().user?.uid;
    if (userId != null) {
      setState(() {
        _inquiriesFuture = _inquiryService.getMyInquiries(userId);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createInquiry(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final userModel = authService.userModel;
    if (user == null) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의 내용을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final role = _roleToString(userModel?.role ?? UserRole.subject);
    final id = await _inquiryService.createInquiry(
      userId: user.uid,
      userPhone: user.phoneNumber ?? userModel?.phone ?? '',
      userDisplayName: userModel?.displayName,
      role: role,
      message: message,
    );
    setState(() => _isSubmitting = false);
    _messageController.clear();

    if (!context.mounted) return;
    if (id != null) {
      _refreshInquiries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의가 등록되었습니다. 답변 시 알려드리겠습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의 등록에 실패했습니다.'), backgroundColor: Colors.red),
      );
    }
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.guardian:
        return 'guardian';
      case UserRole.subject:
        return 'subject';
      case UserRole.both:
        return 'both';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = widget.userId ?? authService.user?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('1:1 문의'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: _inquiriesFuture == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(color: Colors.blue.shade600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '문의 목록 불러오는 중...',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<InquiryModel>>(
                      future: _inquiriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    '문의 목록을 불러오지 못했습니다.',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '아래에서 새 문의를 작성해 보세요.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.blue.shade600),
                                const SizedBox(height: 16),
                                Text(
                                  '문의 목록 불러오는 중...',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }
                        final list = snapshot.data ?? [];
                                if (list.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.contact_support_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    '등록된 문의가 없습니다.',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '아래에서 문의를 작성해 주세요.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                    final inquiry = list[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showInquiryDetail(context, inquiry),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      inquiry.message.length > 50
                                          ? '${inquiry.message.substring(0, 50)}...'
                                          : inquiry.message,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('yyyy.MM.dd HH:mm').format(inquiry.createdAt),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              if (inquiry.replies.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.reply, size: 14, color: Colors.green.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        '답변 ${inquiry.replies.length}건',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                          },
                        );
                      },
                    ),
            ),
          ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: '문의 내용을 입력하세요',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _createInquiry(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _createInquiry(context),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('등록'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _showInquiryDetail(BuildContext context, InquiryModel inquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(inquiry.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                inquiry.message,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              if (inquiry.replies.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  '답변 (${inquiry.replies.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...inquiry.replies.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.admin_panel_settings, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  '관리자',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('yyyy.MM.dd HH:mm').format(r.createdAt),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(r.message, style: const TextStyle(fontSize: 14, height: 1.5)),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
