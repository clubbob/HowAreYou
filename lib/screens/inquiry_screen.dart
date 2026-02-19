import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/inquiry_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// 1:1 문의 화면 (웹과 동일 기능: 문의 하기 / 문의 확인)
class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key, this.userId});

  final String? userId;

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> with SingleTickerProviderStateMixin {
  final InquiryService _inquiryService = InquiryService();
  late TabController _tabController;

  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  bool _submitSuccess = false;
  String? _errorMsg;
  Future<List<InquiryModel>>? _inquiriesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInquiries();
  }

  void _loadInquiries() {
    final userId = widget.userId ?? context.read<AuthService>().user?.uid;
    if (userId != null) {
      _inquiriesFuture = _inquiryService.getMyInquiries(userId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inquiriesFuture == null) {
      final userId = widget.userId ?? context.read<AuthService>().user?.uid;
      if (userId != null) {
        _inquiriesFuture = _inquiryService.getMyInquiries(userId);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      setState(() {
        _errorMsg = '문의 내용을 입력해 주세요.';
      });
      return;
    }
    if (message.length > 2000) {
      setState(() {
        _errorMsg = '문의 내용은 2000자 이내로 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    final role = _roleToString(userModel?.role ?? UserRole.subject);
    final userPhone = user.phoneNumber ?? userModel?.phone ?? '';
    final id = await _inquiryService.createInquiry(
      userId: user.uid,
      userPhone: userPhone,
      userDisplayName: userModel?.displayName,
      email: null,
      role: role,
      message: message,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (id != null) {
      _messageController.clear();
      _loadInquiries();
      setState(() {
        _submitSuccess = true;
      });
      if (mounted) {
        _tabController.animateTo(1);
      }
    } else {
      setState(() {
        _errorMsg = '문의 등록에 실패했습니다.';
      });
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          tabs: const [
            Tab(text: '문의 하기'),
            Tab(text: '문의 확인'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInquiryFormTab(context),
          _buildInquiryListTab(context),
        ],
      ),
    );
  }

  Widget _buildInquiryFormTab(BuildContext context) {
    if (_submitSuccess) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green.shade700),
                  const SizedBox(height: 16),
                  Text(
                    '문의가 접수되었습니다.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '빠른 시일 내에 답변 드리겠습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '문의 확인 탭에서 답변을 확인할 수 있습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _submitSuccess = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('다른 문의하기'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '서비스 이용 중 궁금한 점이 있으시면 문의해 주세요. 영업일 기준 1~2일 내 답변 드립니다.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500)),
            ),
          ],
          Text(
            '로그인된 계정정보는 관리자에게 전달됩니다.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: '문의 내용 *',
              hintText: '문의 내용을 입력해 주세요.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _createInquiry(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('문의 등록'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '급한 문의는 clubbob@naver.com · 010-6391-4520으로 연락해 주세요.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryListTab(BuildContext context) {
    if (_inquiriesFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade600),
            const SizedBox(height: 16),
            Text('문의 목록 불러오는 중...', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      );
    }

    return FutureBuilder<List<InquiryModel>>(
      future: _inquiriesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    '문의 목록을 불러오지 못했습니다.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
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
              children: [
                CircularProgressIndicator(color: Colors.blue.shade600),
                const SizedBox(height: 16),
                Text('문의 목록 불러오는 중...', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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
                    '문의 하기 탭에서 문의를 작성해 주세요.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _inquiriesFuture = null);
            _loadInquiries();
          },
          child: ListView.builder(
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
                        Text(
                          inquiry.message.length > 50
                              ? '${inquiry.message.substring(0, 50)}...'
                              : inquiry.message,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
          ),
        );
      },
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
                  '관리자 답변 (${inquiry.replies.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  '답변 대기 중입니다.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
