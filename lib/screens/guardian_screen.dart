import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/button_styles.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  static const double _inputRadius = 12;
  static const double _inputMinHeight = 56;
  static const EdgeInsets _inputPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 지정자 이름을 다이얼로그에서 입력 (에뮬레이터에서 입력이 잘 됨)
  Future<void> _showNameInputDialog(BuildContext context) async {
    final initialName = _nameController.text;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('보호자 이름'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '이름(별칭)',
            hintText: '예: 와이프, 엄마',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.text = initialName;
              Navigator.pop(ctx, false);
            },
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            style: AppButtonStyles.primaryFilled,
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  /// 로그인 시 저장 형식과 맞추기 위해 E.164로 변환 (+821012345678)
  String _toE164(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return input.trim();
    if (digits.startsWith('82') && digits.length >= 11) {
      return '+$digits';
    }
    if (digits.length >= 9 && digits.startsWith('010')) {
      return '+82${digits.substring(1)}';
    }
    if (digits.length >= 10 && digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    if (!input.trim().startsWith('+')) {
      return '+82$digits';
    }
    return input.trim();
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

  /// 기존 지정자(코드만 보이는 경우)에 이름만 나중에 입력
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
    final controller = TextEditingController(text: initialName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('보호자 이름'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '이름(별칭)',
            hintText: '예: 와이프, 엄마',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final n = controller.text.trim();
              Navigator.pop(ctx, n.isNotEmpty ? n : null);
            },
            style: AppButtonStyles.primaryFilled,
            child: const Text('저장'),
          ),
        ],
      ),
    );
    // 다이얼로그가 완전히 닫힌 뒤 controller dispose (에러 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    if (name == null || !mounted) return;
    // 지정자 추가와 동일하게 guardianInfos 전체를 읽어 수정 후 통째로 저장 (수정이 반영되도록)
    final docRef = _firestore.collection('subjects').doc(userId);
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
    final current = existingInfos[guardianUid] is Map
        ? Map<String, dynamic>.from(existingInfos[guardianUid] as Map)
        : <String, dynamic>{};
    existingInfos[guardianUid] = {...current, 'displayName': name};
    await docRef.set({
      'guardianInfos': existingInfos,
    }, SetOptions(merge: true));
  }

  /// 지정자 조회용: Firestore에 저장된 형식이 다양할 수 있어 여러 형식으로 시도
  Future<QuerySnapshot> _findUserByPhone(String rawInput) async {
    final digits = rawInput.replaceAll(RegExp(r'[^\d]'), '');
    final candidates = <String>{
      _toE164(rawInput),
      digits, // 01063914520
      if (digits.startsWith('010')) '82${digits.substring(1)}', // 821063914520
    };

    for (final phone in candidates) {
      if (phone.isEmpty) continue;
      final q = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return q;
    }
    return _firestore.collection('users').limit(0).get();
  }

  Future<void> _addGuardian() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('보호자 이름을 먼저 입력해 주세요. (버튼을 눌러 이름 입력)')),
      );
      return;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호를 입력해주세요.')),
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

      // 여러 형식으로 시도 (E.164, 010..., 82...)
      final usersQuery = await _findUserByPhone(_phoneController.text.trim());

      if (usersQuery.docs.isEmpty) {
        throw Exception('해당 전화번호로 가입된 사용자를 찾을 수 없습니다.');
      }

      final guardianDoc = usersQuery.docs.first;
      final guardianId = guardianDoc.id;
      final guardianData = guardianDoc.data() as Map<String, dynamic>? ?? {};
      final guardianPhone = guardianData['phone'] is String
          ? (guardianData['phone'] as String)
          : '';
      // 입력한 이름 그대로 저장 (한 글자 "박" 등도 반드시 표시)
      final nameInput = _nameController.text.trim();
      final guardianDisplayName = nameInput.isNotEmpty
          ? nameInput
          : (guardianData['displayName'] is String
              ? (guardianData['displayName'] as String).trim()
              : '');

      final docRef = _firestore.collection('subjects').doc(userId);
      // 기존 guardianInfos를 읽어서 새 지정자 정보를 넣은 뒤 통째로 저장 (이름이 확실히 반영되도록)
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
      existingInfos[guardianId] = {
        'phone': guardianPhone,
        'displayName': guardianDisplayName, // 항상 문자열로 저장 (빈 문자열 가능)
      };

      await docRef.set({
        'displayName': authService.userModel?.displayName ?? '',
        'pairedGuardianUids': FieldValue.arrayUnion([guardianId]),
        'guardianInfos': existingInfos,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보호자가 추가되었습니다.')),
        );
        _nameController.clear();
        _phoneController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        leadingWidth: 72,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_ios_new, size: 20),
                    const SizedBox(width: 4),
                    const Text('뒤로', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: userId == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('subjects').doc(userId).snapshots(),
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
                final rightPadding = 24 + padding.right + 20;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    rightPadding,
                    24 + padding.bottom,
                  ),
                  clipBehavior: Clip.none,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '보호자 추가',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: _inputMinHeight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showNameInputDialog(context),
                          icon: const Icon(Icons.person, size: 22),
                          label: Text(
                            _nameController.text.isEmpty
                                ? '보호자 이름 입력 (예: 와이프, 엄마)'
                                : '보호자 이름: ${_nameController.text}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: _inputPadding,
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size(double.infinity, _inputMinHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_inputRadius),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 10),
                        child: TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: '보호자 전화번호',
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
                      const SizedBox(height: 32),
                      const Text(
                        '등록된 보호자',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (guardianUids.isEmpty)
                        const Text('등록된 보호자가 없습니다.')
                      else
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
                          String title = hasName
                              ? displayName!
                              : (hasPhone
                                  ? phone!
                                  : '이름 없음 (연필 아이콘으로 입력)');
                          // UID가 노출되지 않도록 방어 (이전 데이터/구버전 대응)
                          if (title == uid) {
                            title = '이름 없음 (연필 아이콘으로 입력)';
                          }
                          final subtitle = hasPhone && hasName
                              ? phone
                              : (hasPhone && !hasName ? null : '연필 아이콘 탭 → 이름 입력');
                          return Card(
                            child: ListTile(
                              title: Text(title),
                              subtitle: subtitle != null
                                  ? Text(subtitle,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]))
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: hasName ? '이름 수정' : '이름 입력',
                                    onPressed: () => _showSetNameDialog(
                                      context,
                                      userId!,
                                      uid,
                                      guardianInfos,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await _firestore
                                          .collection('subjects')
                                          .doc(userId)
                                          .update({
                                        'pairedGuardianUids':
                                            FieldValue.arrayRemove([uid]),
                                        'guardianInfos.$uid': FieldValue.delete(),
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
