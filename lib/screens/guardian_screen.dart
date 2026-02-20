import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/guardian_service.dart';
import '../utils/constants.dart';
import '../utils/button_styles.dart';
import '../utils/invite_link_helper.dart';
import 'subject_settings_screen.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GuardianService _guardianService = GuardianService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasScrolledAfterAdd = false;

  static const double _inputRadius = 12;
  static const double _inputMinHeight = 56;
  static const EdgeInsets _inputPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showInviteBottomSheet(BuildContext context, String userId) {
    final inviteUrl = InviteLinkHelper.buildGuardianInviteUrl(userId);
    final screenHeight = MediaQuery.of(context).size.height;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: screenHeight * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '보호자 초대 링크',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 내용
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 공유 예시 문구 카드
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '공유 예시 문구',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  final fullMessage = InviteLinkHelper.getFullGuardianInviteMessage(userId);
                                  Clipboard.setData(
                                    ClipboardData(text: fullMessage),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('문구가 복사되었습니다'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                tooltip: '복사',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            InviteLinkHelper.getFullGuardianInviteMessage(userId),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 공유 버튼
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await InviteLinkHelper.shareGuardianInvite(userId);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.share, size: 22),
                        label: const Text('공유하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 목록 표시용: E.164(82...) 등을 010XXXXXXXX 형태로
  /// 821063914520 → 0 + 1063914520 = 01063914520 (82 다음이 10이면 0 하나만 붙임)
  String _formatPhoneDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 11 && digits.startsWith('82')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length >= 10 && digits.startsWith('010')) {
      return digits;
    }
    return phone;
  }

  /// 기존 보호자 정보 수정 (이름/별칭만 변경, 보호자 화면과 동일 UI)
  Future<void> _showSetNameDialog(
    BuildContext context,
    String userId,
    String guardianUid,
    Map<String, dynamic> guardianInfos,
  ) async {
    final info = guardianInfos[guardianUid];
    final infoMap = info is Map
        ? Map<String, dynamic>.from(info as Map)
        : <String, dynamic>{};
    final initialName = infoMap['displayName'] is String
        ? (infoMap['displayName'] as String).trim()
        : '';
    final existingPhone = infoMap['phone'] is String
        ? (infoMap['phone'] as String)
        : '';
    
    final nameController = TextEditingController(text: initialName);
    
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름(별칭) 수정'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '예: 엄마, 아빠',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? null : v.trim()),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
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
                  onPressed: () {
                    final n = nameController.text.trim();
                    Navigator.pop(ctx, n.isEmpty ? null : n);
                  },
                  style: AppButtonStyles.primaryElevated,
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    
    // 다이얼로그가 완전히 닫힌 후 controller dispose (애니메이션 완료 대기)
    Future.delayed(const Duration(milliseconds: 400), () {
      nameController.dispose();
    });
    
    if (result == null) return;
    
    try {
      // 보호자 추가와 동일하게 guardianInfos 전체를 읽어 수정 후 통째로 저장
      final docRef = _firestore.collection(AppConstants.subjectsCollection).doc(userId);
      final docSnap = await docRef.get();
      final existingData = docSnap.data() as Map<String, dynamic>?;
      final existingInfosRaw = existingData?['guardianInfos'];
      final existingInfos = existingInfosRaw is Map
          ? Map<String, dynamic>.from(
              (existingInfosRaw as Map).map((k, v) => MapEntry(
                    k.toString(),
                    v is Map ? Map<String, dynamic>.from(v) : v,
                  )))
          : <String, dynamic>{};
      
      // 이름만 변경, 전화번호는 기존 값 유지
      final currentInfo = existingInfos[guardianUid];
      final currentInfoMap = currentInfo is Map
          ? Map<String, dynamic>.from(currentInfo as Map)
          : <String, dynamic>{};
      
      existingInfos[guardianUid] = {
        'displayName': result,
        'phone': currentInfoMap['phone'] ?? existingPhone,
        if (currentInfoMap['pairedAt'] != null) 'pairedAt': currentInfoMap['pairedAt'],
      };
      
      await docRef.set({
        'guardianInfos': existingInfos,
      }, SetOptions(merge: true));
      
      if (!mounted) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('보호자 정보가 수정되었습니다.')),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정에 실패했습니다. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _addGuardian() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요.')),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('핸드폰 번호를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;

      if (userId == null) {
        throw Exception('사용자 인증이 필요합니다.');
      }

      final guardianDoc = await _guardianService.getUserByPhone(_phoneController.text.trim());
      if (guardianDoc == null) {
        // 미가입 시 대기 등록 → 가입 시 자동 연결
        final subjectPhone = authService.user?.phoneNumber ?? authService.userModel?.phone ?? '';
        await _guardianService.createPendingSubjectInvite(
          guardianPhone: _phoneController.text.trim(),
          subjectUid: userId,
          subjectPhone: subjectPhone,
          subjectDisplayName: authService.userModel?.displayName,
        );
        if (mounted) {
          _nameController.clear();
          _phoneController.clear();
          _hasScrolledAfterAdd = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '이 분이 아직 앱에 가입하지 않았습니다.\n가입하시면 자동으로 연결됩니다.',
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final guardianId = guardianDoc.id;
      final guardianData = guardianDoc.data() as Map<String, dynamic>? ?? {};
      final guardianPhone = guardianData['phone'] is String
          ? (guardianData['phone'] as String)
          : '';

      // 본인 체크: 프로덕션 모드에서는 본인을 보호자로 추가할 수 없음
      // 개발 모드(kDebugMode)에서는 테스트를 위해 허용
      if (guardianId == userId) {
        if (kDebugMode) {
          // 개발 모드: 허용 (테스트 편의)
          debugPrint('[개발 모드] 본인을 보호자로 추가합니다. (프로덕션에서는 차단됨)');
        } else {
          // 프로덕션 모드: 차단
          throw Exception('본인 핸드폰 번호는 추가할 수 없습니다.');
        }
      }

      final docRef = _firestore.collection(AppConstants.subjectsCollection).doc(userId);
      // 기존 데이터를 먼저 읽어서 중복 확인
      final docSnap = await docRef.get();
      final existingData = docSnap.data() as Map<String, dynamic>?;
      final existingPairedUids = List<String>.from(existingData?['pairedGuardianUids'] ?? []);
      
      // 이미 등록된 보호자인지 확인
      if (existingPairedUids.contains(guardianId)) {
        throw Exception('이미 등록된 보호자입니다.');
      }

      // 입력한 이름 그대로 저장 (한 글자 "박" 등도 반드시 표시)
      final nameInput = _nameController.text.trim();
      final guardianDisplayName = nameInput.isNotEmpty
          ? nameInput
          : (guardianData['displayName'] is String
              ? (guardianData['displayName'] as String).trim()
              : '');

      // 기존 guardianInfos를 읽어서 새 지정자 정보를 넣은 뒤 통째로 저장 (이름이 확실히 반영되도록)
      final existingInfosRaw = existingData?['guardianInfos'];
      final existingInfos = existingInfosRaw is Map
          ? Map<String, dynamic>.from(
              (existingInfosRaw as Map).map((k, v) => MapEntry(
                    k.toString(),
                    v is Map ? Map<String, dynamic>.from(v) : v,
                  )))
          : <String, dynamic>{};
      
      // 새 보호자 정보 추가 (중복 확인 완료 후)
      existingInfos[guardianId] = {
        'phone': guardianPhone,
        'displayName': guardianDisplayName, // 항상 문자열로 저장 (빈 문자열 가능)
        'pairedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };
      
      // pairedGuardianUids에 새 보호자 추가 (중복 확인 완료했으므로 바로 추가)
      existingPairedUids.add(guardianId);

      // 문서가 있으면 update, 없으면 set 사용
      if (docSnap.exists) {
        await docRef.update({
          'displayName': authService.userModel?.displayName ?? '',
          'pairedGuardianUids': existingPairedUids,
          'guardianInfos': existingInfos,
        });
      } else {
        await docRef.set({
          'displayName': authService.userModel?.displayName ?? '',
          'pairedGuardianUids': existingPairedUids,
          'guardianInfos': existingInfos,
        });
      }

      if (mounted) {
        FocusScope.of(context).unfocus(); // 키보드 닫아 상단 보이게
        _nameController.clear();
        _phoneController.clear();
        _hasScrolledAfterAdd = false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보호자가 추가되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // 상단(등록된 보호자 목록)으로 스크롤하여 새로 추가된 보호자 확인 가능하게
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients && !_hasScrolledAfterAdd) {
            _hasScrolledAfterAdd = true;
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String message = '등록이 되지 않았어요. 핸드폰 번호를 확인하고 다시 시도해 주세요.';
        final str = e.toString();
        if (str.startsWith('Exception: ')) {
          message = str.substring('Exception: '.length).split('\n').first.trim();
        } else if (str.contains('permission-denied')) {
          message = '접근 권한이 없습니다. 잠시 후 다시 시도해 주세요.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {
            _isLoading = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('보호자 관리'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubjectSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection(AppConstants.subjectsCollection).doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final guardianUids =
                    List<String>.from(data?['pairedGuardianUids'] ?? []);
                final guardianInfosRaw = data?['guardianInfos'];
                final guardianInfos = guardianInfosRaw is Map
                    ? Map<String, dynamic>.from(guardianInfosRaw)
                    : <String, dynamic>{};

                final padding = MediaQuery.of(context).padding;
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + padding.bottom,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. 보호자 목록 (보호 대상 관리 화면과 동일 형태)
                      if (guardianUids.isEmpty) ...[
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '등록된 보호자가 없습니다.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          '보호자 (${guardianUids.length}명)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...guardianUids.map((uid) {
                          final info = guardianInfos[uid];
                          final infoMap = info is Map
                              ? Map<String, dynamic>.from(info as Map)
                              : null;
                          final phone = infoMap?['phone'] is String
                              ? _formatPhoneDisplay(infoMap!['phone'] as String)
                              : null;
                          // Firestore 반환 타입 차이 대비: String이 아니어도 문자열로 표시 시도
                          final displayNameRaw = infoMap?['displayName'];
                          final displayName = displayNameRaw is String
                              ? (displayNameRaw).trim()
                              : (displayNameRaw != null && displayNameRaw.toString().trim().isNotEmpty)
                                  ? displayNameRaw.toString().trim()
                                  : null;
                          final hasName = displayName != null &&
                              displayName.isNotEmpty;
                          final hasPhone = phone != null && phone.isNotEmpty;
                          String displayText = hasName
                              ? displayName!
                              : (hasPhone
                                  ? phone!
                                  : '이름 없음');
                          if (displayText == uid) {
                            displayText = '이름 없음';
                          }
                          return _GuardianListCard(
                            subjectId: userId!,
                            guardianUid: uid,
                            displayText: displayText,
                            phone: hasName && hasPhone ? phone : null,
                            guardianInfos: guardianInfos,
                            firestore: _firestore,
                            guardianService: _guardianService,
                            onSetName: () => _showSetNameDialog(
                              context,
                              userId,
                              uid,
                              guardianInfos,
                            ),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('보호자 삭제'),
                                  content: Text(
                                    guardianUids.length <= 1
                                        ? '$displayText를 삭제하면 안부를 전달할 보호자가 없어집니다. 삭제하시겠습니까?'
                                        : '$displayText를 삭제하시겠습니까?',
                                  ),
                                  actions: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, false),
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
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: AppButtonStyles.primaryElevated,
                                            child: const Text('삭제'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              try {
                                await _firestore
                                    .collection(AppConstants.subjectsCollection)
                                    .doc(userId)
                                    .update({
                                  'pairedGuardianUids': FieldValue.arrayRemove([uid]),
                                  'guardianInfos.$uid': FieldValue.delete(),
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('보호자가 삭제되었습니다.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('삭제에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        }),
                      ],
                      // 2. 보호자 추가 (보호 대상 관리 화면과 동일 형태)
                      SizedBox(height: guardianUids.isEmpty ? 32 : 28),
                      const Text(
                        '보호자 추가',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 10),
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '보호자 이름(별칭)',
                            hintText: '예: 와이프, 엄마',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400 ?? Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400 ?? Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              20,
                              16,
                              16,
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          canRequestFocus: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 10),
                        child: TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: '보호자 핸드폰 번호',
                            hintText: '01012345678 (숫자만)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400 ?? Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400 ?? Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              20,
                              16,
                              16,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          canRequestFocus: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: _inputMinHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addGuardian,
                          style: AppButtonStyles.primaryElevated,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('보호자 추가'),
                        ),
                      ),
                      // 3. 초대 영역
                      const SizedBox(height: 32),
                      const Text(
                        '링크로 보호자 초대',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '링크를 보내면 보호자는 앱이 없어도 설치 후 자동 연결됩니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (userId != null) {
                              _showInviteBottomSheet(context, userId);
                            }
                          },
                          icon: const Icon(Icons.link, size: 22),
                          label: const Text('보호자에게 초대 링크 보내기'),
                          style: OutlinedButton.styleFrom(
                            padding: _inputPadding,
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size(double.infinity, _inputMinHeight),
                            foregroundColor: const Color(0xFF5C6BC0),
                            side: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                            ),
                          ),
                        ),
                      ),
                      // 4. 안내
                      const SizedBox(height: 32),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '안내',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '이 서비스는 안부 전달을 위한 참고 정보만 제공합니다.\n판단이나 조치를 위한 용도가 아닙니다.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// 상태 배지 - 아이콘 + 텍스트
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

/// 보호자 목록 카드 - 연결/비연결, 유료/무료 상태 아이콘+텍스트 표시
class _GuardianListCard extends StatefulWidget {
  final String subjectId;
  final String guardianUid;
  final String displayText;
  final String? phone;
  final Map<String, dynamic> guardianInfos;
  final FirebaseFirestore firestore;
  final GuardianService guardianService;
  final VoidCallback onSetName;
  final Future<void> Function() onDelete;

  const _GuardianListCard({
    required this.subjectId,
    required this.guardianUid,
    required this.displayText,
    this.phone,
    required this.guardianInfos,
    required this.firestore,
    required this.guardianService,
    required this.onSetName,
    required this.onDelete,
  });

  @override
  State<_GuardianListCard> createState() => _GuardianListCardState();
}

class _GuardianListCardState extends State<_GuardianListCard> {
  late final Future<bool> _isStillConnectedFuture;
  late final Future<String> _subscriptionStatusFuture;

  @override
  void initState() {
    super.initState();
    _isStillConnectedFuture = widget.guardianService.isGuardianStillHasSubject(
      widget.guardianUid,
      widget.subjectId,
    );
    _subscriptionStatusFuture = widget.guardianService.getGuardianSubscriptionStatusRaw(
      widget.guardianUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_isStillConnectedFuture, _subscriptionStatusFuture]),
      builder: (context, snapshot) {
        final isConnected = snapshot.data != null ? (snapshot.data! as List)[0] as bool : true;
        final subRaw = snapshot.data != null ? (snapshot.data! as List)[1] as String : 'trial';
        final isPaid = subRaw == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // 상태 배지 (연결/비연결, 유료/무료) - 아이콘+텍스트
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusChip(
                      icon: isConnected ? Icons.check_circle : Icons.cancel,
                      label: isConnected ? '연결' : '비연결',
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    _StatusChip(
                      icon: isPaid ? Icons.workspace_premium : Icons.card_giftcard,
                      label: isPaid ? '유료' : '무료',
                      color: isPaid ? Colors.blue : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // 이름, 전화번호 (overflow 방지)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.displayText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (widget.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.phone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 22, color: Colors.grey[600]),
                      tooltip: '이름 수정',
                      onPressed: widget.onSetName,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 22, color: Colors.grey[600]),
                      tooltip: '삭제',
                      onPressed: () async {
                        await widget.onDelete();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
